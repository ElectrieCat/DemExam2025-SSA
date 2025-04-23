# Export-SharedFolders.ps1
$exportPath = "C:\SharedFoldersExport.csv"

# �������� ��� ����� �����
$shares = Get-SmbShare

# ������� ������ ��� �������� ������
$exportData = @()

# ������ ����������� ����� ����� ��� ����������
$standardShares = @('C$', 'ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')

foreach ($share in $shares) {
    # ���������, �������� �� ����� ����� �����������
    if ($standardShares -notcontains $share.Name) {
        # �������� ���������� ��� ������ ����� �����
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

# ������������ ������ � CSV ����
$exportData | Export-Csv -Path $exportPath -NoTypeInformation