# reference article
# https://help.dreamhost.com/hc/en-us/articles/4407354972692-Connecting-to-the-DreamHost-API
# https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands


function List-DHDnsRecord {    
    $BaseUri = "https://api.dreamhost.com/"
    $ApiKey = $env:DREAMHOST_API_KEY
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
        $ApiKey = $env:DREAMHOST_API_KEY
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
        $uri = ("$BaseUri`?key=$ApiKey&cmd=$cmd&record=$Domain&type=$Type&value=$Value&format=$format").Replace(" ", "%20")
        $response = Invoke-RestMethod -Uri $uri -Method Get
    }
    
    end {
        # Write-Host $response.data
        return $response.data
    }
}


# Examples
Add-DHDnsRecord -Domain "www.example.com" -Type A -Value "104.175.12.199" -comment "www"
Add-DHDnsRecord -Domain "autodiscover.example.com" -Type CNAME -Value "autodiscover.outlook.com" -Comment "autodiscover"
Remove-DHDnsRecord -Domain "example.com" -Type TXT -Value "MS=ms67256965"
List-DHDnsRecord

# list available API commands
$cmd = "api-list_accessible_cmds"
$uri = "$BaseUri`?key=$ApiKey&cmd=$cmd"
$uri = $uri.Replace(" ", "%20") # fill in the empty spaces
$response = Invoke-RestMethod -Uri $uri -Method Get
$response