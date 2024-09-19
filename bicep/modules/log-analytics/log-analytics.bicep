// Log Analytics Workspace

@description('The name of the resource.')
param workspaceName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Capacity based reservation for data ingestion in GB. Must be in multiples of 100. Leave as 0 if no reservation.')
param capacityReservation int = 0

@description('Storage account ids to link to log analytics workspace')
param storageAccountIds array = []

@description('Object containing resource tags.')
param tags object = {}

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

// Constant Variable for log retention set to 1 year to comply with Ashurst policy
var retentionInDays = 365

// Resource Definition
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    sku: {
      name: 'PerGB2018'
      capacityReservationLevel: (capacityReservation == 0) ? null : capacityReservation
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource linkStorageCustomLogs 'Microsoft.OperationalInsights/workspaces/linkedStorageAccounts@2020-08-01' = if (!empty(storageAccountIds)) {
  name: 'CustomLogs'
  parent: loganalytics
  properties: {
    storageAccountIds: storageAccountIds
  }
}

resource linkStorageQuery 'Microsoft.OperationalInsights/workspaces/linkedStorageAccounts@2020-08-01' = if (!empty(storageAccountIds)) {
  name: 'Query'
  parent: loganalytics
  properties: {
    storageAccountIds: storageAccountIds
  }
}

resource linkStorageAlerts 'Microsoft.OperationalInsights/workspaces/linkedStorageAccounts@2020-08-01' = if (!empty(storageAccountIds)) {
  name: 'Alerts'
  parent: loganalytics
  properties: {
    storageAccountIds: storageAccountIds
  }
}

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: loganalytics
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? null : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? null : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? null : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? null : diagSettings.eventHubName

    logs: [
      {
        category: 'Audit'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? null : diagSettings.retentionPolicy
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: diagSettings.enableMetrics
        retentionPolicy: empty(diagSettings.retentionPolicy) ? null : diagSettings.retentionPolicy
      }
    ]
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${workspaceName}-delete-lock'
  scope: loganalytics
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = loganalytics.name
output id string = loganalytics.id
