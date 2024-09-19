# Web Apps and Function Apps

This module deploys Microsoft.web/sites aka Web Apps and Function Apps

## Details

This module completes the following tasks:

- Creates Microsoft.Web sites resource.
- Applies app config settings changes if specified (appSettings* and preserveAppSettings).
- Applies runtime and other site configuration settings.
- Applies network rules to the site if specified.
- Applies vnet injection to the site if specified.
- Applies diagnostic settings.
- Applies a lock to the site if the lock is specified.

## Parameters

| Name                                     | Type     | Required | Description                                                                                                                                            |
| :--------------------------------------- | :------: | :------: | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                                   | `string` | Yes      | The resource name.                                                                                                                                     |
| `location`                               | `string` | Yes      | The geo-location where the resource lives.                                                                                                             |
| `kind`                                   | `string` | Yes      | Kind of web site.                                                                                                                                      |
| `serverFarmId`                           | `string` | Yes      | Resource ID of the associated App Service plan.                                                                                                        |
| `tags`                                   | `object` | No       | Optional. Resource tags.                                                                                                                               |
| `resourceLock`                           | `string` | No       | Optional. Specify the type of resource lock.                                                                                                           |
| `enableDiagnostics`                      | `bool`   | No       | Optional. Enable diagnostic logging.                                                                                                                   |
| `diagnosticLogCategoryGroupsToEnable`    | `array`  | No       | Optional. The name of log category groups that will be streamed.                                                                                       |
| `diagnosticMetricsToEnable`              | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                   |
| `diagnosticStorageAccountId`             | `string` | No       | Optional. Storage account resource id. Only required if enableDiagnostics is set to true.                                                              |
| `diagnosticLogAnalyticsWorkspaceId`      | `string` | No       | Optional. Log analytics workspace resource id. Only required if enableDiagnostics is set to true.                                                      |
| `diagnosticEventHubAuthorizationRuleId`  | `string` | No       | Optional. Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.                                |
| `diagnosticEventHubName`                 | `string` | No       | Optional. Event hub name. Only required if enableDiagnostics is set to true.                                                                           |
| `acrUseManagedIdentityCreds`             | `bool`   | No       | Optional. Use Managed Identity Creds for Azure Container Registry access.                                                                              |
| `alwaysOn`                               | `bool`   | No       | Optional. Keeps app as always on (hot).                                                                                                                |
| `appCommandLine`                         | `string` | No       | Optional. App command line to launch.                                                                                                                  |
| `appInsightsId`                          | `string` | No       | Optional. Resource ID of Application Insights instance for monitoring.                                                                                 |
| `appSettingsDefaults`                    | `object` | No       | Optional. Custom App Settings to be added if they don't exist.                                                                                         |
| `appSettingsToAdd`                       | `object` | No       | Optional. Custom App Settings to be added.                                                                                                             |
| `appSettingsToRemove`                    | `array`  | No       | Optional. Custom App Setting Keys to be removed.                                                                                                       |
| `connectionStrings`                      | `array`  | No       | Optional. Array of Connection Strings.                                                                                                                 |
| `clientAffinityEnabled`                  | `bool`   | No       | Optional. Enable sending session affinity cookies, which route client requests in the same session to the same instance.                               |
| `corsAllowedOrigins`                     | `array`  | No       | Optional. Array of allowed origins hosts.  Use [*] for allow-all.                                                                                      |
| `corsSupportCredentials`                 | `bool`   | No       | Optional. True/False on whether to enable Support Credentials for CORS.                                                                                |
| `functionsExtensionVersion`              | `string` | No       | Optional. The version of the Functions runtime that hosts your function app.                                                                           |
| `hostingEnvironmentId`                   | `string` | No       | Optional. App Service Environment to use for the app.                                                                                                  |
| `http20Enabled`                          | `bool`   | No       | Optional. Configures a web site to allow clients to connect over http2.0                                                                               |
| `ipSecurityRestrictions`                 | `array`  | No       | Optional. IP security restrictions for main.                                                                                                           |
| `ipSecurityRestrictionsDefaultAction`    | `string` | No       | Optional. Default action for main access restriction if no rules are matched.                                                                          |
| `keyVaultReferenceIdentity`              | `string` | No       | Optional. Identity to use for Key Vault Reference authentication.                                                                                      |
| `managedEnvironmentId`                   | `string` | No       | Optional. Azure Resource Manager ID of the customer's selected Managed Environment on which to host this app.                                          |
| `preserveAppSettings`                    | `bool`   | No       | Optional. Determines whether to preserve unmanaged existing appSettings and connectionStrings. Must be 'false' on first run/deployment.                |
| `publicNetworkAccess`                    | `bool`   | No       | Optional. Allow or block all public traffic.                                                                                                           |
| `redundancyMode`                         | `string` | No       | Optional. Site redundancy mode.                                                                                                                        |
| `runtime`                                | `string` | No       | Optional. Function runtime type and version.                                                                                                           |
| `runtimeLanguage`                        | `string` | No       | Optional. The language worker runtime to load in the app.                                                                                              |
| `runtimeVersion`                         | `string` | No       | Optional. The language worker runtime to load in the app.                                                                                              |
| `scmIpSecurityRestrictions`              | `array`  | No       | Optional. IP security restrictions for scm.                                                                                                            |
| `scmIpSecurityRestrictionsDefaultAction` | `string` | No       | Optional. Default action for scm access restriction if no rules are matched.                                                                           |
| `scmIpSecurityRestrictionsUseMain`       | `bool`   | No       | Optional. IP security restrictions for scm to use main.                                                                                                |
| `storageAccountId`                       | `string` | No       | Optional. ResourceId of Storage Account to host Function App.                                                                                          |
| `systemAssignedIdentity`                 | `bool`   | No       | Optional. Enables system assigned managed identity on the resource.                                                                                    |
| `use32BitWorkerProcess`                  | `bool`   | No       | Optional. Sets 32-bit vs 64-bit worker architecture                                                                                                    |
| `userAssignedIdentities`                 | `object` | No       | Optional. The list of user assigned identities associated with the resource.                                                                           |
| `vnetContentShareEnabled`                | `bool`   | No       | Optional. To enable accessing content over virtual network.                                                                                            |
| `vnetImagePullEnabled`                   | `bool`   | No       | Optional. To enable pulling image over Virtual Network.                                                                                                |
| `vnetRouteAllEnabled`                    | `bool`   | No       | Optional. Virtual Network Route All enabled. This causes all outbound traffic to have Virtual Network Security Groups and User Defined Routes applied. |
| `vnetSubnetId`                           | `string` | No       | Optional. This is the subnet that this Web App will join. This subnet must have a delegation to Microsoft.Web/serverFarms defined first.               |
| `vnetSwiftSupported`                     | `bool`   | No       | Optional. A flag that specifies if the scale unit this Web App is on supports Swift integration.                                                       |
| `isLinux`                                | `bool`   | No       | Constructed. Do not set unless necessary.                                                                                                              |
| `isFunctionApp`                          | `bool`   | No       | Constructed. Do not set unless necessary.                                                                                                              |

## Outputs

| Name                         | Type     | Description                                          |
| :--------------------------- | :------: | :--------------------------------------------------- |
| `name`                       | `string` | The name of the deployed site.                       |
| `resourceId`                 | `string` | The resource ID of the deployed site.                |
| `managedIdentityPrincipalId` | `string` | The GUID of the managed identity in use by the site. |
| `defaultHostname`            | `string` | Default hostname of the site.                        |

## Examples

Please see the [Bicep Tests](test/main.test.bicep) file for examples.
