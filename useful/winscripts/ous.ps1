# Export-OUs.ps1
Import-Module ActiveDirectory

# Параметры
$exportPath = "C:\OUsExport.csv"

# Определите стандартные OU, которые нужно исключить
$standardOUs = @(
    "Users",
    "Computers",
    "Domain Controllers",
    "Managed",
    "ForeignSecurityPrincipals",
    "System"
)

# Получаем все подразделения, исключая стандартные
$OUs = Get-ADOrganizationalUnit -Filter * | Where-Object { 
    $ouName = $_.Name
    -not ($standardOUs -contains $ouName)
} | Select-Object Name, DistinguishedName

# Создаем массив для хранения данных
$exportData = @()

foreach ($ou in $OUs) {
    # Получаем пользователей и группы в каждом подразделении
    $members = Get-ADObject -Filter * -SearchBase $ou.DistinguishedName | Select-Object Name, ObjectClass
    
    foreach ($member in $members) {
        $exportData += [PSCustomObject]@{
            OUName         = $ou.Name
            OUDistinguishedName = $ou.DistinguishedName
            MemberName     = $member.Name
            MemberType     = $member.ObjectClass
        }
    }
}

# Экспортируем данные в CSV файл
$exportData | Export-Csv -Path $exportPath -NoTypeInformation