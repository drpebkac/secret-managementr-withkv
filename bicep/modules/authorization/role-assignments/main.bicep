@description('Required. The resource ID of the resource to apply the role assignment to.')
param resourceId string

@description('Required. The ID of the principal to assign the role to.')
param principalId string

@description('Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.')
param roleDefinitionIdOrName string

@description('Optional. The principal type of the assigned principal ID.')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
  'Device'
  ''
])
param principalType string = ''

@description('Optional. The description of the role assignment.')
param roleAssignmentDescription string = ''

@description('Optional. This is used in special scenarios, such as for Managed Application cross-tenant role assignments.')
param delegatedManagedIdentityResourceId string = ''

var builtInRoleNames = {
  #disable-next-line prefer-unquoted-property-names
  'Owner': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  #disable-next-line prefer-unquoted-property-names
  'Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  #disable-next-line prefer-unquoted-property-names
  'Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  'Application Insights Component Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ae349356-3a1b-4a5e-921d-050484c6347e')
  'Application Insights Snapshot Debugger': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '08954f03-6346-4c2e-81c0-ec3a5cfae23b')
  'Automation Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f353d9bd-d4a6-484e-a77a-8050b599b867')
  'Automation Job Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4fe576fe-1146-4730-92eb-48519fa6bf9f')
  'Automation Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'd3881f73-407a-4167-8283-e981cbba0404')
  'Automation Runbook Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5fb5aef8-1081-4b8e-bb16-9d5d0385bab5')
  'Azure Kubernetes Fleet Manager RBAC Admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '434fb43a-c01c-447e-9f67-c3ad923cfaba')
  'Azure Kubernetes Fleet Manager RBAC Cluster Admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18ab4d3d-a1bf-4477-8ad9-8359bc988f69')
  'Azure Kubernetes Fleet Manager RBAC Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '30b27cfc-9c84-438e-b0ce-70e35255df80')
  'Azure Kubernetes Fleet Manager RBAC Writer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5af6afb3-c06c-4fa4-8848-71a8aee05683')
  'Azure Kubernetes Service RBAC Admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3498e952-d568-435e-9b2c-8d77e338d7f7')
  'Azure Kubernetes Service RBAC Cluster Admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b')
  'Azure Kubernetes Service RBAC Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f6c6a51-bcf8-42ba-9220-52d62157d7db')
  'Azure Kubernetes Service RBAC Writer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb')
  'Backup Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e467623-bb1f-42f4-a55d-6e525e11384b')
  'Backup Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00c29273-979b-4161-815c-10b084fb9324')
  'Backup Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a795c7a0-d4a2-40c1-ae25-d81f01202912')
  'Key Vault Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
  'Key Vault Certificates Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
  'Key Vault Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f25e0fa2-a7c8-4377-a976-54943a77a395')
  'Key Vault Crypto Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '14b46e9e-c2b7-41b4-b07b-48a6ebf60603')
  'Key Vault Crypto Service Encryption User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
  'Key Vault Crypto User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
  'Key Vault Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '21090545-7ca7-4776-b22c-e363652d74d2')
  'Key Vault Secrets Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  'Key Vault Secrets User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  'Log Analytics Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
  'Log Analytics Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '73c42c96-874c-492b-b04d-ab87d138a893')
  'Managed Application Contributor Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '641177b8-a67a-45b9-a033-47bc880bb21e')
  'Managed Application Operator Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c7393b34-138c-406f-901b-d8cf2b17e6ae')
  'Managed Applications Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b9331d33-8a36-4f8c-b097-4f54124fdb44')
  'Monitoring Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
  'Monitoring Metrics Publisher': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
  'Monitoring Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  'Kubernetes Cluster - Azure Arc Onboarding': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '34e09817-6cbe-4d01-b1a2-e0eac5743d41')
  'Kubernetes Extension Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '85cb6faf-e071-4c9b-8136-154b5a04f717')
  'Logic App Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '87a39d53-fc1b-424a-814c-f7e04687dc9e')
  'Logic App Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '515c2055-d9d4-4321-b1b9-bd0c9a0f79fe')
  'Managed Identity Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e40ec5ca-96e0-45a2-b4ff-59039f2c2b59')
  'Managed Identity Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
  'Microsoft Sentinel Automation Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f4c81013-99ee-4d62-a7ee-b3f1f648599a')
  'Microsoft Sentinel Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ab8e14d6-4a74-4a29-9ba8-549422addade')
  'Microsoft Sentinel Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8d289c81-5878-46d4-8554-54e1e3d8b5cb')
  'Microsoft Sentinel Responder': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3e150937-b8fe-4cfb-8069-0eaf05ecd056')
  'Storage Account Backup Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1')
  'Storage Account Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab')
  'SQL DB Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec')
  'SQL Managed Instance Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4939a1f6-9ae0-4e48-a1e0-f2cbe897382d')
  'SQL Security Manager': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '056cd41c-7e88-42e1-933e-88ba6a50c9c3')
  'SQL Server Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437')
  'Web Plan Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2cc479cb-7b4d-49a8-b449-8c00fd0f0a4b')
  'Web PubSub Service Owner': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12cf5a90-567b-43ae-8102-96cf46c7d9b4')
  'Web PubSub Service Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'bfb1c7d2-fb1a-466b-b2ba-aee63b92deaf')
  'Website Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'de139f84-1756-47ae-9be6-808fbbe84772')
  'Desktop Virtualization Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c')
  'Virtual Machine Administrator Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1c0163c0-47e6-4577-8991-ea5c82e286e4')
  'Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
  'Virtual Machine Data Access Administrator (preview)': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '66f75aeb-eabe-4b70-9f1e-c350c4c9ad04')
  'Virtual Machine Local User Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '602da2ba-a5c2-41da-b01d-5360126ab525')
  'Virtual Machine User Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceId, principalId, roleDefinitionIdOrName)
  properties: {
    description: roleAssignmentDescription
    roleDefinitionId: contains(builtInRoleNames, roleDefinitionIdOrName) ? builtInRoleNames[roleDefinitionIdOrName] : roleDefinitionIdOrName
    principalId: principalId
    principalType: !empty(principalType) ? any(principalType) : null
    delegatedManagedIdentityResourceId: !empty(delegatedManagedIdentityResourceId) ? delegatedManagedIdentityResourceId : null
  }
}
