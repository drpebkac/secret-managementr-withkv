targetScope = 'subscription'

param tags object

@description('The function app which will perform the secrets management tasks. Parsed directly via workflow/pipeline deployment')
param functionAppName string

@description('The primary resource group for the secrets management utility resources. Parsed directly via workflow/pipeline deployment')
param resourceGroupName string

@description('Azure region for this deployment. Default: Australia East')
param location string = 'australiaeast'

@description('The name of the Log Analytics Workspace for log tracking of the function app')
param workspaceName string

@description('The name of the App Service Plan to support the function app')
param appServicePlanName string

@description('The name of the storage account used for outputing secrets expirtation reports to')
param reportsStorageAccountName string

@description('The name of the storage account for function app files')
param functionAppStorageAccountName string

@description('Optional. The resourceId of the virtual network subnet to deploy the function app into.')
param vnetSubnetId string = ''

@description('The name of the key vault used to store 3rd party integration API keys for email notifications.')
param kvName string

@description('Optional. Custom App Settings to be added if they don\'t exist.')
@metadata({
  key1: 'value1'
  key2: 'value2'
})
param appSettings object = {}

var storageAccountArray = [
  functionAppStorageAccountName // for function app content
  reportsStorageAccountName // for secret expiry reports to store in
]

// Variables to define the name of containers to store report blobs in secretsmgmtst
var containers = [
  {
    name: 'sm-app-reg-expiry-reports'
  }
  {
    name: 'sm-key-vault-expiry-reports'
  }
  {
    name: 'sm-key-vault-error-logs'
  }
]

// Sure, these values can be simply placed in the app setting config as a string. But since this is a secret' management utility, it's much rather better to have it stored in a KV as a formality.
var placeholderSecrets = [
  {
    name: 'sendGridToken'
    value: 'Replace this value with SendGrid API Key' // Do not replace values here on this variable. The value is a literal secret intended to be changed on the key vault itself. 
  }
  {
    name: 'msTeamsWebhookUri'
    value: 'Replace this value with a MS Teams webhook uri' // Do not replace values here on this variable. The value is a literal secret intended to be changed on the key vault itself.
  }
  {
    name: 'msTeamsWebhookUriSecondary'
    value: 'Replace this value with a MS Teams webhook uri' // Do not replace values here on this variable. The value is a literal secret intended to be changed on the key vault itself.
  }
]

// default required settings for function app
var defaultAppSettings = {
  SM_REPORT_STORAGE__serviceUri: 'https://${storageAccountModule[1].outputs.name}.blob.${environment().suffixes.storage}'
  WEBSITE_TIME_ZONE: 'AUS Eastern Standard Time'
  SM_TENANT_NAME: tenant().displayName
  SM_TENANT_ID: tenant().tenantId
}

// Define this variable If using third party tools (Eg, Sendgrid) 
var integrationSettings = ( appSettings.SM_NOTIFY_EMAIL_WITH_SENDGRID == 'true' ) ? {
  SM_SENDGRID_TOKEN: '@Microsoft.KeyVault(VaultName=${kv.outputs.name};SecretName=${placeholderSecrets[0].name})'
} : {}

var msTeamsWebhookSettings = ( appSettings.SM_NOTIFY_MSTEAMS_WEBHOOK == 'true' ) ? {
  SM_MSTEAMS_WEBHOOK_URI: '@Microsoft.KeyVault(VaultName=${kv.outputs.name};SecretName=${placeholderSecrets[1].name})'
  SM_MSTEAMS_WEBHOOK_URI_SECONDARY: '@Microsoft.KeyVault(VaultName=${kv.outputs.name};SecretName=${placeholderSecrets[2].name})'
} : {}

var finalAppSettings = union(defaultAppSettings, appSettings, integrationSettings, msTeamsWebhookSettings)

// This will create a resource group if it doesnt exist. This will be the primary resource group for resources to deploy into
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: toLower(resourceGroupName)
  location: location
  tags: tags
}

module kv '../modules/key-vault/vaults/main.bicep' = {
  name: 'deploy_key_vault'
  scope: rg
  params: {
    name: kvName
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
  }
}

// Replace value with sendgrid API value post deployment
module kvSecrets '../modules/key-vault/vaults-secrets/main.bicep' = [ for i in range(0, length(placeholderSecrets)): {
  name: 'create_kv_secret-${i}'
  scope: rg
  dependsOn: [
    kv
  ]
  params: {
    keyVaultName: kv.outputs.name
    name: placeholderSecrets[i].name
    value: placeholderSecrets[i].value
  }
}]

// Deploys storage account
module storageAccountModule '../modules/storage/storage-accounts/main.bicep' = [ for i in range(0, (length(storageAccountArray))) : {
  name: 'deploy_storage_account-${i}'
  scope: rg
  params: {
    name: storageAccountArray[i]
    deleteRetentionPolicy: 90
    tags: tags
    location: location
  }
}]

module containerModule '../modules/storage/blob/main.bicep' = if (!empty(containers)) {
  name: 'container_deploy'
  scope: rg
  dependsOn: [
    storageAccountModule[1]
  ]
  params: {
    containers: containers
    storageAccountName: storageAccountModule[1].outputs.name
  }
}

module logAnalytics '../modules/log-analytics/log-analytics.bicep' = {
  dependsOn: [
    rg
  ]
  name: 'deploy_law'
  scope: resourceGroup(resourceGroupName)
  params: {
    workspaceName: workspaceName
    location: location
  }
}

//Deploy application insights for function app
module applicationInsights '../modules/insights/components/main.bicep' = {
  dependsOn: [
    rg
  ]
  name: 'deploy_fa_applicationInsights'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: functionAppName
    tags: tags
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module appServicePlan '../modules/web/server-farms/main.bicep' = {
  dependsOn: [
    rg
  ]
  name: 'deploy_serverFarm'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: appServicePlanName
    location: location
    skuName: 'B1' // Minimum sku required for networking
    operatingSystem: 'windows'
    skuCapacity: 1
  }
}

module functionAppModule '../modules/web/sites/main.bicep' = {
  dependsOn: [
    rg
  ]
  name: 'deploy_fa'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: functionAppName
    location: location
    kind: 'functionapp'
    isFunctionApp: true
    serverFarmId: appServicePlan.outputs.resourceId
    enableDiagnostics: true
    diagnosticLogAnalyticsWorkspaceId: logAnalytics.outputs.id
    appInsightsId: applicationInsights.outputs.resourceId
    runtime: 'POWERSHELL|7.2'
    runtimeLanguage: 'powershell'
    storageAccountId: storageAccountModule[0].outputs.id
    tags: tags
    appSettingsDefaults: finalAppSettings
    vnetRouteAllEnabled: empty(vnetSubnetId) ? false : true
    vnetSubnetId: vnetSubnetId
    alwaysOn: true
  }
}

var roleDefinitionId = [
  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b') // Storage Blob Data Owner
  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User 
]

//Grants function RBAC permissions to KV
module rbacAssignments '../modules/authorization/role-assignments/main.bicep' = [ for i in range(0, length(roleDefinitionId)): {
  name: 'deploy_RbacPermissions-${i}'
  scope: resourceGroup(resourceGroupName)
  params: {
    principalId: functionAppModule.outputs.managedIdentityPrincipalId
    roleDefinitionIdOrName: roleDefinitionId[i]
    resourceId: functionAppModule.outputs.resourceId
    principalType: 'ServicePrincipal'
  }
}]
