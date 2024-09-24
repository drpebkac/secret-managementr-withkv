using namespace System.Net

# Input bindings are passed in via param block.
param($Timer)

# Date in UTC for standardised time
$CurrentDate = Get-Date -AsUTC
$ExpiredStatus = "Expired"
$NearExpiryStatus = "Near Expiry"

function PostWebhookNotification($SortedExpiringSecrets)
{
  $RootOrgName = $env:SM_CLIENT_NAME
  $MSTeamsUri = $env:SM_MSTEAMS_WEBHOOK_URI
  $MSTeamsUriSecondary = $env:SM_MSTEAMS_WEBHOOK_URI_SECONDARY

  $MSTeamsWebhookUriArray = @($MSTeamsUri,$MSTeamsUriSecondary)
  
  if($MSTeamsWebhookUriArray)
  {
    foreach($Uri in $MSTeamsWebhookUriArray)
    {
      $Sections = @()

      if([string]::IsNullOrEmpty($Uri))
      {
        continue
      }

      foreach($Entry in $SortedExpiringSecrets)
      {
        $Facts = @()
        
        foreach($Key in $entry.Keys)
        {
          $Fact = @{
            name = $Key
            value = $Entry[$Key]
          }
    
          $Facts += $Fact
    
        }
    
        $Section = @{
          facts = $Facts
        }
          
        $Sections += @($Section)
      }
      
      $MSTeamsBody = @{
        Title = "$RootOrgName - Expiring Secrets for App registrations"
        Text = "This is a MS Teams notification to advise that there are expiring secrets for App Registrations."
        Sections = $Sections
      } | ConvertTo-Json -Depth 20

      $PostToTeams = Invoke-WebRequest -Method POST -body $MSTeamsBody -uri $Uri -ContentType "application/json"

      if($($PostToTeams).Content -like "Webhook message delivery failed with error: Microsoft Teams endpoint returned HTTP error 500 with ContextId*")
      {
        $MSTeamsBody = @{
          Title = "$RootOrgName - Expiring Secrets for App registrations"
          Text = "This customer has exceeded the number of expiring secrets for a Microsoft Teams webhook to handle. Please refer the customer's full csv report for details."
          Sections = ""
        } | ConvertTo-Json -Depth 20

        Invoke-WebRequest -Method POST -body $MSTeamsBody -uri $Uri -ContentType "application/json"
      }
    }
  }
}

function AppendExpiryReport(
  $TenantName,
  $AppId,
  $AppDisplayname,
  $SecretDescription,
  $SecretExpiryDate,
  $Status) {

  $PlaceHolderTable = @()

  $PlaceHolderTable += @{
    TenantName        = $TenantName
    AppId             = $AppId
    AppDisplayname    = $AppDisplayname
    SecretDescription = $SecretDescription
    SecretExpiryDate  = $SecretExpiryDate ? $SecretExpiryDate.ToString("dd MMM yyyy hh:mm:ss") : ""
    Status            = $Status
  }

  return $PlaceHolderTable
}

