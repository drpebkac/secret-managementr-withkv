targetScope = 'subscription'

@description('Azure region for this deployment')
param location string

param tags object

@description('The primary resource group for the secrets management utility resources')
param resourceGroupName string

@description('The function app which will perform the secrets management tasks')
param functionAppName string

@description('The name of the Log Analytics Workspace for log tracking of the function app')
param workspaceName string

@description('The name of the App Service Plan to support the function app')
param appServicePlanName string

@description('The name of the storage account used for outputing secrets expirtation reports to')
param reportsStorageAccountName string

@description('Optional. The resourceId of the virtual network subnet to deploy the function app into.')
param vnetSubnetId string = ''

@description('Optional. Custom App Settings to be added if they don\'t exist.')
@metadata({
  key1: 'value1'
  key2: 'value2'
})
param appSettings object = {}

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

// This will create a resource group if it doesnt exist. This will be the primary resource group for resources to deploy into
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: toLower(resourceGroupName)
  location: location
  tags: tags
}

// Deploys storage account for secret expiry reports to store in
module storageAccountModule '../modules/storage/storage-accounts/main.bicep' = {
  dependsOn: [
    rg
  ]
  name: 'deploy_storage_account'
  scope: rg
  params: {
    name: reportsStorageAccountName
    deleteRetentionPolicy: 90
    tags: tags
    location: location
  }
}

module containerModule '../modules/storage/blob/main.bicep' = if (!empty(containers)) {
  name: 'container_deploy'
  scope: rg
  dependsOn: [
    storageAccountModule
  ]
  params: {
    containers: containers
    storageAccountName: storageAccountModule.outputs.name
  }
}

// default required settings for function app
var defaultAppSettings = {
  SM_REPORT_STORAGE__serviceUri: 'https://${reportsStorageAccountName}.blob.${environment().suffixes.storage}'
  WEBSITE_TIME_ZONE: 'AUS Eastern Standard Time'
  SM_TENANT_NAME: tenant().displayName
  SM_TENANT_ID: tenant().tenantId
}

var finalAppSettings = union(defaultAppSettings, appSettings)

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
    storageAccountId: storageAccountModule.outputs.id
    tags: tags
    appSettingsDefaults: finalAppSettings
    vnetRouteAllEnabled: empty(vnetSubnetId) ? false : true
    vnetSubnetId: vnetSubnetId
    alwaysOn: true
  }
}

// Storage Blob Data Owner
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')

//Grants function RBAC permissions to KV
module rbacAssignments '../modules/authorization/role-assignments/main.bicep' = {
  name: 'deploy_RbacPermissions'
  scope: resourceGroup(resourceGroupName)
  params: {
    principalId: functionAppModule.outputs.managedIdentityPrincipalId
    roleDefinitionIdOrName: roleDefinitionId
    resourceId: functionAppModule.outputs.resourceId
    principalType: 'ServicePrincipal'
  }
}
