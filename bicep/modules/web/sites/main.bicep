metadata name = 'Web Apps and Function Apps'
metadata description = 'This module deploys Microsoft.web/sites aka Web Apps and Function Apps'
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

@description('Kind of web site.')
@allowed([
  'api'
  'api,linux'
  'app'
  'app,linux'
  'functionapp'
  'functionapp,linux'
])
param kind string

@description('Resource ID of the associated App Service plan.')
param serverFarmId string

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

@description('Optional. Enable diagnostic logging.')
param enableDiagnostics bool = !empty(diagnosticStorageAccountId) || !empty(diagnosticLogAnalyticsWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)

@description('Optional. The name of log category groups that will be streamed.')
@allowed([
  'audit'
  'allLogs'
])
param diagnosticLogCategoryGroupsToEnable array = [
  'audit'
  'allLogs'
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

/*
** Template Specific Optional Parameters
*/

@description('Optional. Use Managed Identity Creds for Azure Container Registry access.')
param acrUseManagedIdentityCreds bool = systemAssignedIdentity || !empty(userAssignedIdentities)

// TODO
// @description('Optional. If using user managed identity, the user managed identity ClientId.')
// #disable-next-line BCP318
// param acrUserManagedIdentityID string = !empty(userAssignedIdentities) ? first(items(userAssignedIdentities)).value : null

@description('Optional. Keeps app as always on (hot).')
param alwaysOn bool = false

@description('Optional. App command line to launch.')
param appCommandLine string = ''

@description('Optional. Resource ID of Application Insights instance for monitoring.')
param appInsightsId string = ''

@description('Optional. Custom App Settings to be added if they don\'t exist.')
@metadata({
  key1: 'value1'
  key2: 'value2'
})
param appSettingsDefaults object = {}

@description('Optional. Custom App Settings to be added.')
@metadata({
  key1: 'value1'
  key2: 'value2'
})
param appSettingsToAdd object = {}

@description('Optional. Custom App Setting Keys to be removed.')
@metadata({
  sampleInput: [
    'key1'
    'key2'
  ]
})
param appSettingsToRemove array = []

// TODO: Connection strings could be given the appSettings treatment for preserving/defaults/add/remove
@description('Optional. Array of Connection Strings.')
@metadata({
  sampleInput: [
    {
      name: 'connectionstring'
      connectionString: 'Data Source=tcp:{sqlFQDN},1433;Initial Catalog={sqlDBName};User Id={sqlLogin};Password=\'{sqlLoginPassword}\';'
      type: 'SQLAzure'
    }
  ]
})
param connectionStrings array = []

@description('Optional. Enable sending session affinity cookies, which route client requests in the same session to the same instance.')
param clientAffinityEnabled bool = false

@description('Optional. Array of allowed origins hosts.  Use [*] for allow-all.')
param corsAllowedOrigins array = isFunctionApp ? [
  'https://portal.azure.com'
] : []

@description('Optional. True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

// https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings#functions_extension_version
@description('Optional. The version of the Functions runtime that hosts your function app.')
param functionsExtensionVersion string = '~4'

@description('Optional. App Service Environment to use for the app.')
param hostingEnvironmentId string = ''

@description('Optional. Configures a web site to allow clients to connect over http2.0')
param http20Enabled bool = true

@description('Optional. IP security restrictions for main.')
@metadata({
  sampleInput: [
    {
      action: 'Allow or Deny access for this IP range.'
      description: 'IP restriction rule description.'
      headers: {
        // Arrays of up to 8 strings
        'X-Forwarded-Host': []
        'X-Forwarded-For': []
        'X-Azure-FDID': []
        'X-FD-HealthProbe': []
      }
      ipAddress: 'CIDR or Azure Service Tag'
      name: 'IP restriction rule name.'
      priority: 999 // Priority of IP restriction rule.
      tag: 'Default or ServiceTag or XffProxy'
      vnetSubnetResourceId: 'Virtual network resource id.'
    }
    {
      action: 'Allow'
      description: 'Allow traffic from our specific Front Door instance.'
      headers: {
        'X-Azure-FDID': [
          '12345678-1234-1234-1234-123456789012'
        ]
      }
      ipAddress: 'AzureFrontDoor.Backend'
      name: 'Allow Front Door'
      priority: 100
      tag: 'ServiceTag'
    }
  ]
})
param ipSecurityRestrictions array = []

@description('Optional. Default action for main access restriction if no rules are matched.')
@allowed([
  'Allow'
  'Deny'
])
param ipSecurityRestrictionsDefaultAction string = 'Allow'

@description('Optional. Identity to use for Key Vault Reference authentication.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
])
param keyVaultReferenceIdentity string = empty(userAssignedIdentities) ? 'SystemAssigned' : 'UserAssigned'

@description('Optional. Azure Resource Manager ID of the customer\'s selected Managed Environment on which to host this app.')
param managedEnvironmentId string = ''

@description('Optional. Determines whether to preserve unmanaged existing appSettings and connectionStrings. Must be \'false\' on first run/deployment.')
param preserveAppSettings bool = false

@description('Optional. Allow or block all public traffic.')
param publicNetworkAccess bool = true

@description('Optional. Site redundancy mode.')
@allowed([
  'ActiveActive'
  'Failover'
  'GeoRedundant'
  'Manual'
  'None'
])
param redundancyMode string = 'None'

@description('Optional. Function runtime type and version.')
@metadata({
  // https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings#valid-linuxfxversion-values
  // https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages?tabs=isolated-process%2Cv4&pivots=programming-language-powershell#language-support-details
  // https://learn.microsoft.com/en-us/azure/azure-functions/dotnet-isolated-process-guide
  runtime: [
    // entries without comments 'should' work on windows and linux, for api/app/functionapp alike
    'DOCKER|<image reference e.g. mcr.microsoft.com/azure-app-service/windows/parkingpage:latest>'
    'DOTNET|6.0' // for functionapps on linux (yeah, really), and anything on windows
    'DOTNET|7.0' // for functionapps on linux (yeah, really), and anything on windows
    'DOTNETCORE|6.0' // for (api|app),linux
    'DOTNETCORE|7.0' // for (api|app),linux
    'DOTNETCORE|8.0' // for (api|app),linux
    'DOTNET-ISOLATED|4.8'
    'DOTNET-ISOLATED|6.0'
    'DOTNET-ISOLATED|7.0'
    'DOTNET-ISOLATED|8.0'
    'GO|1.19' // for linux
    'JAVA|8'
    'JAVA|11'
    'JAVA|17'
    'NODE|14'
    'NODE|16'
    'NODE|18'
    'NODE|18-lts'
    'NODE|20'
    'NODE|20-lts'
    'PHP|8.0'
    'PHP|8.1'
    'PHP|8.2'
    'POWERSHELL|7.2'
    'PYTHON|3.7' // for linux
    'PYTHON|3.8' // for linux
    'PYTHON|3.9' // for linux
    'PYTHON|3.10' // for linux
    'PYTHON|3.11' // for linux
  ]
})
param runtime string = isLinux && !isFunctionApp ? 'DOTNETCORE|6.0' : 'DOTNET|6.0'

@description('Optional. The language worker runtime to load in the app.')
param runtimeLanguage string = toLower(first(split(runtime, '|')))

@description('Optional. The language worker runtime to load in the app.')
param runtimeVersion string = last(split(runtime, '|'))

@description('Optional. IP security restrictions for scm.')
@metadata({
  sampleInput: [
    {
      action: 'Allow or Deny access for this IP range.'
      description: 'IP restriction rule description.'
      headers: {
        // Arrays of up to 8 strings
        'X-Forwarded-Host': []
        'X-Forwarded-For': []
        'X-Azure-FDID': []
        'X-FD-HealthProbe': []
      }
      ipAddress: 'CIDR or Azure Service Tag'
      name: 'IP restriction rule name.'
      priority: 999 // Priority of IP restriction rule.
      tag: 'Default or ServiceTag or XffProxy'
      vnetSubnetResourceId: 'Virtual network resource id.'
    }
    {
      action: 'Allow'
      description: 'Allow traffic from our specific Front Door instance.'
      headers: {
        'X-Azure-FDID': [
          '12345678-1234-1234-1234-123456789012'
        ]
      }
      ipAddress: 'AzureFrontDoor.Backend'
      name: 'Allow Front Door'
      priority: 100
      tag: 'ServiceTag'
    }
  ]
})
param scmIpSecurityRestrictions array = []

@description('Optional. Default action for scm access restriction if no rules are matched.')
@allowed([
  'Allow'
  'Deny'
])
param scmIpSecurityRestrictionsDefaultAction string = 'Allow'

@description('Optional. IP security restrictions for scm to use main.')
param scmIpSecurityRestrictionsUseMain bool = true

@description('Optional. ResourceId of Storage Account to host Function App.')
param storageAccountId string = ''

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = true

@description('Optional. Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = false

@description('Optional. The list of user assigned identities associated with the resource.')
param userAssignedIdentities object = {}

@description('Optional. To enable accessing content over virtual network.')
param vnetContentShareEnabled bool = true

@description('Optional. To enable pulling image over Virtual Network.')
param vnetImagePullEnabled bool = true

@description('Optional. Virtual Network Route All enabled. This causes all outbound traffic to have Virtual Network Security Groups and User Defined Routes applied.')
param vnetRouteAllEnabled bool = true

@description('Optional. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first.')
param vnetSubnetId string = ''

@description('Optional. A flag that specifies if the scale unit this Web App is on supports Swift integration.')
param vnetSwiftSupported bool = false

/*
** Constructed Parameters, not intended to be set directly
*/

@description('Constructed. Do not set unless necessary.')
param isLinux bool = contains(kind, 'linux')

@description('Constructed. Do not set unless necessary.')
param isFunctionApp bool = contains(kind, 'functionapp')

/*
** Template Specific Variables
*/

var appInsightsTag = empty(appInsightsId) ? {} : {
  'hidden-link: /app-insights-resource-id': appInsightsId
}

// App Settings documentation
// https://learn.microsoft.com/en-us/azure/app-service/reference-app-settings
// https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-se{tings

var appSettingsBase = {
  WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
  WEBSITE_ENABLE_SYNC_UPDATE_SITE: '1'
}

var appSettingsFunctions = isFunctionApp ? {
  FUNCTIONS_EXTENSION_VERSION: functionsExtensionVersion
  FUNCTIONS_WORKER_RUNTIME: runtimeLanguage

  // This setting allows '*_EXTENSION_VERSION' settings to swap with the slot during swap
  // Interpret it as Website Override: Sticky Extension Versions = disabled (non-deployment-slot-specific)
  // Specifically to enable FUNCTIONS_EXTENSION_VERSION changes with slot swaps
  WEBSITE_OVERRIDE_STICKY_EXTENSION_VERSIONS: '0'
} : {}

// WEBSITE_CONTENT* settings only technically required for function apps with autoscaling plans
// AzureWebJobsStorage supports non-storageKey access, but WEBSITE_CONTENT* does not
// TODO: Currently using storageKey-based access for both
var appSettingsFunctionsStorage = isFunctionApp && !empty(storageEndpointString) ? {
  AzureWebJobsStorage: storageEndpointString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageEndpointString

  // Documentation notes that Azure should be allowed to self-manage this
  // But functionapp,linux does not deploy properly without
  // This is the approach from the official samples as at 2023-09
  WEBSITE_CONTENTSHARE: toLower(name)
} : {}

// Azure Monitor / Application Insights / 'Autoinstrumentation' documentation
// https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps
// https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps-net

var appSettingsAppInsightsBase = !empty(appInsightsId) ? {
  APPLICATIONINSIGHTS_CONNECTION_STRING: reference(appInsightsId, '2020-02-02').ConnectionString
  ApplicationInsightsAgent_EXTENSION_VERSION: isLinux ? '~3' : '~2'
  InstrumentationEngine_EXTENSION_VERSION: '~1'
  XDT_MicrosoftApplicationInsights_BaseExtensions: '~1'
  XDT_MicrosoftApplicationInsights_Mode: 'recommended'
} : {}

// https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps-net-core
var appSettingsAppInsightsDotnet = startsWith(runtimeLanguage, 'dotnet') ? {
  XDT_MicrosoftApplicationInsights_PreemptSdk: '1'
} : {}

// https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps-java
var appSettingsAppInsightsJava = runtimeLanguage == 'java' ? {
  APPLICATIONINSIGHTS_ENABLE_AGENT: 'true'
  XDT_MicrosoftApplicationInsights_Java: '1'
} : {}

// https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps-nodejs
var appSettingsAppInsightsNode = runtimeLanguage == 'node' ? {
  XDT_MicrosoftApplicationInsights_NodeJS: '1'
} : {}

// // https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell#powershell-versions
// // Not needed, retained as a reference
// var appSettingsPowershell = runtimeLanguage == 'powershell' ? {
//   FUNCTIONS_WORKER_RUNTIME_VERSION: runtimeVersion
// } : {}

var appSettingsVnet = vnetContentShareEnabled && !empty(vnetSubnetId) ? {
  WEBSITE_CONTENTOVERVNET: '1'
} : {}

// WEBSITE_NODE_DEFAULT_VERSION is only required on Windows
var appSettingsNode = runtimeLanguage == 'node' && !isLinux ? {
  WEBSITE_NODE_DEFAULT_VERSION: nodeVersion
} : {}

// Ensure appInsights settings are only applied if an ID is provided
var appSettingsAppInsights = empty(appInsightsId) ? {} : union(appSettingsAppInsightsBase, appSettingsAppInsightsDotnet, appSettingsAppInsightsNode, appSettingsAppInsightsJava)

// Combine all the various computed settings
var appSettingsComputed = union(appSettingsBase, appSettingsAppInsights, appSettingsFunctions, appSettingsFunctionsStorage, appSettingsVnet, appSettingsNode)

// Retrieve current settings if not the first run
var appSettingsCurrent = preserveAppSettings ? siteAppSettings.outputs.appSettings : {}

// Mash all the settings together in priority, high to low
// ToAdd > Computed > Current > Defaults
var appSettingsBeforeRemove = union(appSettingsDefaults, appSettingsCurrent, appSettingsComputed, appSettingsToAdd)

// Finally, remove any settings listed in appSettingsToRemove
var appSettings = reduce(items(appSettingsBeforeRemove), {}, (current, next) => union(current, contains(appSettingsToRemove, next.key) ? {} : { '${next.key}': next.value }))

var cors = {
  allowedOrigins: corsAllowedOrigins
  supportCredentials: corsSupportCredentials
}

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

// Most things on Windows need a default netFrameworkVersion too (v6.0 LTS)
var netFrameworkVersion = startsWith(runtimeLanguage, 'dotnet') ? 'v${runtimeVersion}' : 'v6.0'

// Allow for NODE|18 and NODE|18-lts style version parameters
var nodeVersion = runtimeLanguage == 'node' ? '~${first(split(runtimeVersion, '-'))}' : ''

var phpVersion = runtimeLanguage == 'php' ? runtimeVersion : 'OFF'

var powerShellVersion = runtimeLanguage == 'powershell' ? runtimeVersion : ''

var siteTags = union(tags, appInsightsTag)

var storageAccountName = empty(storageAccountId) ? '' : last(split(storageAccountId, '/'))

// Only attempt to retrieve an account key if a storageAccountId has been provided
var storageEndpoint = empty(storageAccountName) ? {} : {
  AccountKey: first(listKeys(storageAccountId, '2023-01-01').keys).value
  AccountName: storageAccountName
  DefaultEndpointsProtocol: 'https'
  EndpointSuffix: environment().suffixes.storage
}

// Construct a proper connection string from the dictionary object above
var storageEndpointString = empty(storageEndpoint) ? '' : join(map(items(storageEndpoint), item => join([ item.key, item.value ], '=')), ';')

/*
** 'Boiler-plate' Variables
*/

var diagnosticsLogs = [for categoryGroup in diagnosticLogCategoryGroupsToEnable: {
  categoryGroup: categoryGroup
  enabled: true
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

var diagnosticsName = toLower('${site.name}-dgs')

var lockName = toLower('${site.name}-${resourceLock}-lck')

/*
** Helper Module(s)
*/

module siteAppSettings 'helper/app-settings-read.bicep' = if (preserveAppSettings) {
  name: '${name}-app-settings-read'
  params: {
    name: name
  }
}

/*
** Main Resource Deployment
*/

resource site 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: siteTags
  kind: kind
  identity: identity
  properties: {
    // security requirements
    httpsOnly: true

    clientAffinityEnabled: clientAffinityEnabled
    // Client Cert must be disabled if HTTP/2 is enabled
    clientCertEnabled: http20Enabled ? false : null
    hostingEnvironmentProfile: empty(hostingEnvironmentId) ? null : {
      id: hostingEnvironmentId
    }
    keyVaultReferenceIdentity: empty(keyVaultReferenceIdentity) ? null : keyVaultReferenceIdentity
    managedEnvironmentId: empty(managedEnvironmentId) ? null : managedEnvironmentId
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    redundancyMode: redundancyMode
    reserved: isLinux
    serverFarmId: serverFarmId

    vnetContentShareEnabled: !empty(vnetSubnetId) ? vnetContentShareEnabled : null
    vnetImagePullEnabled: !empty(vnetSubnetId) ? vnetImagePullEnabled : null
    vnetRouteAllEnabled: !empty(vnetSubnetId) ? vnetRouteAllEnabled : null
  }

  // security requirements
  resource basicAuthFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  // security requirements
  resource basicAuthScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: appSettings
  }

  // TODO: Metatdata could be given the appSettings treatment for preserving/defaults/add/remove
  resource configMetadata 'config' = {
    name: 'metadata'
    properties: {
      CURRENT_STACK: runtimeLanguage
    }
  }

  resource configWeb 'config' = {
    name: 'web'
    properties: {
      // security requirements
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'

      acrUseManagedIdentityCreds: acrUseManagedIdentityCreds
      // TODO: acrUserManagedIdentityID: acrUserManagedIdentityID
      alwaysOn: alwaysOn
      appCommandLine: !empty(appCommandLine) ? appCommandLine : null
      connectionStrings: !empty(connectionStrings) ? connectionStrings : null
      cors: !empty(corsAllowedOrigins) ? cors : null
      http20Enabled: http20Enabled
      ipSecurityRestrictions: ipSecurityRestrictions
      ipSecurityRestrictionsDefaultAction: ipSecurityRestrictionsDefaultAction

      // All linux Apps are effectively Docker Container Web Apps
      linuxFxVersion: isLinux ? runtime : ''

      // Per-language *Version settings only required on Windows
      // TODO: Test results with a Windows Docker Container Web App
      netFrameworkVersion: isLinux || empty(netFrameworkVersion) ? null : netFrameworkVersion
      nodeVersion: isLinux || empty(nodeVersion) ? null : nodeVersion
      phpVersion: isLinux || empty(phpVersion) ? null : phpVersion
      powerShellVersion: isLinux || empty(powerShellVersion) ? null : powerShellVersion

      scmIpSecurityRestrictions: scmIpSecurityRestrictions
      scmIpSecurityRestrictionsDefaultAction: scmIpSecurityRestrictionsDefaultAction
      scmIpSecurityRestrictionsUseMain: scmIpSecurityRestrictionsUseMain
      use32BitWorkerProcess: use32BitWorkerProcess

      // Windows Docker Container Web Apps
      windowsFxVersion: runtimeLanguage == 'docker' && !isLinux ? runtime : ''
    }
  }

  resource networkConfigVnet 'networkConfig' = if (!empty(vnetSubnetId)) {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: vnetSubnetId
      swiftSupported: vnetSwiftSupported
    }
  }
}

/*
** 'Boiler-plate' Resources
*/

resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (resourceLock != 'NotSpecified') {
  scope: site
  name: lockName
  properties: {
    level: resourceLock
    notes: (resourceLock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

// Preview diagnosticSettings API has not been updated recently by Microsoft but is preferred over the latest GA version (2016-09-01)
#disable-next-line use-recent-api-versions
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: site
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

/*
** Outputs
*/

@description('The name of the deployed site.')
output name string = site.name

@description('The resource ID of the deployed site.')
output resourceId string = site.id

@description('The GUID of the managed identity in use by the site.')
output managedIdentityPrincipalId string = site.identity.principalId

@description('Default hostname of the site.')
output defaultHostname string = site.properties.defaultHostName
