# Export-All-Refined-v2.ps1
Import-Module ActiveDirectory

# --- Параметры ---
$exportBaseFolder = "C:\AD_Migration_Export" # Папка для всех файлов экспорта
$passwordForAllUsers = "P@ssw0rd" # Временный пароль ДЛЯ ВСЕХ пользователей (ВАЖНО: Установить политику смены при первом входе на Samba!)

# --- Пути к файлам экспорта ---
# Создаем папку для экспорта, если не существует
if (-not (Test-Path $exportBaseFolder)) {
    Write-Host "Создание папки для экспорта: $exportBaseFolder"
    New-Item -ItemType Directory -Path $exportBaseFolder | Out-Null
}

$OUsStructureExportPath = Join-Path $exportBaseFolder "OUs_Structure.csv"
$usersExportPath = Join-Path $exportBaseFolder "Users_Details.csv"
$groupsDetailsExportPath = Join-Path $exportBaseFolder "Groups_Details.csv"
$groupsMembershipsExportPath = Join-Path $exportBaseFolder "Groups_Memberships.csv"
$sharedFoldersExportPath = Join-Path $exportBaseFolder "SharedFolders_Permissions.csv"

# --- Списки стандартных объектов для исключения ---

# Список имен стандартных OU, которые Get-ADOrganizationalUnit МОЖЕТ вернуть
# Убраны стандартные контейнеры (CN=Users, CN=Computers и т.д.), т.к. Get-ADOrganizationalUnit их не возвращает
$standardOUNamesToExclude = @(
    "Domain Controllers" # Это стандартный OU
    # Добавьте СТРОГО имена других OU (не контейнеров!), которые считаете стандартными/системными в вашей среде
)

# Список имен стандартных Групп для исключения
$standardGroupNamesToExclude = @(
    "Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators",
    "Users", "Guests", "Account Operators", "Backup Operators", "Print Operators",
    "Server Operators", "Domain Computers", "Domain Controllers", "Domain Users",
    "Domain Guests", "Group Policy Creator Owners", "Denied RODC Password Replication Group",
    "Allowed RODC Password Replication Group", "Certificate Service DCOM Access",
    "Cert Publishers", "DnsAdmins", "DnsUpdateProxy", "IIS_IUSRS",
    "Pre-Windows 2000 Compatible Access", "RAS and IAS Servers",
    "Windows Authorization Access Group", "Hyper-V Administrators",
    "Cryptographic Operators", "Event Log Readers", "Remote Management Users"
    # Добавьте другие специфичные для вашей среды, если нужно
)

# --- 1. Экспорт структуры Подразделений (OU) ---
Write-Host "Экспорт структуры OU..."
# Получаем ВСЕ OU
$allOUs = Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
Write-Host "Найдено всего OU: $($allOUs.Count)"

# Фильтруем стандартные OU по ИМЕНИ
$filteredOUs = $allOUs | Where-Object { $_.Name -notin $standardOUNamesToExclude }

# Дополнительная проверка: исключаем OU внутри стандартных OU (например, внутри "Domain Controllers")
# $filteredOUs = $filteredOUs | Where-Object { $_.DistinguishedName -notmatch ',OU=Domain Controllers,'} # Раскомментируйте и адаптируйте, если нужно

Write-Host "OU после фильтрации по имени: $($filteredOUs.Count)"

# Сортируем по длине DN, чтобы родительские OU шли раньше (помогает при импорте)
$sortedOUs = $filteredOUs | Sort-Object @{Expression = {$_.DistinguishedName.Length}} | Select-Object DistinguishedName

# Экспортируем только DistinguishedName
if ($sortedOUs) {
    $sortedOUs | Export-Csv -Path $OUsStructureExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Структура OU экспортирована в $OUsStructureExportPath"
} else {
    Write-Warning "Не найдено не-стандартных OU для экспорта. Файл $OUsStructureExportPath будет пустым или не будет создан."
    # Создаем пустой файл с заголовком, чтобы скрипт импорта не падал
    "DistinguishedName" | Out-File -FilePath $OUsStructureExportPath -Encoding UTF8
}

# --- 2. Экспорт Пользователей ---
Write-Host "Экспорт пользователей..."
# Получаем пользователей со всеми нужными атрибутами
# Исключаем пользователей из стандартных контейнеров Builtin и Users по DN
$users = Get-ADUser -Filter * -Properties SamAccountName, Name, Description, DistinguishedName, homeDirectory, homeDrive, scriptPath, Enabled |
    Where-Object { $_.DistinguishedName -notmatch '^CN=.*,CN=Builtin,' -and $_.DistinguishedName -notmatch '^CN=.*,CN=Users,' }

