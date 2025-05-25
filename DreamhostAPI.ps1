# reference article
# https://help.dreamhost.com/hc/en-us/articles/4407354972692-Connecting-to-the-DreamHost-API
# https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands
# https://panel.dreamhost.com/?tree=home.api

function List-DHDnsRecord {    
    $BaseUri = "https://api.dreamhost.com/"
    $ApiKey = $env:DREAMHOST_API_KEY
    $cmd = "dns-list_records"
    $format = "json"

    $uri = "$BaseUri`?key=$ApiKey&cmd=$cmd&format=$Format"
    $response = Invoke-RestMethod -Uri $uri -Method Get
    return ($response.data | Select-Object zone, type, record, value, comment, editable)  
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

        [Parameter(Mandatory=$false)]
        [string]$Comment=""
    )
    
    begin {
        $BaseUri = "https://api.dreamhost.com/"
        $ApiKey = $env:DREAMHOST_API_KEY
        $cmd = "dns-add_record"
        $format = "json"
    }
    
    process {
        # prepare URI and encode it to replace spaces with %20 and semicolons with %3B, etc
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&comment=$Comment&format=$format").Replace(" ", "%20").Replace(";", "%3B")
        $response = Invoke-RestMethod -Uri $uri -Method Get
    }
    
    end {
        return $response.data
    }
}


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
        $ApiKey = $env:DREAMHOST_API_KEY
        $cmd = "dns-remove_record"
        $format = "json"
    }
    
    process {
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&format=$format").Replace(" ", "%20").Replace(";", "%3B")
        $response = Invoke-RestMethod -Uri $uri -Method Get
    }
    
    end {
        # Write-Host $response.data
        return $response.data
    }
}


function Add-DHDnsRecordTest {
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [ValidateSet("A", "CNAME", "NS", "NAPTR", "SRV", "TXT", "AAAA")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Value,

        [Parameter(Mandatory=$false)]
        [string]$Comment=""
    )
    
    begin {
        $BaseUri = "https://api.dreamhost.com/"
        $ApiKey = $env:DREAMHOST_API_KEY
        $cmd = "dns-add_record"
        $format = "json"
    }
    
    process {
        # prepare URI and replace spaces with %20 and semicolons with %3B
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&comment=$Comment&format=$format")
        $encodedDataString = [System.Uri]::EscapeDataString($uri)
        $encodedUri = [System.Uri]::EscapeUriString($uri)
    }
    
    end {
        $result = [ordered]@{
            OriginalURI = $uri
            EscapeDataString = $encodedDataString
            EscapeUriString = $encodedUri
        }
        return $result
    }
}

Add-DHDnsRecordTest -Domain "spanishwitty.com" -Type TXT -Value "MS=ms80528128" -Comment "M365 Ownership Verification"
Add-DHDnsRecordTest -Domain "_dmarc3.spanishwitty.com" -Type TXT -Value "v=DMARC1; p=reject;" -Comment "Test only please delete"

# Examples Add
Add-DHDnsRecord -Domain "www.example.com" -Type A -Value "104.175.12.199" -comment "www"
Add-DHDnsRecord -Domain "autodiscover.example.com" -Type CNAME -Value "autodiscover.outlook.com" -Comment "autodiscover"
Add-DHDnsRecord -Domain "spanishwitty.com" -Type TXT -Value "MS=ms80528128" -Comment "M365 Ownership Verification"
Add-DHDnsRecord -Domain "spanishwitty.com" -Type TXT -Value "v=spf1 include:spf.protection.outlook.com -all" -Comment "SPF Record"
Add-DHDnsRecord -Domain "selector3._domainkey.spanishwitty.com" -Type CNAME -Value "autodiscover.outlook.com" -Comment "Test only please delete"
Add-DHDnsRecord -Domain "_acme-challenge.www.spanishwitty.org" -Type CNAME -Value "dd89b4d5-0fce-4096-bba7-8661ad721fa8.auth.acme-dns.io" -Comment "ACME DNS Test Server"


# Examples Remove
Remove-DHDnsRecord -Domain "_dmarc3.spanishwitty.com" -Type TXT -Value "v=DMARC1; p=reject;"

Remove-DHDnsRecord -Domain "example.com" -Type TXT -Value "MS=ms67256965"
Remove-DHDnsRecord -Domain "spanishwitty.com" -Type TXT -Value "MS=ms80528128"

# Example List
$AllDomainRecords = List-DHDnsRecord 
$AllDomainRecords | Format-Table
$terrencemontgomery = List-DHDnsRecord | Where-Object {$_.zone -eq "terrencemontgomery.com"}
$terrencemontgomery | ConvertTo-Csv -Delimiter ","


# list available API commands
$cmd = "api-list_accessible_cmds"
$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd"
$uri = $uri.Replace(" ", "%20") # fill in the empty spaces
$response = Invoke-RestMethod -Uri $uri -Method Get
$response