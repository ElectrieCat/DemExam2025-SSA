# Export-All.ps1
Import-Module ActiveDirectory

# Параметры
$usersExportPath = "C:\users.csv"
$groupsExportPath = "C:\groups.csv"
$OUsExportPath = "C:\OUsExport.csv"
$sharedFoldersExportPath = "C:\SharedFoldersExport.csv"

# 1. Экспорт пользователей и добавление пароля
$password = "P@ssw0rd"  # Пароль для всех пользователей

$users = Get-ADUser -Filter * -Property SamAccountName, Name, Description | 
Select-Object SamAccountName, Name, Description

# Добавляем поле с паролем к каждому пользователю
$usersWithPassword = $users | ForEach-Object {
    [PSCustomObject]@{
        SamAccountName = $_.SamAccountName
        Name           = $_.Name
        Description    = $_.Description
        Password       = $password  # Добавляем пароль
    }
}

# Экспортируем пользователей в CSV
$usersWithPassword | Export-Csv -Path $usersExportPath -NoTypeInformation

Write-Host "Экспорт пользователей завершен! Пароли добавлены в файл."

# 2. Экспорт групп и членов групп, исключая стандартные
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
    "Domain Guests"
)

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
} | Export-Csv -Path $groupsExportPath -NoTypeInformation

# 3. Экспорт подразделений и входящих в них пользователей и групп
$standardOUs = @(
    "Users",
    "Computers",
    "Domain Controllers",
    "Managed",
    "ForeignSecurityPrincipals",
    "System"
)

$OUs = Get-ADOrganizationalUnit -Filter * | Where-Object { 
    -not ($standardOUs -contains $_.Name)
} | Select-Object Name, DistinguishedName

# Создаем массив для хранения данных
$exportDataOUs = @()

foreach ($ou in $OUs) {
    # Получаем пользователей и группы в каждом подразделении
    $members = Get-ADObject -Filter * -SearchBase $ou.DistinguishedName | Select-Object Name, ObjectClass
    
    foreach ($member in $members) {
        $exportDataOUs += [PSCustomObject]@{
            OUName         = $ou.Name
            OUDistinguishedName = $ou.DistinguishedName
            MemberName     = $member.Name
            MemberType     = $member.ObjectClass
        }
    }
}

# Экспортируем данные в CSV файл для OUs
$exportDataOUs | Export-Csv -Path $OUsExportPath -NoTypeInformation

# 4. Экспорт общих папок и разрешений к ним
$shares = Get-SmbShare

# Создаем массив для хранения данных для общих папок
$exportDataShares = @()

# Список стандартных общих папок для исключения
$standardShares = @('C$', 'ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')

foreach ($share in $shares) {
    # Проверяем, является ли общая папка стандартной
    if ($standardShares -notcontains $share.Name) {
        # Получаем разрешения для каждой общей папки
        $permissions = Get-SmbShareAccess -Name $share.Name

        foreach ($permission in $permissions) {
            $exportDataShares += [PSCustomObject]@{
                ShareName      = $share.Name
                SharePath      = $share.Path
                Trustee        = $permission.AccountName
                AccessRight    = $permission.AccessRight
            }
        }
    }
}

# Экспортируем данные в CSV файл для общих папок
$exportDataShares | Export-Csv -Path $sharedFoldersExportPath -NoTypeInformation

Write-Host "Экспорт завершен! Все данные сохранены."