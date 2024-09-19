/*
** Configuration
*/

@description('Optional. The geo-location where the resource lives.')
param location string = resourceGroup().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
@minLength(1)
@maxLength(4)
param shortIdentifier string = 'arn'

@description('Computed. Do not set.')
param deploymentStartTime string = utcNow()

@description('Computed. Do not set.')
@secure()
param newKeyVaultSecret string = newGuid()

/*
** Prerequisites
*/

var logAnalyticsWorkspaceName = '${shortIdentifier}tstlaw${uniqueString(deployment().name, 'logAnalyticsWorkspace', location)}'

module logAnalyticsWorkspace '../../../operational-insights/workspaces/main.bicep' = {
  name: '${logAnalyticsWorkspaceName}-${deploymentStartTime}'
  params: {
    location: location
    name: logAnalyticsWorkspaceName
  }
}

var appInsightsName = '${shortIdentifier}tstapp${uniqueString(deployment().name, 'appInsights', location)}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

var keyVaultName = '${shortIdentifier}tstkv${uniqueString(deployment().name, 'keyVault', location)}'

module keyVault '../../../key-vault/vaults/main.bicep' = {
  name: '${keyVaultName}-${deploymentStartTime}'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: apiLinux.outputs.managedIdentityPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

module keyVaultSecret '../../../key-vault/vaults-secrets/main.bicep' = {
  name: '${keyVaultName}-Secret-${deploymentStartTime}'
  params: {
    keyVaultName: keyVault.outputs.name
    name: 'newKeyVaultSecret'
    value: newKeyVaultSecret
  }
}

var frontDoorName = '${shortIdentifier}tstafd${uniqueString(deployment().name, 'frontDoor', location)}'

resource frontDoor 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

var functionsStorageAccountName = '${shortIdentifier}tststg${uniqueString(deployment().name, 'storageAccount', location)}'

module functionsStorageAccount '../../../storage/storage-accounts/main.bicep' = {
  name: '${functionsStorageAccountName}-${deploymentStartTime}'
  params: {
    location: location
    name: functionsStorageAccountName
    // required for 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    allowSharedKeyAccess: true
  }
}

var serverFarmLinuxName = '${shortIdentifier}tstfml${uniqueString(deployment().name, 'serverFarmLinux', location)}'

resource serverFarmLinux 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: serverFarmLinuxName
  location: location

  properties: {
    reserved: true
  }

  sku: {
    name: 'S1'
  }
}

var serverFarmWindowsName = '${shortIdentifier}tstfmw${uniqueString(deployment().name, 'serverFarmWindows', location)}'

resource serverFarmWindows 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: serverFarmWindowsName
  location: location

  properties: {
    reserved: false
  }

  sku: {
    name: 'S1'
  }
}

/*
** Execution
*/

var apiLinuxName = '${shortIdentifier}tstail${uniqueString(deployment().name, 'apiLinux', location)}'
var apiWindowsName = '${shortIdentifier}tstaiw${uniqueString(deployment().name, 'apiWindows', location)}'
var functionLinuxName = '${shortIdentifier}tstfnl${uniqueString(deployment().name, 'functionLinux', location)}'
var functionWindowsName = '${shortIdentifier}tstfnw${uniqueString(deployment().name, 'functionWindows', location)}'
var webAppLinuxName = '${shortIdentifier}tstapl${uniqueString(deployment().name, 'webAppLinux', location)}'
var webAppWindowsName = '${shortIdentifier}tstapw${uniqueString(deployment().name, 'webAppWindows', location)}'

// apiLinux test flow (conceptually, at least):
// 1. Create logAnaLytics (appInsights dependency)
// 2. Create appInsights (apiLinux dependency)
// 3. Create apiLinux (apiLinuxSettingsCurrent && keyVault dependency)
// 4. Create keyVault (keyVaultSecret dependency)
// 5. Create keyVaultSecret (apiLinuxSettingsKeyvault dependency)
// 6. Read apiLinux app settings (apiLinuxSettings dependency)
// 7. Read newKeyVaultSecret uri (apiLinuxSettings dependency)
// 8. Write new combined apiLinuxSettings

module apiLinux '../main.bicep' = {
  name: '${apiLinuxName}-${deploymentStartTime}'
  params: {
    kind: 'api,linux'
    location: location
    name: apiLinuxName
    runtime: 'DOTNETCORE|6.0'
    serverFarmId: serverFarmLinux.id

    appInsightsId: appInsights.id
    preserveAppSettings: false
  }
}

module apiLinuxSettingsCurrent '../../../web/sites/helper/app-settings-read.bicep' = {
  name: '${apiLinuxName}-read-settings-${deploymentStartTime}'
  params: {
    name: apiLinuxName
  }
  dependsOn: [
    apiLinux
  ]
}

