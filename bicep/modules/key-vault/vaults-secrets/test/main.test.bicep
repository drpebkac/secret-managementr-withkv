/*======================================================================
GLOBAL CONFIGURATION
======================================================================*/
@description('Optional. The geo-location where the resource lives.')
param location string = resourceGroup().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
@minLength(1)
@maxLength(5)
param shortIdentifier string = 'arn'

@description('Optional. Secret vaule to add to key vault.')
@secure()
param value string = '${shortIdentifier}-${newGuid()}'

@description('Optional. Expiry date for secret value.')
param valueExpiry int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P90D'))

/*======================================================================
TEST PREREQUISITES
======================================================================*/
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${shortIdentifier}-kvscrt-${uniqueString(deployment().name, 'keyVault', location)}'
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
  }
}

/*======================================================================
TEST EXECUTION
======================================================================*/
module secretMinimum '../main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-min-secret'
  params: {
    name: '${shortIdentifier}-tst-kv-min-${uniqueString(deployment().name, 'keyVaultSecret', location)}'
    keyVaultName: keyVault.name
    value: value
  }
}

module secret '../main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-secret'
  params: {
    name: '${shortIdentifier}-tst-kv-${uniqueString(deployment().name, 'keyVaultSecret', location)}'
    keyVaultName: keyVault.name
    value: value
    attributes: {
      enabled: false
      exp: valueExpiry
    }
  }
}
