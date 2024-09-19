/*
** Configuration
*/

@description('Optional. The geo-location where the resource lives.')
param location string = resourceGroup().location

@description(
  'Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.'
)
@minLength(1)
@maxLength(4)
param shortIdentifier string = 'arn'

@description('Optional. The resource deployment name.')
param deploymentStartTime string = utcNow()

/*
** Prerequisites
*/

var backingWorkspaceName = '${shortIdentifier}tstlaw${uniqueString(deployment().name, 'backingWorkspace', location)}'

module backingWorkspace '../../../operational-insights/workspaces/main.bicep' = {
  name: '${backingWorkspaceName}${deploymentStartTime}'
  params: {
    location: location
    name: backingWorkspaceName
  }
}

/*
** Execution
*/

var appInsightsName = '${shortIdentifier}tstapp${uniqueString(deployment().name, 'appInsights', location)}'

module appInsights '../main.bicep' = {
  name: '${appInsightsName}${deploymentStartTime}'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: backingWorkspace.outputs.resourceId
  }
}
