<#
    SYNOPSIS: This script reports on InboxUnreadCount, InboxTotalCount and DeletedItemsTotalCount
    Mailbox Custom Attribute 15
        Administration : MailboxAudit-Admin
        Operations     : MailboxAudit-Ops
        Sales          : MailboxAudit-Sales
    Prerequisites PowerShell Modules:
        ExchangeOnlineManagement
        Microsoft.Graph.Authentication
        ImportExcel
    Microsoft 365 App Registration require the following Application Permissions  
        Scopes to send email: Mail.Send, Mail.ReadWrite
        Scopes to read mailboxes:
#>

Clear-Host
#region Define Microsoft 365 Entra Id App Registration variables
$TenantId = "631b69df-b732-4902-b4c3-ee6a4428ceae"
$AppId = "a2d27c5b-29d6-44d3-b056-32b4b9b1b717"
$CertificateThumbprint = "542774661ECE73CABE683DC7DC9533A98312C58C"
$Organization = "greenboxloans.onmicrosoft.com"
$CertificateFilePath = "/home/terrence/Downloads/ExoAutomateCert.pfx"
$certPassword = (Import-Clixml -Path /home/terrence/Desktop/VSCode/GBL-Creds.xml).Password # return the password, which is a SecureString object
# $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificateFilePath, $certPassword)
$certificate = Get-PfxCertificate -FilePath $CertificateFilePath -Password $certPassword
#endregion

#region Define Excel filename with timestamp appended
$TimeStamp = $(Get-Date -Format "yyyyMMddHHmmss")
$FileExcel = "c:\temp\MailboxAudit-$TimeStamp.xlsx"         # Admin, Ops, Sales all in one file on 3 different sheets
# $SpFolder = "IT/Mailbox Audit Reports"
# $SpFolder = "Attachments"
# $SpDocLibId = "b!HRsVwF8-k0e6SxEU6A55jOFRKp8T4fRBlGiUBGKwkay6qolE4RHBTZcCE7llRmk6" # Sharepoint doc library ID for team site
# $SpDocLibId = "b!SsalYmK3SUSTPzAW--fdaBHaxU2pQ0BBnVIA8LI1MXKqUZ0rtAhIR73s1k_bVu_x" # OneDrive ID for Nerds
#endregion

#region Define variables for sending email
$MsgFrom = "nerds@greenboxloans.com"
$MsgSubject = "Mailbox Audit for $(Get-Date -Format 'MMMM d, yyyy')"
$RecipientDisplayName = "IT Dept"
$RecipientAddress = "nerds@greenboxloans.com"
#endregion

#region Confirm certificate exists and is not expired
$CertificateExists = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $CertificateThumbprint}
if (-not $CertificateExists) {
    Write-Host "Please install certificate and restart the script"
    Exit 1
}

if ((Get-Date) -gt $CertificateExists.NotAfter) {
    Write-Host "This certificate is expired, please generate a new one and upload the to App Registration"
    Exit 1
}
#endregion

#region CONFIRM REQUIRED MODULES ARE LOADED
$ModulesLoaded = Get-InstalledModule | Select-Object -ExpandProperty Name 

# Exchange Module
if  ("ExchangeOnlineManagement" -notin $ModulesLoaded) {
    Write-Error "Please install Exchange Online Management module and then restart the script"
    Exit 1
}

# Graph Module
if  ("Microsoft.Graph.Authentication" -notin $ModulesLoaded) {
    Write-Error "Please install MS Graph Authentication module and then restart the script"
    Exit 1
}

# Excel Module
If ("ImportExcel" -notin $ModulesLoaded) {
    Write-Error "Please install ImportExcel module and then restart the script"
    Exit 1
}
#endregion

#region Connect to ExchangeOnline and MS Graph
try {
    Connect-ExchangeOnline -AppId $AppId -Certificate $certificate -Organization $Organization -ShowBanner:$false

} catch {
    Write-Error "Connection to Exchange Online failed...exiting script."
    Exit 1
}

try {
    Connect-MgGraph -ClientId $AppId -TenantId $TenantId -Certificate $certificate  -NoWelcome    

} catch {
    Write-Error "Connection to Microsoft Graph failed...exiting script."
    Exit 1
}
#endregion

#region Query MS Graph and pull data
Write-Host "Finding user mailboxes..."
[array]$Mbx = Get-ExoMailbox -ResultSize Unlimited -Filter "CustomAttribute15 -like 'MailboxAudit*'" -Properties CustomAttribute15 | Sort-Object DisplayName
If (!($Mbx)) { Write-Host "No mailboxes found... exiting!" ; break }
Write-Host -Object ("Found {0} mailboxes" -f $Mbx.Count)
$Report = [System.Collections.Generic.List[Object]]::new()
$i = 1
ForEach ($M in $Mbx) {
    # Write-Host ("Processing mailbox {0} of {1}: {2}" -f $i, $Mbx.Count, $M.DisplayName); $i++
    $Uri = "https://graph.microsoft.com/v1.0/users/" + $M.ExternalDirectoryObjectId + "/mailFolders?`$top=250"
    # $FolderData = Invoke-RestMethod -Headers $Headers -Uri $Uri -UseBasicParsing -Method "GET" -ContentType "application/json"
    $FolderData = Invoke-MgGraphRequest -Method GET -Uri $Uri
    $InboxData = $FolderData.Value | Where-Object {$_.displayname -eq "Inbox"}
    $DelItemsData = $FolderData.Value | Where-Object {$_.displayname -eq "Deleted Items"}    
    # $TotalMbxItems = ($FolderData.Value.totalitemcount | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
    # $TotalMbxSize = ($FolderData.Value.SizeInBytes | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
    $ReportLine = [PSCustomObject][Ordered]@{  # Write out details of the mailbox
        DisplayName            = $M.DisplayName
        EmailAddress           = $M.UserPrincipalName
        InboxUnreadCount       = $InboxData.unreadItemCount
        InboxTotalCount        = $InboxData.totalItemCount
        DeletedItemsTotalCount = $DelItemsData.totalItemCount
        CustomAttribute15      = ($M.CustomAttribute15).Trim()
        # TotalMbxFolders     = $FolderData.Value.Count
        # TotalMbxItems       = $TotalMbxItems
        # TotalMbxFolderSize  = [math]::Round($TotalMbxsize/1Mb,2)  
    }
    $Report.Add($ReportLine) 
}
#endregion

