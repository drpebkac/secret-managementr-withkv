/*======================================================================
GLOBAL CONFIGURATION
======================================================================*/
@description('Optional. The geo-location where the resource lives.')
param location string = resourceGroup().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
@minLength(1)
@maxLength(5)
param shortIdentifier string = 'arn'

/*======================================================================
TEST PREREQUISITES
======================================================================*/
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${shortIdentifier}-tst-umi-${uniqueString(deployment().name, 'umi', location)}'
  location: location
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${shortIdentifier}-tst-vnet-${uniqueString(deployment().name, 'virtualNetworks', location)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${shortIdentifier}-tst-law-${uniqueString(deployment().name, 'logAnalyticsWorkspace', location)}'
  location: location
}

resource diagnosticsStorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${shortIdentifier}tstdiag${uniqueString(deployment().name, 'diagnosticsStorageAccount', location)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
resource diagnosticsEventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: '${shortIdentifier}tstdiag${uniqueString(deployment().name, 'diagnosticsEventHubNamespace', location)}'
  location: location
}

/*======================================================================
TEST EXECUTION
======================================================================*/
module keyVaultMinimum '../main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-min-kv'
  params: {
    name: '${shortIdentifier}-kv-min-${uniqueString(deployment().name, 'keyVault', location)}'
    location: location
  }
}

module automationAccount '../main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-kv'
  params: {
    name: '${shortIdentifier}-kv-${uniqueString(deployment().name, 'keyVault', location)}'
    location: location
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: '124.56.78.0/24'
        }
      ]
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/default'
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
    }
    accessPolicies: [
      {
        objectId: userIdentity.properties.principalId
        permissions: {
          certificates: [
            'create'
            'get'
            'getissuers'
            'import'
            'list'
            'listissuers'
            'setissuers'
            'update'
          ]
          keys: [
            'create'
            'decrypt'
            'encrypt'
            'get'
            'getrotationpolicy'
            'import'
            'list'
            'rotate'
            'setrotationpolicy'
            'update'
          ]
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
    enableRbacAuthorization: false
    enablePurgeProtection: false
    enableDiagnostics: true
    diagnosticLogAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    diagnosticStorageAccountId: diagnosticsStorageAccount.id
    diagnosticEventHubAuthorizationRuleId: '${diagnosticsEventHubNamespace.id}/authorizationrules/RootManageSharedAccessKey'
    resourceLock: 'CanNotDelete'
  }
}