var apiLinuxSettingsKeyvault = {
  newKeyVaultSecret: '@Microsoft.KeyVault(SecretUri=${keyVaultSecret.outputs.uri})'
}

var apiLinuxSettings = union(apiLinuxSettingsCurrent.outputs.appSettings, apiLinuxSettingsKeyvault)

module apiKeyvaultSettings '../../../web/sites/helper/app-settings-write.bicep' = {
  name: '${apiLinuxName}-write-settings-${deploymentStartTime}'
  params: {
    name: apiLinuxName
    appSettings: apiLinuxSettings
  }
}

module apiWindows '../main.bicep' = {
  name: '${apiWindowsName}-${deploymentStartTime}'
  params: {
    kind: 'api'
    location: location
    name: apiWindowsName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmWindows.id

    appInsightsId: appInsights.id
    preserveAppSettings: false
    ipSecurityRestrictions: [
      {
        action: 'Allow'
        description: 'Allow traffic from our specific Front Door instance.'
        headers: {
          'X-Azure-FDID': [
            frontDoor.properties.frontDoorId
          ]
        }
        ipAddress: 'AzureFrontDoor.Backend'
        name: 'Allow Front Door'
        priority: 100
        tag: 'ServiceTag'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Deny'
    scmIpSecurityRestrictionsUseMain: true
  }
}

var defaultSettingSample = {
  DUMMY_SETTING_1: 'default value'
  DUMMY_SETTING_2: 'to be removed'
}

var appSettingSample = {
  DUMMY_SETTING_1: 'specific value'
  DUMMY_SETTING_3: 'random extra junk'
}

var appSettingsToRemove = [
  'DUMMY_SETTING_2'
]

// First run sets 'DUMMY_SETTING_1' to 'default value' as a default
// First run sets 'DUMMY_SETTING_2' to 'to be removed' as a default
module functionLinux1 '../main.bicep' = {
  name: '${functionLinuxName}-${deploymentStartTime}-1'
  params: {
    kind: 'functionapp,linux'
    location: location
    name: functionLinuxName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmLinux.id

    appInsightsId: appInsights.id
    appSettingsDefaults: defaultSettingSample
    storageAccountId: functionsStorageAccount.outputs.resourceId
    preserveAppSettings: false
  }
}

// 2nd run sets 'DUMMY_SETTING_1' to 'specific value'
// 2nd run sets 'DUMMY_SETTING_2' is carried across unmodified
module functionLinux2 '../main.bicep' = {
  name: '${functionLinuxName}-${deploymentStartTime}-2'
  params: {
    kind: 'functionapp,linux'
    location: location
    name: functionLinuxName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmLinux.id

    appInsightsId: appInsights.id
    appSettingsDefaults: defaultSettingSample
    appSettingsToAdd: appSettingSample
    storageAccountId: functionsStorageAccount.outputs.resourceId
    preserveAppSettings: true
  }
  dependsOn: [
    functionLinux1
  ]
}

// After the 3rd run 'DUMMY_SETTING_1' should still be 'specific value'
// After the 3rd run 'DUMMY_SETTING_2' should be removed
module functionLinux3 '../main.bicep' = {
  name: '${functionLinuxName}-${deploymentStartTime}-3'
  params: {
    kind: 'functionapp,linux'
    location: location
    name: functionLinuxName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmLinux.id

    appInsightsId: appInsights.id
    appSettingsDefaults: defaultSettingSample
    appSettingsToRemove: appSettingsToRemove
    storageAccountId: functionsStorageAccount.outputs.resourceId
    preserveAppSettings: true
  }
  dependsOn: [
    functionLinux2
  ]
}

module functionWindows '../main.bicep' = {
  name: '${functionWindowsName}-${deploymentStartTime}'
  params: {
    kind: 'functionapp'
    location: location
    name: functionWindowsName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmWindows.id

    appInsightsId: appInsights.id
    storageAccountId: functionsStorageAccount.outputs.resourceId
    preserveAppSettings: false
  }
}

module webAppLinux '../main.bicep' = {
  name: '${webAppLinuxName}-${deploymentStartTime}'
  params: {
    kind: 'app,linux'
    location: location
    name: webAppLinuxName
    runtime: 'DOTNETCORE|6.0'
    serverFarmId: serverFarmLinux.id

    appInsightsId: appInsights.id
    preserveAppSettings: false
  }
}

module webAppWindows '../main.bicep' = {
  name: '${webAppWindowsName}-${deploymentStartTime}'
  params: {
    kind: 'app'
    location: location
    name: webAppWindowsName
    runtime: 'DOTNET|6.0'
    serverFarmId: serverFarmWindows.id

    appInsightsId: appInsights.id
    diagnosticLogAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.resourceId
    systemAssignedIdentity: true
    appSettingsDefaults: defaultSettingSample
    appSettingsToAdd: appSettingSample
    appSettingsToRemove: appSettingsToRemove
  }
}
