# Source: https://getpractical.co.uk/2023/06/30/sending-emails-using-microsoft-graph-api-and-powershell-an-advanced-guide/


# Parameters
Param (
$appId = "",
$tenantId = "",
$appSecret = "",
$graphUrl = "https://login.microsoftonline.com/$($tenantId).onmicrosoft.com/oauth2/v2.0/token")



# Authentication
$ body = @{
   client_id = $appId
   client_secret = $appSecret
   scope = $Scope
   grant_type = 'client_credentials'
}
$authorizationRequest = Invoke-RestMethod -Uri $graphUrl -Method "Post" -Body $body
$access_token = $authorizationRequest.access_tokeb

$header = @{
   Authorization = "Bearer" + $authorizationRequest.access_token
}

# Connect to Microsoft Graph
Connect-MgGraph -AccessToken $access_token

# Email details
$msgFrom = "brian@wipe.dk"
$ccRecipient1 = "brianjor@gmail.com"
$ccRecipient2 = "bjo@nhc.dk"
$emailRecipient = "brianjor@protonmail.com"
# Write-Host "Your Error Message" <- hvorfor denne linje?

$msgSubject = "Du har fået ny post"
$htmlHeaderUser = "<h2>Header på email i H2 format</h2>"
$htmlLine1 = "<p>First paragraph of your email body</p>"
$htmlLine2 = "<p>Second paragraph of the email body</p>"
$htmlBody = $htmlHeaderUser + $htmlLine1 + $htmlLine2
$htmlMsg = "<html><body>" + $htmlBody + "</body></html>"

# Get the user id for the sender
$userFrom = Get-MgUser -Filter "mail eq '$msgFrom'"
$userIdFrom = $userFrom.Id

# Create message body and properties and send
$messageParams = @{
   "URI" = "https://graph.microsoft.com/v1.0/users/$userIdFrom/sendMail"
   "Headers" = $header
   "Method" = "POST"
   "ContentType" = 'application/json'
   "Body" = (@{
      "message" = @{
         "subject" = $msgSubject
         "body" = @{
            "contentType" = 'HTML'
            "content" = $htmlMsg }
         "toRecipients" = @(
            @{
              "emailAddress" = @{"address" = $emailRecipient}
     })
   "ccRecipients" = @(
      @{
         "emailAddress" = @{"address" = $ccRecipient1 }
      },
      @{
         "emailAddress" = @{"address" = $ccRecipient2 }
      })
   }
   }) | ConvertTo-JSON -Depth 6
}

# Send the message
Invoke-RestMethod @MessageParams
