@description('A blob service may contain more than one container. Container names are parsed through and iterated to create containers')
param containers array

@description('The name referencing the parent storage account')
param storageAccountName string

// Required to be declared for blob containers to be created
@description('A blob reference needs to be created before containers can')
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' existing = {
  name: '${storageAccountName}/default'
}

//Creates containers using the array of container
resource blobcontainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [ for container in containers: {
  name: container.name
  parent: blobServices
  properties: {
    publicAccess: 'None'
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: true
    metadata: {}
  }
}]
