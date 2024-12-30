$VaultBackupPath = "/home/terrence/Desktop/Vault Backup"

# create directories
Foreach ($i in (-45..-15)) {
    # Write-Host -ForegroundColor Green -Object $i
    $Dir = New-Item -Path $VaultBackupPath -Name "Backup$i" -ItemType Directory
    #Set-ItemProperty -Path $Dir -Name LastWriteTime -Value (Get-Date).AddDays($i)
    # create random number of files inside the newly created folder
    $Random = Get-Random -Minimum 5 -Maximum 20
    Foreach ($j in ($Random..1)) {
        $File = New-Item -Path $Dir -Name "RandoFile$j" -ItemType File
        Add-Content -Path $File -Value "Oh Boy!"
    }
    Set-ItemProperty -Path $Dir -Name LastWriteTime -Value (Get-Date).AddDays($i)

}

# delete everything quickly
Get-ChildItem -Path $VaultBackupPath -Recurse -Force | Remove-Item -Recurse -Force

# get folders older than 30 days
Get-ChildItem -Path $VaultBackupPath -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30)} 

# get folders older than 30 days and delete them
Get-ChildItem -Path $VaultBackupPath -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force

[System.Net.Dns]::GetHostByName("www.google.com")
$Yahoo = [System.Net.Dns]::GetHostByName("www.yahoo.com")
$YahooEntry = [System.Net.Dns]::GetHostEntry("www.yahoo.com")
# last change made here on line 30
# last change made here on line 31
