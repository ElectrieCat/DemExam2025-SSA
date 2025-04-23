# Export-Groups.ps1
Import-Module ActiveDirectory

# Параметры
$exportPath = "C:\groups.csv"

# Определите стандартные группы, которые нужно исключить
$standardGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Users",
    "Guests",
    "Account Operators",
    "Backup Operators",
    "Print Operators",
    "Domain Controllers",
    "Domain Users",
    "IIS_IUSRS",
    "Group Policy Creator Owners",
    "Pre-Windows 2000 Compatible Access",
    "Windows Authorization Access Group",
    "Denied RODC Password Replication Group",
    "Domain Guests"  # Добавлено для исключения
)

# Экспорт групп и членов групп, исключая стандартные
Get-ADGroup -Filter * | Where-Object { $standardGroups -notcontains $_.Name } | ForEach-Object {
    $group = $_
    
    # Получаем членов группы
    $members = Get-ADGroupMember -Identity $group | Select-Object SamAccountName
    
    foreach ($member in $members) {
        [PSCustomObject]@{
            GroupName     = $group.Name
            MemberName    = $member.SamAccountName
        }
    }
} | Export-Csv -Path $exportPath -NoTypeInformation