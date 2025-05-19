
function Get-PublicIP1 () {
    $ip_address = Invoke-RestMethod -Uri "https://api.ipify.org" -Method Get
    return $ip_address
}

Get-PublicIP1

function Get-PublicIP2 () {
    $ip_address = Resolve-dnsna
    return $ip_address
}

Get-PublicIP2