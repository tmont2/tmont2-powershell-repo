Install-Module -Name Posh-ACME -Repository PSGallery -Force
Get-InstalledModule -Name Posh-ACME | Select-Object Name, Version, InstalledLocation
Import-Module -Name Posh-ACME

Set-PAServer LE_PROD
Set-PAServer LE_STAGE # staging or production

#region Dreamhost API

$PluginArgs = @{DreamhostApiKeySecure = ConvertTo-SecureString -String $env:DREAMHOST_API_KEY -AsPlainText -Force }
New-PACertificate -Domain "macbuntu.spanishwitty.org" -AcceptTOS -Plugin Dreamhost -PluginArgs $PluginArgs
# the above command also takes a PFX password, instead of using the default "poshacme"
Get-PACertificate | Select-Object *
Get-PAOrder macbuntu.spanishwitty.org | Select-Object *

# can we get a cert for the root domain, and its not a wildcard?
New-PACertificate -Domain "spanishwitty.org" -AcceptTOS -Plugin Dreamhost -PluginArgs $PluginArgs

Get-PACertificate macbuntu.spanishwitty.org | Select-Object *

#endregion

#region ACME-DNS
# https://auth.acme-dns.io
$PluginArgs = @{ACMEServer='auth.acme-dns.io'}
New-PACertificate -Domain "spanishwitty.org","www.spanishwitty.org" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
Get-PACertificate spanishwitty.org | Select-Object *
Get-PAOrder spanishwitty.org | Select-Object *

#endregion