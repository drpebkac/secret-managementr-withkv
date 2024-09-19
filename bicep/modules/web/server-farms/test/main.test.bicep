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

@description('Computed. Do not set.')
param deploymentStartTime string = utcNow()

/*
** Prerequisites
*/

var logAnalyticsWorkspaceName = '${shortIdentifier}tstlaw${uniqueString(deployment().name, 'logAnalyticsWorkspace', location)}'

module logAnalyticsWorkspace '../../../operational-insights/workspaces/main.bicep' = {
  name: '${logAnalyticsWorkspaceName}${deploymentStartTime}'
  params: {
    location: location
    name: logAnalyticsWorkspaceName
  }
}

/*
** Execution
*/

var linuxMinimumName = '${shortIdentifier}-tst-min-linux-${uniqueString(deployment().name, 'linuxMinimum', location)}'

module linuxMinimum '../../server-farms/main.bicep' = {
  name: '${linuxMinimumName}${deploymentStartTime}'
  params: {
    location: location
    name: linuxMinimumName
    operatingSystem: 'linux'
  }
}

var windowsMinimumName = '${shortIdentifier}-tst-min-windows-${uniqueString(deployment().name, 'windowsMinimum', location)}'

module windowsMinimum '../../server-farms/main.bicep' = {
  name: '${windowsMinimumName}${deploymentStartTime}'
  params: {
    location: location
    name: windowsMinimumName
    operatingSystem: 'windows'
  }
}

var linuxScaledName = '${shortIdentifier}-tst-linux-${uniqueString(deployment().name, 'linuxScaled', location)}'

module linux '../main.bicep' = {
  name: '${linuxScaledName}${deploymentStartTime}'
  params: {
    location: location
    name: linuxScaledName
    operatingSystem: 'linux'
    diagnosticLogAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.resourceId
    elasticScaleEnabled: true
    enableDiagnostics: true
    perSiteScaling: true
    resourceLock: 'CanNotDelete'
    skuName: 'P3v3'
    zoneRedundant: true
  }
}
