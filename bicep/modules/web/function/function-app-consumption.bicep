@description('Prefix value which will be prepended to all resource names.')
@minLength(2)
@maxLength(9)
param envShortName string

@description('Name of workload. Used for resource naming.')
param workloadName string

@description('Name of function app. Used for resource naming.')
param functionAppName string

@description('Only applies if you using Consumption or Premium service plans.')
param preWarmedInstanceCount int = 1

@description('Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = true

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
  'python'
  'powershell'
])
param functionRuntime string = 'powershell'

@description('Node.JS version. Only needed if runtime is node')
param nodeVersion string = '~12'

@description('Name of storage account.')
param storageAccountName string

@description('id of storage account.')
param storageAccountId string

@description('instrumentation key of app insights.')
param appInsightsInstrumentationKey string

@description('Optional. Resource tags.')
@metadata({
  doc: 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#arm-templates'
  example: {
    tagKey: 'string'
  }
})
param tags object = {}

@description('Array of allowed origins hosts.  Use [*] for allow-all.')
param corsAllowedOrigins array = [
  'https://portal.azure.com'
]

@description('True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = true

@description('Location for all resources.')
param location string

@description('Shortname of location. Used for resource naming.')
param locationShortName string

@description('The name of the app service plan')
param hostingPlanName string = '${envShortName}-${workloadName}-${locationShortName}-asp'

@description('Additional App Settings to include on top of that required for this function app')
@metadata({
  note: 'Sample input'
  addAppSettings: [
    {
      name: 'key-name'
      value: 'key-value'
    }
  ]
})
param addAppSettings array = []

// Build base level App Settings needed for Function App
var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionRuntime
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME_VERSION'
    value: '7.2'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: nodeVersion
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsInstrumentationKey
  }
]

var appSettings = union(baseAppSettings,addAppSettings)

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  tags: tags
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: use32BitWorkerProcess
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      preWarmedInstanceCount: preWarmedInstanceCount
      appSettings: appSettings
      cors: {
        allowedOrigins: corsAllowedOrigins
        supportCredentials: corsSupportCredentials
      }
    }
    httpsOnly: true
  }
}

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLock) {
  name: '${functionAppName}-delete-lock'
  scope: functionApp
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = functionApp.name
output id string = functionApp.id
output principalId string = functionApp.identity.principalId
