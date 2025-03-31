#region Change Password and Sign this user out of all Microsoft 365 sessions.
# script to reset Entra ID user passwords uses a CSV file with columns UPN and NewPassword
$Scopes = "User.ReadWrite.All"
Connect-MgGraph -Scopes $Scopes -UseDeviceCode
$ReportList = [System.Collections.Generic.List[Object]]::New()
$CsvImportPath = "/home/terrence/Desktop/VSCode/ResetPassword.csv"
$CsvExportPath = "/home/terrence/Desktop/VSCode/ResetPasswordResult.csv"

$UserList = Import-CSV $CsvImportPath
foreach($User in $UserList) { 
    $PwResetStatus, $UserSignOutStatus = "Success", "Success"

    $PasswordProfile = @{  
        ForceChangePasswordNextSignIn = $false 
        Password = $User.NewPassword 
    } 
    # use a try/catch to reset the password
    try { 
        Update-MgUser -UserId $User.UPN -PasswordProfile $PasswordProfile -ErrorAction Stop 
        Write-Host -ForegroundColor Green "Password updated for $($User.UPN)" 
    } 
    catch { 
        $errorMessage = $_.Exception.Message 
        Write-Host -ForegroundColor Red "Failed to update the password for $($User.UPN): $($errorMessage)"
        $PwResetStatus = "Fail"
    } 
    # use a try/catch to sign out all user sessions
    try {
        $SignOutResult = Revoke-MgUserSignInSession -UserId $User.UPN -ErrorAction Stop
        if ($SignOutResult.Value -eq $true) {
            Write-Host -ForegroundColor Green "Sign out succeeded for $($User.UPN)" 
        } else {
            Write-Host -ForegroundColor Red "Sign out failed for $($User.UPN)"
            $UserSignOutStatus = "Fail"
        }     
    }
    catch {
        Write-Host -ForegroundColor Red "Sign out failed for $($User.UPN)"
        $UserSignOutStatus = "Fail"
    }
    $ReportLine = [PSCustomObject]@{
        UserName = $User.UPN
        PasswordReset = $PwResetStatus
        UserSignedOut = $UserSignOutStatus
    }
    $ReportList.Add($ReportLine)
} 
$ReportList | Sort-Object -Property Username | Format-Table
$ReportList | Sort-Object -Property Username | Export-Csv -Path $CsvExportPath -Encoding utf8 -NoTypeInformation

#endregion