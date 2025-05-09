Import-Module ActiveDirectory

# Автоматическая установка и подключение DSInternals
try {
    Import-Module DSInternals -ErrorAction Stop
} catch {
    Install-Module -Name DSInternals -Force -Scope CurrentUser
    Import-Module DSInternals
}

$csvFilePath = 'C:\export-ad.csv'
$domainDN = (Get-ADDomain).DistinguishedName
$excludedParentDNs = @("CN=Builtin,$domainDN", "CN=Users,$domainDN")

function Is-ExcludedDN($dn) {
    $parts = $dn -split '(?<!\\),'
    if ($parts.Count -gt 1) {
        $parentDN = ($parts[1..($parts.Count - 1)] -join ',').Trim()
        return $excludedParentDNs -contains $parentDN
    }
    return $false
}

function Get-NTHash($samAccountName) {
    try {
        $acct = Get-ADReplAccount -SamAccountName $samAccountName -Server $env:COMPUTERNAME
        return [BitConverter]::ToString($acct.NTHash).Replace('-', '')
    } catch {
        return "N/A"
    }
}

# Получаем только группы (исключая OU)
function Get-UserGroups($memberOf) {
    $groups = $memberOf | ForEach-Object {
        # Проверяем, является ли объект группой, а не OU
        if ($_ -match '^CN=') {
            $group = Get-ADGroup -Filter {DistinguishedName -eq $_} -ErrorAction SilentlyContinue
            if ($group) {
                return ($group.Name)
            }
        }
    }
    return $groups -join '; '
}

# Пользователи
$users = Get-ADUser -Filter * -Properties Name, SamAccountName, Description, DistinguishedName, MemberOf |
Where-Object { -not (Is-ExcludedDN $_.DistinguishedName) } |
ForEach-Object {
    $groups = Get-UserGroups $_.MemberOf
    [PSCustomObject]@{
        ObjectType        = 'User'
        Login             = $_.SamAccountName
        FullName          = $_.Name
        Description       = $_.Description
        DistinguishedName = $_.DistinguishedName -replace ",?$domainDN$", ''
        MemberOf          = $groups
        NTHash            = Get-NTHash $_.SamAccountName
    }
}

# Группы
$groups = Get-ADGroup -Filter * -Properties Name, Members, DistinguishedName |
Where-Object { -not (Is-ExcludedDN $_.DistinguishedName) } |
ForEach-Object {
    $members = $_.Members | ForEach-Object {
        (Get-ADObject $_ -Properties SamAccountName).SamAccountName
    }
    [PSCustomObject]@{
        ObjectType        = 'Group'
        Name              = $_.Name
        Members           = $members -join '; '
        DistinguishedName = $_.DistinguishedName -replace ",?$domainDN$", ''
    }
}

# Подразделения (OU)
$ous = Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName | ForEach-Object {
    $objects = Get-ADObject -SearchBase $_.DistinguishedName -SearchScope OneLevel -Filter * -Properties Name, ObjectClass
    [PSCustomObject]@{
        ObjectType        = 'OU'
        Name              = $_.Name
        DistinguishedName = $_.DistinguishedName -replace ",?$domainDN$", ''
        ChildObjects      = ($objects | ForEach-Object { "$($_.Name) ($($_.ObjectClass))" }) -join '; '
    }
}

# Объединение и экспорт
$allObjects = $users + $groups + $ous
$allObjects | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8 -Force

Write-Host "Экспорт завершен: $csvFilePath" -ForegroundColor Green