#region Output data to Excel file

# uncomment the next line for debug
$Report | Select-Object DisplayName, @{l='Team';e={$_.CustomAttribute15.Replace("MailboxAudit-", "")}}, InboxUnreadCount, InboxTotalCount, DeletedItemsTotalCount | Sort-Object DisplayName | Format-Table

$DateStamp = $TimeStamp.Substring(0,8) # take the first 8 characters of the timestamp

# Admin
$WorkSheetName = "Administration $DateStamp"
$Report | Where-Object {$_.CustomAttribute15 -eq "MailboxAudit-Admin" } | Sort-Object DisplayName |
    Select-Object DisplayName, EmailAddress, InboxUnreadCount, InboxTotalCount, DeletedItemsTotalCount |
    Export-Excel -Path $FileExcel -TableName "Admin" -WorkSheetName $WorkSheetName -TableStyle Medium7 -FreezeTopRow -AutoSize
    
# Ops
$WorkSheetName = "Operations $DateStamp"
$Report | Where-Object {$_.CustomAttribute15 -eq "MailboxAudit-Ops" } | Sort-Object DisplayName |
    Select-Object DisplayName, EmailAddress, InboxUnreadCount, InboxTotalCount, DeletedItemsTotalCount |  
    Export-Excel -Path $FileExcel -TableName "Ops" -WorkSheetName $WorkSheetName -TableStyle Medium7 -FreezeTopRow -AutoSize
    
# Sales
$WorkSheetName = "Sales $DateStamp"
$Report | Where-Object {$_.CustomAttribute15 -eq "MailboxAudit-Sales" } | Sort-Object DisplayName |
    Select-Object DisplayName, EmailAddress, InboxUnreadCount, InboxTotalCount, DeletedItemsTotalCount |  
    Export-Excel -Path $FileExcel -TableName "Sales" -WorkSheetName $WorkSheetName -TableStyle Medium7 -FreezeTopRow -AutoSize        
    
Write-Host ("Excel worksheet available in {0}" -f $FileExcel)
#endregion

#region Upload Excel file to SharePoint
$SpFileName = Split-Path -Path $FileExcel -Leaf
$Uri = "https://graph.microsoft.com/v1.0/drives/$SpDocLibId/items/root:/$SpFolder/$($SpFileName):/content"
# $GraphResult = Invoke-MgGraphRequest -Uri $Uri -Method Put -InputFile $FileExcel -ContentType 'multipart/form-data' -Verbose
#endregion

#region Email Excel report to itdept@greenboxloans.com
# Construct HTML template
$HtmlMsg = @"
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Mailbox Audit Report!</title>
<style>color:darkred</style>
</head>
<body>
<p>Hello $RecipientDisplayName,</p>
<p>Please see the attached file. You will find three sheets, each with one department. </p>
<p>Thank you! </p>
<p><b>IT Accuracy Support<br/>
<a href="mailto:support@itaccuracy.com">support@itaccuracy.com</a><br/>
310.870.1713</b></p>
</body>
</html>
"@

# Construct the email parameters
$BodyParameter = @{
    message = @{
		subject = $MsgSubject
		body = @{
			contentType = "html"
			content = "$($HtmlMsg)"
		}
		toRecipients = @(
			@{
				emailAddress = @{
					address = $RecipientAddress
				}
			}
		)		
        attachments = @(
			@{
				"@odata.type" = "#microsoft.graph.fileAttachment"
				name = ($FileExcel -split '\\')[-1]
				contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                # contentBytes = [convert]::ToBase64String((Get-Content -Path $FileExcel -Encoding byte)) # PowerShell 5
				contentBytes = [convert]::ToBase64String((Get-Content -Path $FileExcel -AsByteStream -Raw)) # PowerShell 7
			}
		)
	}
	saveToSentItems = "false"
}

# Send the email
Write-Host "Sending report to $RecipientAddress"
try {
    Send-MgUserMail -UserId $MsgFrom -BodyParameter $BodyParameter
} catch {
    Write-Error "Failed to send report via email, please logon to GBL-DC-01 and download the report."
}
#endregion

#region Clean Up 
# Disconnect from Exchange and MS Graph
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph | Out-Null

# delete all Excel reports that are more than 30 days old
Get-ChildItem -Path "C:\Temp" -Filter "MailboxAudit*.xlsx" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30)  } | Remove-Item -Force -ErrorAction SilentlyContinue
#endregion