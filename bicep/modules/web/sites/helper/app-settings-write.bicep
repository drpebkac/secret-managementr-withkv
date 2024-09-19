// Helper bicep specifically for writing App Settings

@description('Name of existing site.')
param name string

@description('Optional. App Settings to be written.')
@metadata({
  key1: 'value1'
  key2: 'value2'
})
param appSettings object = {}

resource app 'Microsoft.Web/sites@2022-09-01' existing = {
  name: name
}

resource appConfigSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: app
  name: 'appsettings'
  properties: appSettings
}