Write-Host "Найдено пользователей для экспорта (вне CN=Users, CN=Builtin): $($users.Count)"

# Добавляем поле с паролем и выбираем нужные столбцы
$usersDataForExport = $users | ForEach-Object {
    [PSCustomObject]@{
        SamAccountName  = $_.SamAccountName
        Name            = $_.Name # Обычно содержит ФИО, но может быть иначе
        Description     = $_.Description # По заданию предполагается ФИО здесь, но экспортируем как есть
        DistinguishedName = $_.DistinguishedName # Для размещения в правильном OU
        Enabled         = $_.Enabled # Статус учетной записи (True/False)
        # Атрибуты профиля. Будут пустыми, если не заданы в AD!
        HomeDirectory   = $_.homeDirectory
        HomeDrive       = $_.homeDrive
        ScriptPath      = $_.scriptPath
        Password        = $passwordForAllUsers # Временный пароль
    }
}

# Экспортируем пользователей в CSV
$usersDataForExport | Export-Csv -Path $usersExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Пользователи экспортированы в $usersExportPath"
Write-Warning "ВАЖНО: Пользователям назначен временный пароль '$passwordForAllUsers'. Настройте на Samba политику смены пароля при первом входе!"
Write-Warning "Примечание: Пустые поля для HomeDirectory, HomeDrive, ScriptPath означают, что эти атрибуты не были заданы для пользователя в Active Directory."

# --- 3. Экспорт Групп (Детали и Членство) ---

# Получаем все группы с нужными свойствами
$allGroups = Get-ADGroup -Filter * -Properties SamAccountName, Name, Description, DistinguishedName, GroupScope, GroupCategory, isCriticalSystemObject

