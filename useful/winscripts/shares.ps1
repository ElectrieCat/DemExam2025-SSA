# Export-SharedFolders.ps1
$exportPath = "C:\SharedFoldersExport.csv"

# Получаем все общие папки
$shares = Get-SmbShare

# Создаем массив для хранения данных
$exportData = @()

# Список стандартных общих папок для исключения
$standardShares = @('C$', 'ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')

foreach ($share in $shares) {
    # Проверяем, является ли общая папка стандартной
    if ($standardShares -notcontains $share.Name) {
        # Получаем разрешения для каждой общей папки
        $permissions = Get-SmbShareAccess -Name $share.Name

        foreach ($permission in $permissions) {
            $exportData += [PSCustomObject]@{
                ShareName      = $share.Name
                SharePath      = $share.Path
                Trustee        = $permission.AccountName
                AccessRight    = $permission.AccessRight
            }
        }
    }
}

# Экспортируем данные в CSV файл
$exportData | Export-Csv -Path $exportPath -NoTypeInformation