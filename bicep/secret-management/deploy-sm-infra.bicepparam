using 'deploy-sm-infra.bicep'

//// *** Resource naming prefix will vary for different customer, change values as accordingly to customer's naming conventions *** ////

// Global variables - Default prefixes for resource names

var prefix = 'ccv-srt-mgmr'
var storagePrefix = toLower(replace(prefix, '-', ''))

// Global resource name parameters - Default prefixes for resource names

param appServicePlanName = '${prefix}-asp'

param functionAppName = '${prefix}-func'

param resourceGroupName = 'secrets-management-rg'

param location = 'australiaeast'

param tags = {
  serviceProvider: 'Arinco'
}

param workspaceName = '${prefix}-law'

param functionAppStorageAccountName = '${storagePrefix}fasa'

param reportsStorageAccountName = '${storagePrefix}sa'

param kvName = '${prefix}-kv'

// Set these parameter values as required. These app setting values define the behaviour of the function app and the composition of notifcation email

param appSettings = {
  SM_SCHEDULE_CRON: '0 0 07 * * MON' // Cron expression to indicate on what schedule the report should be generated. Current setting runs 7am Mondays
  SM_CLIENT_NAME: 'ccv' // Client name to be used in the report
  SM_NEAR_EXPIRY_DAYS: 28 // Number of days to look back for secrets that are about to expire
  SM_APP_EXCLUSION_LIST: '' // Comma separated list of app registrations to exclude from the report
  SM_ENABLE_STALE_SECRET_CLEANUP: 'False' // Use 'True or 'False'
  SM_NOTIFY_MSTEAMS_WEBHOOK: 'False' // Use 'True or 'False'v
  SM_NOTIFY_EMAIL_WITH_GRAPH: 'True' // Use 'True or 'False'
  SM_NOTIFY_EMAIL_WITH_SENDGRID: 'False' // Use 'True or 'False'
  SM_NOTIFY_EMAIL_FROM_ADDRESS: 'itsupport@ittttt.it' // Email address to send the report from
  SM_NOTIFY_EMAIL_TO_ADDRESS: 'abc@def.hij,klm@nop' // Comma separated list of email addresses to send the report to
  SM_APP_REG_REPORT_MAIL_SUBJECT: '[IMPORTANT] Your app registration secrets are due to expire'
  SM_APP_REG_REPORT_MAIL_MESSAGE: '<p>Hello<br>\n<br>\nPlease be advised that you have app registration secrets that are due to expire. <br>\n<br>\nAttached is a report listing the secrets.<br>\n<br>\nIt is crucial the secrets listed are renewed, prior to its expiry date to avoid downtime with your services. <br>\n<br>\nThank you</p>'
  SM_KEY_VAULT_REPORT_MAIL_SUBJECT: '[IMPORTANT] Your key vault secrets are due to expire'
  SM_KEY_VAULT_REPORT_MAIL_MESSAGE: '<p>Hello<br>\n<br>\nPlease be advised that you have key vault secrets that are due to expire or have no expire date. <br>\n<br>\nAttached is a report listing the secrets.<br>\n<br>\nIt is crucial the secrets listed are renewed, prior to its expiry date to avoid downtime with your services.<br>\n<br>\n If any errors were encountered when scanning key vaults, a log will be attached.  <br>\n<br>\nThank you</p>'

}

//// *** Some customers may have key vaults secured behind a private network. *** ////
//// *** These variables define Virtual Network settings required to enable secrets management function app to connect to key vaults. *** ////
//// *** Uncomment and define this section to enable this functionality. *** ////

// var vnetSubscriptionId = '2203f013-1a68-42ec-9c0b-80346b7c1cdf'
// var vnetResourceGroupName = 'shd-network-rgp'
// var vnetName = 'shd-mel-vnw01'
// var vnetSubnetName = 'SecretsManagement'
// param vnetSubnetId = '/subscriptions/${vnetSubscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${vnetSubnetName}'


