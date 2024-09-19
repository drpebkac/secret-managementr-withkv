metadata name = 'Application Insights Module'
metadata description = 'This module deploys Microsoft.Insights/components, aka Applications Insights.'
metadata owner = 'Arinco'

/*
** Required Parameters
*/

@description('The resource name.')
param name string

@description('The geo-location where the resource lives.')
param location string

@description('ResourceId of Log Analytics to associate App Insights to.')
param workspaceResourceId string

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
  'NotSpecified'
  'ReadOnly'
  'CanNotDelete'
])
param resourceLock string = 'NotSpecified'

/*
** Template Specific Optional Parameters
*/

@description('Optional. Type of application being monitored.')
@allowed([
  'other'
  'web'
])
param applicationType string = (kind == 'web') ? 'web' : 'other'

@description('Optional. Disable IP masking.')
param disableIpMasking bool = false

@description('Optional. Disable Non-AAD based Auth.')
param disableLocalAuth bool = false

@description('Optional. The kind of application that this component refers to, used to customize UI.')
@allowed([
  'ios'
  'java'
  'other'
  'phone'
  'store'
  'web'
])
param kind string = 'web'

@description('Optional. The network access type for accessing Application Insights ingestion.')
param publicNetworkAccessForIngestion bool = true

@description('Optional. The network access type for accessing Application Insights query.')
param publicNetworkAccessForQuery bool = true

@description('Optional. Percentage of the data produced by the application being monitored that is being sampled for Application Insights telemetry.')
@minValue(1)
@maxValue(100)
param samplingPercentage int = 100

/*
** Template Specific Variables
*/

var lockName = toLower('${appInsights.name}-${resourceLock}-lck')

/*
** Main Resource Deployment
*/

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: !empty(tags) ? tags : null
  kind: kind
  properties: {
    Application_Type: applicationType
    DisableIpMasking: disableIpMasking
    DisableLocalAuth: disableLocalAuth
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion ? 'Enabled' : 'Disabled'
    publicNetworkAccessForQuery: publicNetworkAccessForQuery ? 'Enabled' : 'Disabled'
    SamplingPercentage: samplingPercentage
    WorkspaceResourceId: workspaceResourceId
  }
}

/*
** 'Boiler-plate' Resources
*/

resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (resourceLock != 'NotSpecified') {
  scope: appInsights
  name: lockName
  properties: {
    level: resourceLock
    notes: (resourceLock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

/*
** Outputs
*/

@description('The name of the deployed applications insights resource.')
output name string = appInsights.name

@description('The resource ID of the deployed applications insights resource.')
output resourceId string = appInsights.id

@description('The instumentation key of the deployed applications insights resource. Used for function apps')
output instrumentationKey string = appInsights.properties.InstrumentationKey
