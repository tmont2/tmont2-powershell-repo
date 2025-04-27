# reference article: https://davidjust.com/post/export-all-bitlocker-keys-from-entraid/

# Install the Microsoft.Graph module if not already installed
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber

# Import the Microsoft.Graph module
Import-Module Microsoft.Graph

# Define Scopes for Microsoft Graph
$Scopes =@(
    "User.ReadWrite.All"
    "Group.ReadWrite.All"
    "Device.Read.All"
    "Directory.Read.All"
    "BitlockerKey.Read.All"
    "DeviceManagementManagedDevices.Read.All" 
)
# Connect to Microsoft Graph
Connect-MgGraph -Scopes $Scopes -UseDeviceCode

# query for all devices that are joined to Entra
$devices = Get-MgDevice -Filter "TrustType eq 'AzureAd'" -Property DisplayName, DeviceId, OperatingSystem, TrustType, Model, Manufacturer
$devices | Select-Object DisplayName, DeviceId, OperatingSystem, TrustType, Model, Manufacturer
$devices | Where-Object {$_.TrustType -eq "AzureAd"} | Select-Object DisplayName, DeviceId, OperatingSystem, TrustType
$devices.Count

# query for all BitLocker key
$blkeys = Get-MgInformationProtectionBitlockerRecoveryKey
$blkeys.Count

$DeviceList = foreach($device in $devices) {
    $recoveryKeys = $blkeys | Where-Object {$_.DeviceId -eq $device.DeviceId} |
        ForEach-Object {
            $Key = Get-MgInformationProtectionBitlockerRecoveryKey -BitlockerRecoveryKeyId $_.id -Property "key"
            [ordered]@{BitLockerKey = $Key.key; BitLockerKeyID = $Key.id; CreatedDateTime = $Key.CreatedDateTime}
        }
    
    
    [PSCustomObject]@{
        DeviceName = $device.DisplayName
        DeviceID = $device.DeviceId
        # Model = $device.Model
        # Manufacturer = $device.Manufacturer
        BitLockerKey = $recoveryKeys | ConvertTo-Json -Compress
    }
}

$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = "$desktopPath\BitlockerKeys.xlsx"
$DeviceList | Sort-Object DeviceName | Export-Excel -Path $SavePath -TableName BitlockerKeys -Autosize

# Disconnect from Microsoft Graph
Disconnect-MgGraph
