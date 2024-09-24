metadata name = 'Key Vaults Module'
metadata description = 'This module deploys Microsoft.KeyVault vaults'
metadata owner = 'Arinco'

@description('The resource name.')
param name string

@description('The geo-location where the resource lives.')
param location string

@description('Optional. Resource tags.')
@metadata({
  doc: 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#arm-templates'
  example: {
    tagKey: 'string'
  }
})
param tags object = {}

@description('Optional. The sku of the key vault.')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('Optional. Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = true

@description('Optional. Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = true

@description('Optional. Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Optional. Property specifying whether protection against purge is enabled for this vault.')
param enablePurgeProtection bool = true

@description('Optional. SoftDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 90

@description('Optional. Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored.')
param enableRbacAuthorization bool = true

@description('Optional. An array of 0 to 1024 identities that have access to the key vault. Only required when enableRbacAuthorization is set to "false".')
@metadata({
  applicationId: 'Application ID of the client making request on behalf of a principal.'
  objectId: 'The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies.'
  permissions: {
    certificates: [
      'String array containing any of:'
      'all'
      'backup'
      'create'
      'delete'
      'deleteissuers'
      'get'
      'getissuers'
      'import'
      'list'
      'listissuers'
      'managecontacts'
      'manageissuers'
      'purge'
      'recover'
      'restore'
      'setissuers'
      'update'
    ]
    keys: [
      'String array containing any of:'
      'all'
      'backup'
      'create'
      'decrypt'
      'delete'
      'encrypt'
      'get'
      'getrotationpolicy'
      'import'
      'list'
      'purge'
      'recover'
      'release'
      'restore'
      'rotate'
      'setrotationpolicy'
      'sign'
      'unwrapKey'
      'update'
      'verify'
      'wrapKey'
    ]
    secrets: [
      'String array containing any of:'
      'all'
      'backup'
      'delete'
      'get'
      'list'
      'purge'
      'recover'
      'restore'
      'set'
    ]
    storage: [
      'String array containing any of:'
      'all'
      'backup'
      'delete'
      'deletesas'
      'get'
      'getsas'
      'list'
      'listsas'
      'purge'
      'recover'
      'regeneratekey'
      'restore'
      'set'
      'setsas'
      'update'
    ]
  }
  tenantId: 'The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.'
})
param accessPolicies array = []

@description('Optional. Rules governing the accessibility of the key vault from specific network locations.')
@metadata({
  bypass: 'Tells what traffic can bypass network rules. This can be "AzureServices" or "None". If not specified the default is "AzureServices".'
  defaultAction: 'The default action when no rule from ipRules and from virtualNetworkRules match. This is only used after the bypass property has been evaluated. Accepted values are "Allow" or "Deny".'
  ipRules: [
    {
      value: 'An IPv4 address range in CIDR notation, such as "124.56.78.91" (simple IP address) or "124.56.78.0/24" (all addresses that start with 124.56.78).'
    }
  ]
  virtualNetworkRules: [
    {
      id: 'Full resource id of a vnet subnet.'
      ignoreMissingVnetServiceEndpoint: 'Property to specify whether NRP will ignore the check if parent subnet has serviceEndpoints configured. Accepted values are "true" or "false".'
    }
  ]
})
param networkAcls object = {}

@description('Optional. Specify the type of resource lock.')
@allowed([
  'NotSpecified'
  'ReadOnly'
  'CanNotDelete'
])
param resourceLock string = 'NotSpecified'

@description('Optional. Enable diagnostic logging.')
param enableDiagnostics bool = false

@description('Optional. The name of log category groups that will be streamed.')
@allowed([
  'audit'
  'allLogs'
])
param diagnosticLogCategoryGroupsToEnable array = [
  'audit'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Optional. Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Optional. Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

var lockName = toLower('${keyvault.name}-${resourceLock}-lck')

var diagnosticsName = toLower('${keyvault.name}-dgs')

var diagnosticsLogs = [for categoryGroup in diagnosticLogCategoryGroupsToEnable: {
  categoryGroup: categoryGroup
  enabled: true
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: sku
    }
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: enableRbacAuthorization
    networkAcls: {
      bypass: contains(networkAcls, 'bypass') ? networkAcls.bypass : null
      defaultAction: contains(networkAcls, 'defaultAction') ? networkAcls.defaultAction : null
      ipRules: contains(networkAcls, 'ipRules') ? networkAcls.ipRules : null
      virtualNetworkRules: contains(networkAcls, 'virtualNetworkRules') ? networkAcls.virtualNetworkRules : null
    }
    accessPolicies: accessPolicies
  }
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourceLock != 'NotSpecified') {
  scope: keyvault
  name: lockName
  properties: {
    level: resourceLock
    notes: (resourceLock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: keyvault
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: diagnosticsLogs
    metrics: diagnosticsMetrics
  }
}

@description('The name of the deployed key vault.')
output name string = keyvault.name

@description('The resource ID of the deployed key vault.')
output resourceId string = keyvault.id

@description('The uri of the deployed key vault.')
output uri string = keyvault.properties.vaultUri