# Фильтруем стандартные и системные группы
$filteredGroups = $allGroups | Where-Object {
    ($_.Name -notin $standardGroupNamesToExclude) `
    -and ($_.DistinguishedName -notmatch '^CN=.*,CN=Builtin,') `
    -and ($_.DistinguishedName -notmatch '^CN=.*,CN=Users,') `
    -and (-not $_.isCriticalSystemObject) # Дополнительная проверка на критически важные системные объекты
}
Write-Host "Найдено групп для экспорта (не стандартные, не в Builtin/Users, не системные): $($filteredGroups.Count)"

# 3.1 Экспорт Деталей Групп
Write-Host "Экспорт деталей групп..."
$groupsDetails = $filteredGroups | Select-Object SamAccountName, Name, Description, DistinguishedName, GroupScope, GroupCategory

$groupsDetails | Export-Csv -Path $groupsDetailsExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Детали групп экспортированы в $groupsDetailsExportPath"

# 3.2 Экспорт Членства в Группах
Write-Host "Экспорт членства в группах..."
$groupMemberships = @()
# Используем УЖЕ отфильтрованный список $filteredGroups
foreach ($group in $filteredGroups) {
    Write-Verbose "Получение членов группы: $($group.Name) ($($group.DistinguishedName))"
    try {
        # Получаем членов группы, запрашивая только нужные атрибуты для ускорения
        $members = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue | Get-ADObject -Properties SamAccountName, DistinguishedName -ErrorAction SilentlyContinue

        foreach ($member in $members) {
            if($member -ne $null -and $member.SamAccountName -ne $null) {
                 $groupMemberships += [PSCustomObject]@{
                    GroupDistinguishedName = $group.DistinguishedName # DN группы для точности
                    MemberSamAccountName   = $member.SamAccountName   # SamAccountName члена для добавления
                    MemberDistinguishedName= $member.DistinguishedName # DN члена для информации/проверки
                 }
            } else {
                 # Это может произойти, если член группы из другого домена или объект поврежден/удален
                 Write-Warning "Не удалось получить детали для члена группы $($group.Name). Возможно, внешний или удаленный объект."
            }
        }
    } catch {
        Write-Warning "Ошибка при получении членов группы $($group.Name): $($_.Exception.Message)"
    }
}

$groupMemberships | Export-Csv -Path $groupsMembershipsExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Членство в группах экспортировано в $groupsMembershipsExportPath"


# --- 4. Экспорт Общих папок и Разрешений к ним (на уровне шары) ---
# (Эта часть оставлена без изменений, т.к. по ней не было нареканий)
Write-Host "Экспорт общих папок и разрешений (share-level)..."
try {
    $shares = Get-SmbShare -ErrorAction Stop # Используем Stop, чтобы поймать ошибку, если командлет недоступен
} catch {
    Write-Error "Не удалось выполнить Get-SmbShare. Убедитесь, что модуль SmbShare доступен и у вас есть права. Ошибка: $($_.Exception.Message)"
    # Завершаем эту часть, но продолжаем скрипт
    $shares = @()
}


$exportDataShares = @()
# Обновленный список стандартных/скрытых шар для исключения
$standardSharesToExclude = @('ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')
$driveLetterSharesPattern = '^[A-Z]\$$' # Паттерн для дисков типа C$, D$

foreach ($share in $shares) {
    # Исключаем шары из списка, системные диски (C$, D$...) и прочие скрытые (заканчивающиеся на $),
    # но оставляем NETLOGON и SYSVOL, если они есть
    $isStandard = $standardSharesToExclude -contains $share.Name
    $isDriveShare = $share.Name -match $driveLetterSharesPattern
    $isHidden = $share.Name.EndsWith('$')
    $isException = ($share.Name -eq 'NETLOGON') -or ($share.Name -eq 'SYSVOL')

    if (-not ($isStandard -or $isDriveShare -or ($isHidden -and -not $isException))) {
         Write-Verbose "Обработка шары: $($share.Name)"
        try {
            $permissions = Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue

            foreach ($permission in $permissions) {
                if ($permission.AccountName) {
                    $exportDataShares += [PSCustomObject]@{
                        ShareName      = $share.Name
                        SharePath      = $share.Path
                        ScopeName      = $share.ScopeName
                        Trustee        = $permission.AccountName
                        AccessControlType = $permission.AccessControlType
                        AccessRight    = $permission.AccessRight
                    }
                } else {
                     Write-Warning "Пропущено разрешение без AccountName для шары $($share.Name)"
                }
            }
        } catch {
            Write-Warning "Ошибка при получении разрешений для шары $($share.Name): $($_.Exception.Message)"
        }
    } else {
         Write-Verbose "Пропуск стандартной/скрытой/дисковой шары: $($share.Name)"
    }
}

# Экспортируем данные в CSV файл для общих папок
$exportDataShares | Export-Csv -Path $sharedFoldersExportPath -NoTypeInformation -Encoding UTF8
Write-Host "Общие папки и их разрешения (share-level) экспортированы в $sharedFoldersExportPath"
Write-Warning "ВАЖНО: Экспортированы только разрешения на уровне ОБЩЕГО РЕСУРСА (share permissions). Разрешения файловой системы NTFS НЕ экспортированы и требуют отдельной миграции/настройки на Samba!"

# --- Завершение ---
Write-Host "-----------------------------------------------------"
Write-Host "Экспорт завершен! Файлы сохранены в папке: $exportBaseFolder"
Write-Host "Содержимое папки:"
Get-ChildItem $exportBaseFolder | Select-Object Name, Length, LastWriteTime
Write-Host "-----------------------------------------------------"
# (Сообщения о следующих шагах оставлены без изменений)
Write-Host "Следующие шаги:"
Write-Host "1. Скопируйте папку '$exportBaseFolder' на сервер Samba или в доступное для него место."
Write-Host "2. Используйте самописные скрипты импорта на Samba для обработки файлов:"
Write-Host "   - '$($OUsStructureExportPath.Split('\')[-1])': Создать структуру OU (используя DistinguishedName)."
Write-Host "   - '$($groupsDetailsExportPath.Split('\')[-1])': Создать группы с их атрибутами в нужных OU (используя DistinguishedName)."
Write-Host "   - '$($usersExportPath.Split('\')[-1])': Создать пользователей с их атрибутами в нужных OU (используя DistinguishedName), установить временный пароль."
Write-Host "   - '$($groupsMembershipsExportPath.Split('\')[-1])': Добавить пользователей/группы в соответствующие группы."
Write-Host "   - '$($sharedFoldersExportPath.Split('\')[-1])': Настроить общие папки и разрешения на уровне шары в smb.conf."
Write-Host "3. Настройте политику смены пароля при первом входе для импортированных пользователей на Samba!"
Write-Host "4. Реализуйте миграцию данных и настройку разрешений NTFS на файловой системе сервера Samba."
Write-Host "5. Настройте автоматическое монтирование дисков для HQ-CLI (например, через login scripts в Samba или политики на клиентах)."
Write-Host "-----------------------------------------------------"