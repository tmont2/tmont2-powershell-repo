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

#region ACME-DNS spanishwitty.org
# https://auth.acme-dns.io
$PluginArgs = @{ACMEServer='auth.acme-dns.io'}
New-PACertificate -Domain "spanishwitty.org","www.spanishwitty.org" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
Get-PACertificate spanishwitty.org | Select-Object *
Get-PAOrder spanishwitty.org | Select-Object *
#endregion

#region ACME-DNS spanishwitty.net
$response = Invoke-RestMethod -Method Post -Uri "https://auth.spanishwitty.net/register"
$response

$health = Invoke-WebRequest -Method GET -Uri "https://auth.spanishwitty.net/health"
$health.StatusCode

# Store Credentials 1
$SecurePassword = ConvertTo-SecureString -String $response.password -AsPlainText -Force
$AcmeCredential = New-Object System.Management.Automation.PSCredential($response.username, $SecurePassword)
Set-Secret -Name "ACME-DNS" -Secret $AcmeCredential

$acme_dns = Get-Secret -Name "ACME-DNS"
$Username = $acme_dns.UserName
$Password = $acme_dns.GetNetworkCredential().Password

# Store Credentials 2
$ACME_DNS_HASH = @{
    username = $response.username
    password = $response.password
    fulldomain = $response.fulldomain
    subdomain = $response.subdomain
}

$ACME_DNS_HASH
Set-Secret -Name "ACME-DNS-HASH" -Secret $ACME_DNS_HASH
$PullHash = Get-Secret -Name "ACME-DNS-HASH"
$PullHash.fulldomain | ConvertFrom-SecureString -AsPlainText

# spanishwitty.com
$reg = @{
    '_acme-challenge.spanishwitty.com' = @(
        # the array order of these values is important
        $PullHash.subdomain | ConvertFrom-SecureString -AsPlainText   # subdomain
        $PullHash.username | ConvertFrom-SecureString -AsPlainText    # username
        $PullHash.password | ConvertFrom-SecureString -AsPlainText    # password
        $PullHash.fulldomain | ConvertFrom-SecureString -AsPlainText  # full domain
    )
}
$PluginArgs = @{ACMEServer='auth.spanishwitty.net'; ACMERegistration = $reg}
New-PACertificate -Domain "spanishwitty.com" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
# New-PACertificate -Domain "spanishwitty.com","www.spanishwitty.com" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
Get-PACertificate spanishwitty.com | Select-Object *
Get-PAOrder spanishwitty.com | Select-Object *

# terrencemontgomery.com
$reg = @{
    '_acme-challenge.terrencemontgomery.com' = @(
        # the array order of these values is important
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.subdomain  # subdomain
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.username   # username
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.password   # password
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.fulldomain # full domain
    )
}
$PluginArgs = @{ACMEServer='auth.spanishwitty.net'; ACMERegistration = $reg}
New-PACertificate -Domain "terrencemontgomery.com" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
Get-PACertificate terrencemontgomery.com | Select-Object *
Get-PAOrder terrencemontgomery.com | Select-Object *

# acnproteam.com
$reg = @{
    '_acme-challenge.acnproteam.com' = @(
        # the array order of these values is important
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.subdomain  # subdomain
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.username   # username
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.password   # password
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.fulldomain # full domain
    )
    '_acme-challenge.www.acnproteam.com' = @(
        # the array order of these values is important
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.subdomain  # subdomain
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.username   # username
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.password   # password
        ConvertFrom-SecureString -AsPlainText -SecureString $PullHash.fulldomain # full domain
    )
}
$PluginArgs = @{ACMEServer='auth.spanishwitty.net'; ACMERegistration = $reg}
New-PACertificate -Domain "acnproteam.com", "www.acnproteam.com" -AcceptTOS -Plugin AcmeDns -PluginArgs $PluginArgs
Get-PACertificate acnproteam.com | Select-Object *
Get-PAOrder acnproteam.com | Select-Object *

Get-PACertificate -List | Select-Object Subject, NotBefore, Thumbprint, AllSANs

#endregion

Test-Connection -TargetName "165.1.64.214" -TcpPort 22
Test-Connection -TargetName "165.1.64.214" -TcpPort 53
Test-Connection -TargetName "165.1.64.214" -TcpPort 80
Test-Connection -TargetName "165.1.64.214" -TcpPort 443

