metadata name = 'Key Vaults Secrets Module'
metadata description = 'This module deploys Microsoft.KeyVault/vaults/secrets'
metadata owner = 'Arinco'

@description('The resource name.')
param name string

@description('Optional. Resource tags.')
@metadata({
  doc: 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#arm-templates'
  example: {
    tagKey: 'string'
  }
})
param tags object = {}

@description('The name of the existing key vault.')
param keyVaultName string

@description('The value of the secret.')
@secure()
param value string

@description('Optional. The attributes of the secret.')
@metadata({
  enabled: 'Determines whether the object is enabled. Accepted values are "true" or "false".'
  exp: 'Expiry date in seconds since 1970-01-01T00:00:00Z. Date/time format in epoch/ticks https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#datetimetoepoch.'
  nbf: 'Not before date in seconds since 1970-01-01T00:00:00Z. Date/time format in epoch/ticks https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#datetimetoepoch.'
})
param attributes object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: name
  tags: tags
  properties: {
    value: value
    attributes: attributes
  }
}

@description('The name of the deployed secret.')
output name string = secret.name

@description('The resource ID of the deployed secret.')
output resourceId string = secret.id

@description('The uri of the deployed secret.')
output uri string = secret.properties.secretUri

@description('The uri with version of the deployed secret.')
output uriWithVersion string = secret.properties.secretUriWithVersion
