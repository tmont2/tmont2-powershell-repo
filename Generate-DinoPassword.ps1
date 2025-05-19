<#
  .SYNOPSIS
  Generate 1 or more passwords using DinoPass API

  .DESCRIPTION
  Generate 1 or more passwords using DinoPass API
  Specify Number to get the number of passwords desired
  Specify Path to output the passwords to a file

#>
function Generate-DinoPassword12 {    
    [CmdletBinding()]
    param (
        [int]$NumberOfPasswords = 5
    )
    $uri = "https://www.dinopass.com/password/strong"
    $counter = 1
    
    $PassList = [System.Collections.Generic.List[String]]::new()
    while ($counter -le $NumberOfPasswords) {
        Write-Host "Counter: $counter"
        $response = Invoke-WebRequest -URI $uri -Method Get
        if ( ($response.StatusCode -eq 200) -and ($response.Content.Length -ge 12) ) {
            $PassList.Add($response.Content)
            $counter++
        }
    }
    return $PassList
}

$PasswordList = Generate-DinoPassword12 -NumberOfPasswords 10
$PasswordList
$PasswordList | ForEach-Object { $_.Length}

function Generate-DinoPassword {
    [CmdletBinding()]
    param(
        $Number = 1,
        $Path = ""
    )
    $counter = 1    
    $uri = "https://www.dinopass.com/password/strong"
    $PasswordList = while ($counter -le $Number) {
        $response = Invoke-WebRequest -URI $uri -Method Get
        if ($response.StatusCode -eq 200) {
            $counter += 1
        }
        $response.Content
        # Start-Sleep -Seconds 1
    }

    
    $PasswordList | Out-File -FilePath $Path
    #endregion
}

# Example 1
# Generate-DinoPassword -Number 3 -Path "/home/terrence/Desktop/PassList.txt"

