# Export-All.ps1
Import-Module ActiveDirectory

# ���������
$usersExportPath = "C:\users.csv"
$groupsExportPath = "C:\groups.csv"
$OUsExportPath = "C:\OUsExport.csv"
$sharedFoldersExportPath = "C:\SharedFoldersExport.csv"

# 1. ������� ������������� � ���������� ������
$password = "P@ssw0rd"  # ������ ��� ���� �������������

$users = Get-ADUser -Filter * -Property SamAccountName, Name, Description | 
Select-Object SamAccountName, Name, Description

# ��������� ���� � ������� � ������� ������������
$usersWithPassword = $users | ForEach-Object {
    [PSCustomObject]@{
        SamAccountName = $_.SamAccountName
        Name           = $_.Name
        Description    = $_.Description
        Password       = $password  # ��������� ������
    }
}

# ������������ ������������� � CSV
$usersWithPassword | Export-Csv -Path $usersExportPath -NoTypeInformation

Write-Host "������� ������������� ��������! ������ ��������� � ����."

# 2. ������� ����� � ������ �����, �������� �����������
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
    
    # �������� ������ ������
    $members = Get-ADGroupMember -Identity $group | Select-Object SamAccountName
    
    foreach ($member in $members) {
        [PSCustomObject]@{
            GroupName     = $group.Name
            MemberName    = $member.SamAccountName
        }
    }
} | Export-Csv -Path $groupsExportPath -NoTypeInformation

# 3. ������� ������������� � �������� � ��� ������������� � �����
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

# ������� ������ ��� �������� ������
$exportDataOUs = @()

foreach ($ou in $OUs) {
    # �������� ������������� � ������ � ������ �������������
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

# ������������ ������ � CSV ���� ��� OUs
$exportDataOUs | Export-Csv -Path $OUsExportPath -NoTypeInformation

# 4. ������� ����� ����� � ���������� � ���
$shares = Get-SmbShare

# ������� ������ ��� �������� ������ ��� ����� �����
$exportDataShares = @()

# ������ ����������� ����� ����� ��� ����������
$standardShares = @('C$', 'ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')

foreach ($share in $shares) {
    # ���������, �������� �� ����� ����� �����������
    if ($standardShares -notcontains $share.Name) {
        # �������� ���������� ��� ������ ����� �����
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

# ������������ ������ � CSV ���� ��� ����� �����
$exportDataShares | Export-Csv -Path $sharedFoldersExportPath -NoTypeInformation

Write-Host "������� ��������! ��� ������ ���������."