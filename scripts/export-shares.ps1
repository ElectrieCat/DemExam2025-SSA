$csvFilePath = 'C:\SharedFolders.csv'
$shares = Get-SmbShare | ForEach-Object {
    $access = Get-SmbShareAccess -Name $_.Name
    if (-not ($access.AccountName -match 'BUILTIN')) {
        [PSCustomObject]@{
            ObjectType  = 'Share'
            Login       = $_.Name
            Description = $_.Description
            Permissions = ($access | % { "$($_.AccountName): $($_.AccessRight)" }) -join '; '
        }
    }
}

$result | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Экспорт завершен: $csvFilePath"
