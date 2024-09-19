@description('Storage account name')
param name string

@description('Storage account sku')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSku string = 'Standard_LRS'

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storageKind string = 'StorageV2'

@description('Storage account access tier, Hot for frequently accessed data or Cool for infreqently accessed data')
@allowed([
  'Hot'
  'Cool'
])
param storageTier string = 'Hot'

@description('Amount of days the soft deleted data is stored and available for recovery')
@minValue(1)
@maxValue(365)
param deleteRetentionPolicy int

@description('Enable blob encryption at rest')
param blobEncryptionEnabled bool = true

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('The location of the resource group in which to create the storage account.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: name
  location: location
  tags: !empty(tags) ? tags : null
  sku: {
    name: storageSku
  }
  kind: storageKind
  properties: {
    accessTier: storageTier
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: blobEncryptionEnabled
        }
      }
    }
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: deleteRetentionPolicy
    }
  }
}

// Storage Resource Diagnostics
resource storage_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: storage
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? null : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? null : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? null : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? null : diagSettings.eventHubName

    logs: [
      {
        category: 'StorageRead'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? null : diagSettings.retentionPolicy
      }
      {
        category: 'StorageWrite'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? null : diagSettings.retentionPolicy
      }
      {
        category: 'StorageDelete'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? null : diagSettings.retentionPolicy
      }
    ]
  }
}

// Resource Lock
resource storage_deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${name}-delete-lock'
  scope: storage
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = storage.name
output id string = storage.id
