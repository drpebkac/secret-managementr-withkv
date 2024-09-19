# Application Insights Module

This module deploys Microsoft.Insights/components, aka Applications Insights.

## Details

This module completes the following tasks:

- Creates Microsoft.Insights components resource.
- Applies a lock to the component if specified.

## Parameters

| Name                              | Type     | Required | Description                                                                                                                            |
| :-------------------------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                            | `string` | Yes      | The resource name.                                                                                                                     |
| `location`                        | `string` | Yes      | The geo-location where the resource lives.                                                                                             |
| `workspaceResourceId`             | `string` | Yes      | ResourceId of Log Analytics to associate App Insights to.                                                                              |
| `tags`                            | `object` | No       | Optional. Resource tags.                                                                                                               |
| `resourceLock`                    | `string` | No       | Optional. Specify the type of resource lock.                                                                                           |
| `applicationType`                 | `string` | No       | Optional. Type of application being monitored.                                                                                         |
| `disableIpMasking`                | `bool`   | No       | Optional. Disable IP masking.                                                                                                          |
| `disableLocalAuth`                | `bool`   | No       | Optional. Disable Non-AAD based Auth.                                                                                                  |
| `kind`                            | `string` | No       | Optional. The kind of application that this component refers to, used to customize UI.                                                 |
| `publicNetworkAccessForIngestion` | `bool`   | No       | Optional. The network access type for accessing Application Insights ingestion.                                                        |
| `publicNetworkAccessForQuery`     | `bool`   | No       | Optional. The network access type for accessing Application Insights query.                                                            |
| `samplingPercentage`              | `int`    | No       | Optional. Percentage of the data produced by the application being monitored that is being sampled for Application Insights telemetry. |

## Outputs

| Name         | Type     | Description                                                     |
| :----------- | :------: | :-------------------------------------------------------------- |
| `name`       | `string` | The name of the deployed applications insights resource.        |
| `resourceId` | `string` | The resource ID of the deployed applications insights resource. |

## Examples

Please see the [Bicep Tests](test/main.test.bicep) file for examples.