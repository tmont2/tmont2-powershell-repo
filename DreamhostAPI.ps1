# reference article
# https://help.dreamhost.com/hc/en-us/articles/4407354972692-Connecting-to-the-DreamHost-API
# https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands


function List-DHDnsRecord {    
    $BaseUri = "https://api.dreamhost.com/"
    $ApiKey = "T7V9QQEB894S3TPU"
    $cmd = "dns-list_records"
    $format = "json"

    $uri = "$BaseUri`?key=$ApiKey&cmd=$cmd&format=$Format"
    $response = Invoke-RestMethod -Uri $uri -Method Get
    return $response.data    
}

function Add-DHDnsRecord {
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [ValidateSet("A", "CNAME", "NS", "NAPTR", "SRV", "TXT", "AAAA")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Value,

        [Parameter(Mandatory=$true)]
        [string]$Comment
    )
    
    begin {
        $BaseUri = "https://api.dreamhost.com/"
        $ApiKey = "T7V9QQEB894S3TPU"
        $cmd = "dns-add_record"
        $format = "json"
    }
    
    process {
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&comment=$Comment&format=$format").Replace(" ", "%20")
        $response = Invoke-RestMethod -Uri $uri -Method Get
    }
    
    end {
        # Write-Host $response.data
        return $response.data
    }
}

# acnproteam.com
$result = Add-DHDnsRecord -Domain "autodiscover.acnproteam.com" -Type CNAME -Value "autodiscover.outlook.com" -comment "auto"
$result = Add-DHDnsRecord -Domain "enterpriseenrollment.acnproteam.com" -Type CNAME -Value "enterpriseenrollment-s.manage.microsoft.com" -comment "entenroll"
$result = Add-DHDnsRecord -Domain "enterpriseregistration.acnproteam.com" -Type CNAME -Value "enterpriseregistration.windows.net" -comment "entreg"
$result = Add-DHDnsRecord -Domain "www.acnproteam.com" -Type A -Value "104.175.12.199" -comment "www"

# terrencemontgomery.com
Add-DHDnsRecord -Domain "autodiscover.terrencemontgomery.com" -Type CNAME -Value "autodiscover.outlook.com" -Comment "autodiscover"
Add-DHDnsRecord -Domain "terrencemontgomery.com" -Type TXT -Value "v=spf1 include:spf.protection.outlook.com -all" -Comment "SPF"
Add-DHDnsRecord -Domain "enterpriseenrollment.terrencemontgomery.com" -Type CNAME -Value "enterpriseenrollment-s.manage.microsoft.com" -comment "entenroll"
Add-DHDnsRecord -Domain "enterpriseregistration.terrencemontgomery.com" -Type CNAME -Value "enterpriseregistration.windows.net" -comment "entreg"
Add-DHDnsRecord -Domain "terrencemontgomery.com" -Type A -Value "104.175.12.199" -comment "Default A Record"
Add-DHDnsRecord -Domain "www.terrencemontgomery.com" -Type CNAME -Value "terrencemontgomery.com" -comment "www"


function Remove-DHDnsRecord {
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [ValidateSet("A", "CNAME", "NS", "NAPTR", "SRV", "TXT", "AAAA")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Value
    )
    
    begin {
        $BaseUri = "https://api.dreamhost.com/"
        $ApiKey = "T7V9QQEB894S3TPU"
        $cmd = "dns-remove_record"
        $format = "json"
    }
    
    process {
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&format=$format").Replace(" ", "%20")
        $response = Invoke-RestMethod -Uri $uri -Method Get
    }
    
    end {
        Write-Host $response.data
        return $response.data
    }
}
Remove-DHDnsRecord -Domain terrencemontgomery.com -Type TXT -Value "MS=ms67256965"

# define variables
$BaseUri = "https://api.dreamhost.com/"
$ApiKey = "T7V9QQEB894S3TPU"
$cmd = "dns-list_records"
$Format = "json"

$BaseUri + "?key=" + $ApiKey
"$BaseUri`?key=$ApiKey&cmd=$Command"
$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd&format=$Format"

$response = Invoke-RestMethod -Uri $uri -Method Get

$response.data | ft

# add MX DNS record is NOT allowed
$cmd = "dns-add_record"
$record = "acnproteam.com"
$type = "MX"
$value = "0 acnproteam-com.mail.protection.outlook.com"
$comment = "This is an MX record, duh!"

$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd&record=$record&type=$type&value=$value&comment=$comment&format=$Format"
$uri = $uri.Replace(" ", "%20") # fill in the empty spaces
$response = Invoke-RestMethod -Uri $uri -Method Get
$response

# add TXT record
$cmd = "dns-add_record"
$record = "acnproteam.com"
$type = "TXT"
$value = "v=spf1 ip4:104.175.12.199 include:spf.protection.outlook.com -all"
$comment = "This is an TXT record, duh!"

$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd&record=$record&type=$type&value=$value&comment=$comment&format=$Format"
$uri.Replace(" ", "%20")

# list available API commands
$cmd = "api-list_accessible_cmds"
$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd"
$uri = $uri.Replace(" ", "%20") # fill in the empty spaces
$response = Invoke-RestMethod -Uri $uri -Method Get
$response