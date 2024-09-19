metadata name = 'App Service Plans'
metadata description = 'This module deploys Microsoft.web/severFarms aka App Service Plans'
metadata owner = 'Arinco'

/*
** Required Parameters
*/

@description('The resource name.')
@minLength(1)
@maxLength(40)
param name string

@description('The geo-location where the resource lives.')
param location string

/*
** 'Boiler-plate' Optional Parameters
*/

@description('Optional. Resource tags.')
@metadata({
  doc: 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#arm-templates'
  example: {
    tagKey: 'string'
  }
})
param tags object = {}

@description('Optional. Specify the type of resource lock.')
@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
param resourceLock string = 'NotSpecified'

@description('Optional. Enable diagnostic logging.')
param enableDiagnostics bool = !empty(diagnosticStorageAccountId) || !empty(diagnosticLogAnalyticsWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 0

@description('Optional. Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Optional. Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Optional. Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

/*
** Template Specific Optional Parameters
*/

@description('Optional. ServerFarm supports ElasticScale. Apps in this plan will scale as if the ServerFarm was ElasticPremium sku.')
param elasticScaleEnabled bool = false

@description('Optional. ResourceId of the App Service Environment to use for the App Service plan.')
param hostingEnvironmentProfileId string = ''

@description('Optional. The kind of App Service Plan.')
@allowed([
  'app'
  'elastic'
])
param kind string = 'app'

@description('Optional. ResourceId of the Kubernetes Environment to use for the App Service plan.')
param kubeEnvironmentProfileId string = ''

@description('Optional. The operating system of the App Service Plan.')
@allowed([
  'linux'
  'windows'
])
param operatingSystem string = 'linux'

@description('Optional. If true, apps assigned to this App Service plan can be scaled independently. If false, apps assigned to this App Service plan will scale to all instances of the plan.')
param perSiteScaling bool = false

@minValue(0)
@maxValue(10)
@description('Optional. Number of instances needed for the app service plan. 0 means not specified (allows for control ouside IaC).')
param skuCapacity int = 0

@description('Optional. Name of the resource SKU.')
@allowed([
  'B1'
  'B2'
  'B3'
  'D1'
  'F1'
  'P0v3'
  'P1'
  'P1mv3'
  'P1v2'
  'P1v3'
  'P2'
  'P2mv3'
  'P2v2'
  'P2v3'
  'P3'
  'P3mv3'
  'P3v2'
  'P3v3'
  'S1'
  'S2'
  'S3'
  'Y1'
])
// default to smallest commonly available plan which supports deployment/staging slots
param skuName string = 'S1'

@description('Optional. If this App Service Plan will perform availability zone balancing.')
param zoneRedundant bool = false

/*
** Template Specific Variables
*/

var reserved = operatingSystem == 'linux'

/*
** 'Boiler-plate' Variables
*/

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsName = toLower('${appServicePlan.name}-dgs')

var lockName = toLower('${appServicePlan.name}-${resourceLock}-lck')

/*
** Main Resource Deployment
*/

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  tags: tags

  kind: kind

  properties: {
    elasticScaleEnabled: elasticScaleEnabled ? elasticScaleEnabled : null

    hostingEnvironmentProfile: empty(hostingEnvironmentProfileId) ? null : {
      id: hostingEnvironmentProfileId
    }

    kubeEnvironmentProfile: empty(kubeEnvironmentProfileId) ? null : {
      id: kubeEnvironmentProfileId
    }

    perSiteScaling: perSiteScaling ? perSiteScaling : null
    reserved: reserved

    zoneRedundant: zoneRedundant ? zoneRedundant : null
  }

  sku: union({
      name: skuName
    }, skuCapacity == 0 ? {} : {
      capacity: skuCapacity
    })
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (resourceLock != 'NotSpecified') {
  scope: appServicePlan
  name: lockName
  properties: {
    level: resourceLock
    notes: (resourceLock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

// Preview diagnosticSettings API has not been updated recently by Microsoft but is preferred over the latest GA version (2016-09-01)
#disable-next-line use-recent-api-versions
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: appServicePlan
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    metrics: diagnosticsMetrics
  }
}

/*
** Outputs
*/

@description('The name of the deployed app service plan resource.')
output name string = appServicePlan.name

@description('The resource ID of the deployed app service plan resource.')
output resourceId string = appServicePlan.id
