@description('The name of the existing function app')
param functionAppName string

param appSettings array

//var currentAppSettings = list(resourceId('Microsoft.Web/sites/config', functionApp.name, 'appsettings'), '2021-03-01').properties

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource faConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: {
    appSettings: string(union(functionApp.properties.siteConfig,appSettings))

    

  }
}
