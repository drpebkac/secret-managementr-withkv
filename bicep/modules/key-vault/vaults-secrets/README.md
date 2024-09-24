# Key Vaults Secrets Module

This module deploys Microsoft.KeyVault/vaults/secrets

## Details

- Creates Microsoft.KeyVault.Vaults.Secret secret resource.
- Adds secrets to existing key vaults.
- Defines value of the vault secret.
- Applies Expiry Date and Not Before Date if specified.

## Parameters

| Name           | Type           | Required | Description                             |
| :------------- | :------------: | :------: | :-------------------------------------- |
| `name`         | `string`       | Yes      | The resource name.                      |
| `tags`         | `object`       | No       | Optional. Resource tags.                |
| `keyVaultName` | `string`       | Yes      | The name of the existing key vault.     |
| `value`        | `securestring` | Yes      | The value of the secret.                |
| `attributes`   | `object`       | No       | Optional. The attributes of the secret. |

## Outputs

| Name             | Type     | Description                                  |
| :--------------- | :------: | :------------------------------------------- |
| `name`           | `string` | The name of the deployed secret.             |
| `resourceId`     | `string` | The resource ID of the deployed secret.      |
| `uri`            | `string` | The uri of the deployed secret.              |
| `uriWithVersion` | `string` | The uri with version of the deployed secret. |

## Examples

Please see the [Bicep Tests](test/main.test.bicep) file for examples.