function Main($CurrentDate, $RootTenantAppExclusions) {
  $SummaryTable = @()
  $ExpirationTable = @()

  if ($RootTenantAppExclusions) {
    Write-Host "Get app registrations, excluding $RootTenantAppExclusions"
    $ArrayOfAppRegistrations = @(Get-AzADApplication | Where-Object { $_.AppId -notin $RootTenantAppExclusions })
  }
  else {
    Write-Host "Get app registrations"
    $ArrayOfAppRegistrations = @(Get-AzADApplication)
  }

  $TenantName = $env:SM_TENANT_NAME

  foreach ($AppReg in $ArrayOfAppRegistrations) {
    $AppRegAppId = $($AppReg).AppId
    $AppRegObjectId = $($AppReg).Id
    $AppRegDisplayName = $($AppReg).DisplayName
    $AppRegCredential = Get-AzADAppCredential -ApplicationId $AppRegAppId

    if ($AppRegCredential) {
      $SummaryTable += @{
        TenantName         = $TenantName
        ApplicationAppId   = $AppRegAppId
        AzureADObjectId    = $AppRegObjectId
        Displayname        = $AppRegDisplayName
        Description        = $($AppRegCredential).DisplayName
        SecretCreationDate = $($AppRegCredential).StartDateTime
        SecretExpiryDate   = $($AppRegCredential).EndDateTime
      }
    }
    else {
      $SummaryTable += @{
        TenantName         = $TenantName
        ApplicationAppId   = $AppRegAppId
        AzureADObjectId    = $AppRegObjectId
        Displayname        = $AppRegDisplayName
        Description        = "NULL"
        SecretCreationDate = "NULL"
        SecretExpiryDate   = "NULL"
      }
    }
  }

  foreach ($App in $SummaryTable) {
    if ($($App.SecretExpiryDate).GetType().toString() -eq 'System.DateTime') {
      Write-Host "App $($App.DisplayName) has single secret"

      $DateToTrigger = $(($App).SecretExpiryDate).AddDays(-$env:SM_NEAR_EXPIRY_DAYS)
      $DateToExpiry = $($App).SecretExpiryDate

      if ($CurrentDate -gt $DateToExpiry) {
        Write-Host "App $($App.DisplayName) secret has expired"

        $ExpirationTable += AppendExpiryReport $App.TenantName $App.ApplicationAppId $App.DisplayName $App.Description $App.SecretExpiryDate $ExpiredStatus
      }
      elseif (($CurrentDate -le $DateToExpiry) -and ($CurrentDate -ge $DateToTrigger)) {

        Write-Host "App $($App.DisplayName) secret is within near expiry period"
        $ExpirationTable += AppendExpiryReport $App.TenantName $App.ApplicationAppId $App.DisplayName $App.Description $App.SecretExpiryDate $NearExpiryStatus
      }
    }

    # App with multiple secrets
    elseif ($($App.SecretExpiryDate).GetType().toString() -eq 'System.Object[]') {
      Write-Host "App $($App.DisplayName) has multiple secrets"

      # Iterator taking into consideration of apps with multiple secrets
      $i = 0
      $MultiSecretAppCount = (($App).SecretExpiryDate).count

      # Individual check operation on a multi secret app registration
      do {
        # Note that the Property is Date instead of SecretExpiryDate. This is sorting the actual date as an object of the $App table
        $DateToTrigger = $(($App).SecretExpiryDate[$i]).AddDays(-$env:SM_NEAR_EXPIRY_DAYS)
        $DateToExpiry = $($App).SecretExpiryDate[$i]

        $RenewedStatus = ""
        # Check if a secret has been renewed
        foreach ($ExpiryDate in $($App).SecretExpiryDate) {
          if ($CurrentDate -le $ExpiryDate.AddDays(-$env:SM_NEAR_EXPIRY_DAYS)) {
            $RenewedStatus = "-Renewed"
            break
          }
          elseif ($CurrentDate -ge $ExpiryDate.AddDays(-$env:SM_NEAR_EXPIRY_DAYS)) {
            break
          }
        }

        # Initial run to report all secrets in the app registration, including expired ones
        if ($CurrentDate -gt $DateToExpiry) {
          Write-Host "App $($App.DisplayName) secret has expired"
          $ExpirationTable += AppendExpiryReport $App.TenantName $App.ApplicationAppId $App.DisplayName $($App).Description[$i] $DateToExpiry "$ExpiredStatus$RenewedStatus"
        }
        elseif (($CurrentDate -le $DateToExpiry) -and ($CurrentDate -ge $DateToTrigger)) {
          Write-Host "App $($App.DisplayName) secret is within near expiry period"

          $ExpirationTable += AppendExpiryReport $App.TenantName $App.ApplicationAppId $App.DisplayName $($App).Description[$i] $DateToExpiry "$NearExpiryStatus$RenewedStatus"
        }

        $i++

      } until($i + 1 -gt $MultiSecretAppCount)
    }
    else {
      Write-Host "App $($App.DisplayName) has no secrets"
    }
  }

  return $ExpirationTable

}

$OutputExpiration = @()

#Value of excluded AppIds, parsed from Function App config
$RootTenantAppExclusions = $env:SM_APP_EXCLUSION_LIST -Split ','


$Output = Main $CurrentDate $RootTenantAppExclusions
$OutputExpiration += $Output

$ExpiryCount = $($OutputExpiration).count
$date = Get-Date -AsUTC -Format %d-MM-yyyy

if ($ExpiryCount -gt 0) {

  $appRegSecretReportFileName = "app-registrations-expiryreport-$($date).csv"
  $SortedExpiringSecrets = $OutputExpiration | Sort-Object -Property DisplayName | Select-Object `
    TenantName, `
    AppId, `
    AppDisplayname, `
    SecretDescription, `
    SecretExpiryDate, `
    Status

  $SortedExpiringSecrets | Export-Csv -NoTypeInformation .\$appRegSecretReportFileName

  $OutputToBlobExpiryReport = Get-Content .\$appRegSecretReportFileName -Raw

  Push-OutputBinding -Name storeExpiryAppRegReport -Value $OutputToBlobExpiryReport

  if ($env:SM_NOTIFY_EMAIL_WITH_GRAPH -eq "True") {
    Write-Host "Sending Email With Report"

    Import-Module EmailModule

    Send-Email `
      -FromAddress $env:SM_NOTIFY_EMAIL_FROM_ADDRESS `
      -ToAddress $env:SM_NOTIFY_EMAIL_TO_ADDRESS `
      -MailSubject $env:SM_APP_REG_REPORT_MAIL_SUBJECT `
      -MailMessage $env:SM_APP_REG_REPORT_MAIL_MESSAGE `
      -Attachments @(
        @{
          "Name" = $appRegSecretReportFileName; "Content" = $OutputToBlobExpiryReport; "ContentType" = "text/csv" 
        }
      )
  }

  if($env:SM_NOTIFY_EMAIL_WITH_SENDGRID -eq "True"){
    Send-PSSendGridMail `
      -FromAddress $env:SM_NOTIFY_EMAIL_FROM_ADDRESS `
      -ToAddress $env:SM_NOTIFY_EMAIL_TO_ADDRESS `
      -Subject $env:SM_KEY_VAULT_REPORT_MAIL_SUBJECT `
      -Body $env:SM_KEY_VAULT_REPORT_MAIL_MESSAGE `
      -AttachmentPath ".\$appRegSecretReportFileName" `
      -Token $env:SM_SENDGRID_TOKEN
  }

  if($env:SM_NOTIFY_MSTEAMS_WEBHOOK -eq "True"){
    PostWebhookNotification $SortedExpiringSecrets
  }

  Remove-Item .\$appRegSecretReportFileName

}
