# Key Vaults Module

This module deploys Microsoft.KeyVault vaults

## Details

- Creates Microsoft.KeyVault vaults resource.
- Applies network rules to the key vault if specified.
- Applies access policies to the key vault if specified.
- Applies diagnostic settings.
- Applies a lock to the key vault if the lock is specified.

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                    |
| :-------------------------------------- | :------: | :------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                                  | `string` | Yes      | The resource name.                                                                                                                                                                                                                             |
| `location`                              | `string` | Yes      | The geo-location where the resource lives.                                                                                                                                                                                                     |
| `tags`                                  | `object` | No       | Optional. Resource tags.                                                                                                                                                                                                                       |
| `sku`                                   | `string` | No       | Optional. The sku of the key vault.                                                                                                                                                                                                            |
| `enabledForDeployment`                  | `bool`   | No       | Optional. Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.                                                                                                      |
| `enabledForDiskEncryption`              | `bool`   | No       | Optional. Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.                                                                                                                   |
| `enabledForTemplateDeployment`          | `bool`   | No       | Optional. Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.                                                                                                                              |
| `enablePurgeProtection`                 | `bool`   | No       | Optional. Property specifying whether protection against purge is enabled for this vault.                                                                                                                                                      |
| `softDeleteRetentionInDays`             | `int`    | No       | Optional. SoftDelete data retention days. It accepts >=7 and <=90.                                                                                                                                                                             |
| `enableRbacAuthorization`               | `bool`   | No       | Optional. Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored. |
| `accessPolicies`                        | `array`  | No       | Optional. An array of 0 to 1024 identities that have access to the key vault. Only required when enableRbacAuthorization is set to "false".                                                                                                    |
| `networkAcls`                           | `object` | No       | Optional. Rules governing the accessibility of the key vault from specific network locations.                                                                                                                                                  |
| `resourceLock`                          | `string` | No       | Optional. Specify the type of resource lock.                                                                                                                                                                                                   |
| `enableDiagnostics`                     | `bool`   | No       | Optional. Enable diagnostic logging.                                                                                                                                                                                                           |
| `diagnosticLogCategoryGroupsToEnable`   | `array`  | No       | Optional. The name of log category groups that will be streamed.                                                                                                                                                                               |
| `diagnosticMetricsToEnable`             | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                           |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Storage account resource id. Only required if enableDiagnostics is set to true.                                                                                                                                                      |
| `diagnosticLogAnalyticsWorkspaceId`     | `string` | No       | Optional. Log analytics workspace resource id. Only required if enableDiagnostics is set to true.                                                                                                                                              |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.                                                                                                                        |
| `diagnosticEventHubName`                | `string` | No       | Optional. Event hub name. Only required if enableDiagnostics is set to true.                                                                                                                                                                   |

## Outputs

| Name         | Type     | Description                                |
| :----------- | :------: | :----------------------------------------- |
| `name`       | `string` | The name of the deployed key vault.        |
| `resourceId` | `string` | The resource ID of the deployed key vault. |
| `uri`        | `string` | The uri of the deployed key vault.         |

## Examples

Please see the [Bicep Tests](test/main.test.bicep) file for examples.