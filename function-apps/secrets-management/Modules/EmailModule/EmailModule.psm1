<#
  .SYNOPSIS
    Script used to build and copy bicep modules from a container registry to another registry in a different tenant. The script uses AD Authentication to access
    the source and target registry.

  .DESCRIPTION
    This script does the following:
    - Creates the container registry in the Client tenant.
    - Logs into the source registry tenant (i.e Arinco Tenant) and scans the registry for repositories and images
    - Logs into the target registry tenant (i.e Client Tenant) and imports the images

  .PARAMETER FromAddress
  Mandatory. The email address to use as the from address.

  .PARAMETER ToAddress
  Mandatory. The email address to use as the to address.

  .PARAMETER MailSubject
  Mandatory. The subject of the email.

  .PARAMETER MailMessage
  Mandatory. The message of the email.

  .PARAMETER Attachments
  Mandatory. The attachments to include in the email. Must be a collection of hash tables with the following properties.
    - Name
    - Content
    - ContentType



  .EXAMPLE
    Send-Email -FromAddress person@company.com -ToAddress blah@hotmail.com -MailSubject "Test" -MailMessage "Test" -Attachments @( @{"Name"="test.txt";"Content" = "abcdfefg"; "ContentType"="text/plain"} )

#>
function Send-Email {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $FromAddress,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ToAddress,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $MailSubject,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $MailMessage,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [object[]] $Attachments
  )

  $graphRequestAttachments = $Attachments | ForEach-Object {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($_.Content)
    $contentEncoded = [System.Convert]::ToBase64String($bytes)

    @{
      "@odata.type"  = "#microsoft.graph.fileAttachment"
      "name"         = $_.Name
      "contentType"  = $_.ContentType
      "contentBytes" = $contentEncoded
    }
  }

  $toAddresses = $ToAddress.Split(',') | ForEach-Object {
    @{
      "emailAddress" = @{
        "address" = $_
      }
    }
  }

  $tokenResponse = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
  $token = $tokenResponse.Token

  $params = @{
    "URI"         = "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail"
    "Headers"     = @{
      "Authorization" = ("Bearer {0}" -F $token)
    }
    "Method"      = "POST"
    "ContentType" = 'application/json'
    "Body"        = (@{
        "message"         = @{
          "importance"   = "high"
          "subject"      = $MailSubject
          "body"         = @{
            "contentType" = 'HTML'
            "content"     = $MailMessage
          }
          "toRecipients" = @(
            $toAddresses
          )
          "attachments"  = @(
            $graphRequestAttachments
          )
        }
        "saveToSentItems" = "false"
      }) | ConvertTo-JSON -Depth 100
  }

  Invoke-RestMethod @params -Verbose
}

Export-ModuleMember -Function Send-Email