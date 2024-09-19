using namespace System.Net

# Input bindings are passed in via param block.
param($Timer)

function Initialize-KVError($KVName, $SubscriptionName, $RG, $ErrorOutputAsString, $AssetType) {
  $ErrorDetails = [PSCustomObject]@{
    Subscription  = $SubscriptionName
    ResourceGroup = $RG
    KVName        = $KVName
    AssetType     = $AssetType
    ErrorMessage  = $ErrorOutputAsString -join ','
  }
  return $ErrorDetails
}

function Test-KeyVaultSecretAccess($KVName, $AssetType) {
  switch ($AssetType) {
    "Secret" {
      Get-AzKeyVaultSecret -VaultName $KVName -ErrorVariable KVErrors

    }
    "Cert" {
      Get-AzKeyVaultCertificate -VaultName $KVName -ErrorVariable KVErrors
    }
    Default {
      throw "$AssetType is unknown."
    }
  }

  if ($KVErrors.Count -gt 0) {
    $ex = $KVErrors[0].Exception
    if ($ex.InnerException) {
      $message = $ex.InnerException.Message
    }
    else {
      $message = $ex.Message
    }
    return ($false, $message)
  }
  return ($true, "")
}

function Get-Expiry-Secret($KVName, $SubscriptionName, $RG) {
  #Temporary Placeholder for return output
  $OutputTable = @()

  #Certificates for some reasons show up in secrets as PEM and PKCS12. This array is used to exclude them in the secrets report. They will appear separately in the certificates report
  $NotSecretsTypes = @('application/x-pem-file', 'application/x-pkcs12')

  #Get Expiry secret
  $SecretExpiryArray = @(Get-AzKeyVaultSecret -VaultName $KVName | Select-Object Name, Created, Expires, Enabled, ContentType, Tags)
  $CurrentDate = Get-Date -AsUTC

  foreach ($Secret in $SecretExpiryArray) {
    if ($Secret.ContentType -notin $NotSecretsTypes) {
      $DateToExpiry = $($Secret).Expires
      [bool]$addToReport = $false
      if ($DateToExpiry) {
        $DateToTrigger = $DateToExpiry.AddDays(-$env:SM_NEAR_EXPIRY_DAYS)
        if (($CurrentDate -gt $DateToExpiry) -or ((($CurrentDate -le $DateToExpiry) -and ($CurrentDate -ge $DateToTrigger)))) {
          $addToReport = $true
        }
      }
      else {
        # Always add secrets with no expiry to report
        $addToReport = $true
      }

      if ($addToReport -eq $true) {
        $Tags = $($Secret).Tags ?? @()
        $TagsStr = $Tags.GetEnumerator().ForEach({ "$($_.Key) = $($_.Value)" }) -join ';'

        $KVSummary = New-Object psobject -Property @{
          Subscription  = $SubscriptionName
          KVName        = $KVName
          resourceGroup = $RG
          SecretName    = $($Secret).Name
          Created       = $($Secret).Created
          Expires       = $($Secret).Expires ?? '(No-Expiry)'
          Enabled       = $($Secret).Enabled
          ContentType   = $($Secret).ContentType
          Tags          = $TagsStr
        }

        $OutputTable += $KVSummary | Select-Object Subscription, resourceGroup, KVName, SecretName, Created, Updated, Expires, Enabled, ContentType, Tags
      }

    }
  }

  return $OutputTable
}

function Get-Expiry-Cert($KVName, $SubscriptionName, $RG) {
  #Temporary Placeholder for return output
  $OutputTable = @()

  #Get expiry cert
  $CertExpiryArray = @(Get-AzKeyVaultCertificate -VaultName $KVName | Select-Object Name, Created, Expires, Enabled, Tags)
  $CurrentDate = Get-Date -AsUTC

  foreach ($Cert in $CertExpiryArray) {
    $DateToExpiry = $($Cert).Expires
    [bool]$addToReport = $false

    if ($DateToExpiry) {
      $DateToTrigger = $DateToExpiry.AddDays(-$env:SM_NEAR_EXPIRY_DAYS)
      if (($CurrentDate -gt $DateToExpiry) -or ((($CurrentDate -le $DateToExpiry) -and ($CurrentDate -ge $DateToTrigger)))) {
        $addToReport = $true
      }
    }
    else {
      # Always add certs with no expiry to report
      $addToReport = $true
    }

    if ($addToReport -eq $true) {
      $Tags = $($Cert).Tags ?? @()
      $TagsStr = $Tags.GetEnumerator().ForEach({ "$($_.Key) = $($_.Value)" }) -join ';'

      $KVSummary = New-Object psobject -Property @{
        Subscription  = $SubscriptionName
        KVName        = $KVName
        resourceGroup = $RG
        CertName      = $($Cert).Name
        Created       = $($Cert).Created
        Expires       = $($Cert).Expires ?? '(No-Expiry)'
        Enabled       = $($Cert).Enabled
        ContentType   = $($Cert).ContentType
        Tags          = $TagsStr
      }

      $OutputTable += $KVSummary | Select-Object Subscription, resourceGroup, KVName, CertName, Created, Updated, Expires, Enabled, ContentType, Tags
    }
  }
  return $OutputTable
}

