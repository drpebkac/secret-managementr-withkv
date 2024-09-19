// Helper bicep specifically for reading existing App Settings

@description('Name of existing site')
param name string

resource app 'Microsoft.Web/sites@2022-09-01' existing = {
  name: name
}

var appSettings = list('${app.id}/config/appsettings', app.apiVersion).properties

@description('App Settings from existing site')
output appSettings object = appSettings