Write-Host "Getting Subscriptions"
#A tenant can have multiple subscriptions. Start here as the entry point
$Subs = @(Get-AZSubscription -WarningAction Ignore -InformationAction SilentlyContinue -TenantId $env:SM_TENANT_ID | Where-Object { $_.TenantID -eq $env:SM_TENANT_ID })

$OutputTableSecrets = @()
$OutputTableCerts = @()
$OutputTableErrors = @()

foreach ($Sub in $Subs) {

  #Narrow down subscription details to just name
  Set-AzContext -Subscription $Sub.Id -WarningAction:SilentlyContinue  | Out-Null

  $SubscriptionName = $($Sub.Name)

  Write-Host "Getting KeyVaults for Subscription $SubscriptionName"

  $KVNames = @((Get-AzKeyVault).VaultName)

  if ($KVNames) {
    foreach ($KVName in $KVNames) {
      Write-Host "Analysing KeyVault $KVName"

      #A subscription can have multiple resource groups. Check the RG associated with the iterated KV
      $RG = (Get-AzKeyVault -Name $KVName).ResourceGroupName

      # Ensure a valid RG is returned for the given vault to avoid errors
      if ($RG) {

        $AccessTestResult = Test-KeyVaultSecretAccess $KVName "Secret"
        if ($AccessTestResult[0] -eq $false) {
          $OutputTableErrors += Initialize-KVError $KVName $SubscriptionName $RG $AccessTestResult[1] "Secret"
        }
        else {
          $OutputTableSecrets += Get-Expiry-Secret $KVName $SubscriptionName $RG
        }

        $AccessTestResult = Test-KeyVaultSecretAccess $KVName "Cert"
        if ($AccessTestResult[0] -eq $false) {
          $OutputTableErrors += Initialize-KVError $KVName $SubscriptionName $RG $AccessTestResult[1] "Cert"
        }
        else {
          $OutputTableSecrets += Get-Expiry-Cert $KVName $SubscriptionName $RG
        }
      }
    }
  }
}

$attachments = @()
$date = Get-Date -AsUTC -Format %d-MM-yyyy
$keyVaultSecretReportFileName = "keyvault-secret-expiryreport-$($date).csv"
$SecretExpiryCount = $($OutputTableSecrets).count
Write-Host "$SecretExpiryCount Secrets expired or nearing expiry"

if ($SecretExpiryCount -gt 0) {

  $OutputTableSecrets | Export-CSV -NoTypeInformation .\$keyVaultSecretReportFileName
  $OutputToBlobSecretsExpiryReport = Get-Content .\$keyVaultSecretReportFileName -Raw
  Push-OutputBinding -Name storeSecretExpiryReport -Value $OutputToBlobSecretsExpiryReport

  $attachments += @{"Name" = $keyVaultSecretReportFileName; "Content" = $OutputToBlobSecretsExpiryReport; "ContentType" = "text/csv" }
}

$keyVaultCertReportFileName = "keyvault-secret-expiryreport-$($date).csv"
$CertExpiryCount = $($OutputTableCerts).count
Write-Host "$CertExpiryCount Certs expired or nearing expiry"

if ($CertExpiryCount -gt 0) {

  $OutputTableCerts | Export-CSV -NoTypeInformation .\$keyVaultCertReportFileName

  $OutputToBlobCertsExpiryReport = Get-Content .\$keyVaultCertReportFileName -Raw
  Push-OutputBinding -Name storeCertExpiryReport -Value $OutputToBlobCertsExpiryReport

  $attachments += @{"Name" = $keyVaultCertReportFileName; "Content" = $OutputToBlobCertsExpiryReport; "ContentType" = "text/csv" }
}

$keyVaultErrorLogFileName = "keyvault-errorlog-$($date).csv"
$ErrorCount = $($OutputTableErrors).count

if ($ErrorCount -gt 0) {

  Write-Host "Errors found in this execution."

  $OutputTableErrors | Export-CSV -NoTypeInformation .\$keyVaultErrorLogFileName

  $OutputToBlobErrorLogs = Get-Content .\$keyVaultErrorLogFileName -Raw
  Push-OutputBinding -Name kvErrorLogs -Value $OutputToBlobErrorLogs

  $attachments += @{"Name" = $keyVaultErrorLogFileName; "Content" = $OutputToBlobErrorLogs; "ContentType" = "text/csv" }
}

if (($env:SM_NOTIFY_EMAIL_ENABLED -eq "Enabled") -and (($SecretExpiryCount -gt 0 -or $CertExpiryCount -gt 0) -or $ErrorCount -gt 0)) {
  Import-Module EmailModule

  Send-Email `
    -FromAddress $env:SM_NOTIFY_EMAIL_FROM_ADDRESS `
    -ToAddress $env:SM_NOTIFY_EMAIL_TO_ADDRESS `
    -MailSubject $env:SM_KEY_VAULT_REPORT_MAIL_SUBJECT `
    -MailMessage $env:SM_KEY_VAULT_REPORT_MAIL_MESSAGE `
    -Attachments $attachments
}

if ($SecretExpiryCount -gt 0) {
  Remove-Item .\$keyVaultSecretReportFileName
}
if ($CertExpiryCount -gt 0) {
  Remove-Item .\$keyVaultCertReportFileName
}
if ($ErrorCount -gt 0) {
  Remove-Item .\$keyVaultErrorLogFileName
}