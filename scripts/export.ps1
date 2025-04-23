# Export-All-Refined-v2.ps1
Import-Module ActiveDirectory

# --- ��������� ---
$exportBaseFolder = "C:\AD_Migration_Export" # ����� ��� ���� ������ ��������
$passwordForAllUsers = "P@ssw0rd" # ��������� ������ ��� ���� ������������� (�����: ���������� �������� ����� ��� ������ ����� �� Samba!)

# --- ���� � ������ �������� ---
# ������� ����� ��� ��������, ���� �� ����������
if (-not (Test-Path $exportBaseFolder)) {
    Write-Host "�������� ����� ��� ��������: $exportBaseFolder"
    New-Item -ItemType Directory -Path $exportBaseFolder | Out-Null
}

$OUsStructureExportPath = Join-Path $exportBaseFolder "OUs_Structure.csv"
$usersExportPath = Join-Path $exportBaseFolder "Users_Details.csv"
$groupsDetailsExportPath = Join-Path $exportBaseFolder "Groups_Details.csv"
$groupsMembershipsExportPath = Join-Path $exportBaseFolder "Groups_Memberships.csv"
$sharedFoldersExportPath = Join-Path $exportBaseFolder "SharedFolders_Permissions.csv"

# --- ������ ����������� �������� ��� ���������� ---

# ������ ���� ����������� OU, ������� Get-ADOrganizationalUnit ����� �������
# ������ ����������� ���������� (CN=Users, CN=Computers � �.�.), �.�. Get-ADOrganizationalUnit �� �� ����������
$standardOUNamesToExclude = @(
    "Domain Controllers" # ��� ����������� OU
    # �������� ������ ����� ������ OU (�� �����������!), ������� �������� ������������/���������� � ����� �����
)

# ������ ���� ����������� ����� ��� ����������
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
    # �������� ������ ����������� ��� ����� �����, ���� �����
)

# --- 1. ������� ��������� ������������� (OU) ---
Write-Host "������� ��������� OU..."
# �������� ��� OU
$allOUs = Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
Write-Host "������� ����� OU: $($allOUs.Count)"

# ��������� ����������� OU �� �����
$filteredOUs = $allOUs | Where-Object { $_.Name -notin $standardOUNamesToExclude }

# �������������� ��������: ��������� OU ������ ����������� OU (��������, ������ "Domain Controllers")
# $filteredOUs = $filteredOUs | Where-Object { $_.DistinguishedName -notmatch ',OU=Domain Controllers,'} # ���������������� � �����������, ���� �����

Write-Host "OU ����� ���������� �� �����: $($filteredOUs.Count)"

# ��������� �� ����� DN, ����� ������������ OU ��� ������ (�������� ��� �������)
$sortedOUs = $filteredOUs | Sort-Object @{Expression = {$_.DistinguishedName.Length}} | Select-Object DistinguishedName

# ������������ ������ DistinguishedName
if ($sortedOUs) {
    $sortedOUs | Export-Csv -Path $OUsStructureExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "��������� OU �������������� � $OUsStructureExportPath"
} else {
    Write-Warning "�� ������� ��-����������� OU ��� ��������. ���� $OUsStructureExportPath ����� ������ ��� �� ����� ������."
    # ������� ������ ���� � ����������, ����� ������ ������� �� �����
    "DistinguishedName" | Out-File -FilePath $OUsStructureExportPath -Encoding UTF8
}

# --- 2. ������� ������������� ---
Write-Host "������� �������������..."
# �������� ������������� �� ����� ������� ����������
# ��������� ������������� �� ����������� ����������� Builtin � Users �� DN
$users = Get-ADUser -Filter * -Properties SamAccountName, Name, Description, DistinguishedName, homeDirectory, homeDrive, scriptPath, Enabled |
    Where-Object { $_.DistinguishedName -notmatch '^CN=.*,CN=Builtin,' -and $_.DistinguishedName -notmatch '^CN=.*,CN=Users,' }

Write-Host "������� ������������� ��� �������� (��� CN=Users, CN=Builtin): $($users.Count)"

# ��������� ���� � ������� � �������� ������ �������
$usersDataForExport = $users | ForEach-Object {
    [PSCustomObject]@{
        SamAccountName  = $_.SamAccountName
        Name            = $_.Name # ������ �������� ���, �� ����� ���� �����
        Description     = $_.Description # �� ������� �������������� ��� �����, �� ������������ ��� ����
        DistinguishedName = $_.DistinguishedName # ��� ���������� � ���������� OU
        Enabled         = $_.Enabled # ������ ������� ������ (True/False)
        # �������� �������. ����� �������, ���� �� ������ � AD!
        HomeDirectory   = $_.homeDirectory
        HomeDrive       = $_.homeDrive
        ScriptPath      = $_.scriptPath
        Password        = $passwordForAllUsers # ��������� ������
    }
}

# ������������ ������������� � CSV
$usersDataForExport | Export-Csv -Path $usersExportPath -NoTypeInformation -Encoding UTF8
Write-Host "������������ �������������� � $usersExportPath"
Write-Warning "�����: ������������� �������� ��������� ������ '$passwordForAllUsers'. ��������� �� Samba �������� ����� ������ ��� ������ �����!"
Write-Warning "����������: ������ ���� ��� HomeDirectory, HomeDrive, ScriptPath ��������, ��� ��� �������� �� ���� ������ ��� ������������ � Active Directory."

# --- 3. ������� ����� (������ � ��������) ---

# �������� ��� ������ � ������� ����������
$allGroups = Get-ADGroup -Filter * -Properties SamAccountName, Name, Description, DistinguishedName, GroupScope, GroupCategory, isCriticalSystemObject

# ��������� ����������� � ��������� ������
$filteredGroups = $allGroups | Where-Object {
    ($_.Name -notin $standardGroupNamesToExclude) `
    -and ($_.DistinguishedName -notmatch '^CN=.*,CN=Builtin,') `
    -and ($_.DistinguishedName -notmatch '^CN=.*,CN=Users,') `
    -and (-not $_.isCriticalSystemObject) # �������������� �������� �� ���������� ������ ��������� �������
}
Write-Host "������� ����� ��� �������� (�� �����������, �� � Builtin/Users, �� ���������): $($filteredGroups.Count)"

# 3.1 ������� ������� �����
Write-Host "������� ������� �����..."
$groupsDetails = $filteredGroups | Select-Object SamAccountName, Name, Description, DistinguishedName, GroupScope, GroupCategory

$groupsDetails | Export-Csv -Path $groupsDetailsExportPath -NoTypeInformation -Encoding UTF8
Write-Host "������ ����� �������������� � $groupsDetailsExportPath"

# 3.2 ������� �������� � �������
Write-Host "������� �������� � �������..."
$groupMemberships = @()
# ���������� ��� ��������������� ������ $filteredGroups
foreach ($group in $filteredGroups) {
    Write-Verbose "��������� ������ ������: $($group.Name) ($($group.DistinguishedName))"
    try {
        # �������� ������ ������, ���������� ������ ������ �������� ��� ���������
        $members = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue | Get-ADObject -Properties SamAccountName, DistinguishedName -ErrorAction SilentlyContinue

        foreach ($member in $members) {
            if($member -ne $null -and $member.SamAccountName -ne $null) {
                 $groupMemberships += [PSCustomObject]@{
                    GroupDistinguishedName = $group.DistinguishedName # DN ������ ��� ��������
                    MemberSamAccountName   = $member.SamAccountName   # SamAccountName ����� ��� ����������
                    MemberDistinguishedName= $member.DistinguishedName # DN ����� ��� ����������/��������
                 }
            } else {
                 # ��� ����� ���������, ���� ���� ������ �� ������� ������ ��� ������ ���������/������
                 Write-Warning "�� ������� �������� ������ ��� ����� ������ $($group.Name). ��������, ������� ��� ��������� ������."
            }
        }
    } catch {
        Write-Warning "������ ��� ��������� ������ ������ $($group.Name): $($_.Exception.Message)"
    }
}

$groupMemberships | Export-Csv -Path $groupsMembershipsExportPath -NoTypeInformation -Encoding UTF8
Write-Host "�������� � ������� �������������� � $groupsMembershipsExportPath"


# --- 4. ������� ����� ����� � ���������� � ��� (�� ������ ����) ---
# (��� ����� ��������� ��� ���������, �.�. �� ��� �� ���� ���������)
Write-Host "������� ����� ����� � ���������� (share-level)..."
try {
    $shares = Get-SmbShare -ErrorAction Stop # ���������� Stop, ����� ������� ������, ���� ��������� ����������
} catch {
    Write-Error "�� ������� ��������� Get-SmbShare. ���������, ��� ������ SmbShare �������� � � ��� ���� �����. ������: $($_.Exception.Message)"
    # ��������� ��� �����, �� ���������� ������
    $shares = @()
}


$exportDataShares = @()
# ����������� ������ �����������/������� ��� ��� ����������
$standardSharesToExclude = @('ADMIN$', 'IPC$', 'print$', 'NETLOGON', 'SYSVOL')
$driveLetterSharesPattern = '^[A-Z]\$$' # ������� ��� ������ ���� C$, D$

foreach ($share in $shares) {
    # ��������� ���� �� ������, ��������� ����� (C$, D$...) � ������ ������� (��������������� �� $),
    # �� ��������� NETLOGON � SYSVOL, ���� ��� ����
    $isStandard = $standardSharesToExclude -contains $share.Name
    $isDriveShare = $share.Name -match $driveLetterSharesPattern
    $isHidden = $share.Name.EndsWith('$')
    $isException = ($share.Name -eq 'NETLOGON') -or ($share.Name -eq 'SYSVOL')

    if (-not ($isStandard -or $isDriveShare -or ($isHidden -and -not $isException))) {
         Write-Verbose "��������� ����: $($share.Name)"
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
                     Write-Warning "��������� ���������� ��� AccountName ��� ���� $($share.Name)"
                }
            }
        } catch {
            Write-Warning "������ ��� ��������� ���������� ��� ���� $($share.Name): $($_.Exception.Message)"
        }
    } else {
         Write-Verbose "������� �����������/�������/�������� ����: $($share.Name)"
    }
}

# ������������ ������ � CSV ���� ��� ����� �����
$exportDataShares | Export-Csv -Path $sharedFoldersExportPath -NoTypeInformation -Encoding UTF8
Write-Host "����� ����� � �� ���������� (share-level) �������������� � $sharedFoldersExportPath"
Write-Warning "�����: �������������� ������ ���������� �� ������ ������ ������� (share permissions). ���������� �������� ������� NTFS �� �������������� � ������� ��������� ��������/��������� �� Samba!"

# --- ���������� ---
Write-Host "-----------------------------------------------------"
Write-Host "������� ��������! ����� ��������� � �����: $exportBaseFolder"
Write-Host "���������� �����:"
Get-ChildItem $exportBaseFolder | Select-Object Name, Length, LastWriteTime
Write-Host "-----------------------------------------------------"
# (��������� � ��������� ����� ��������� ��� ���������)
Write-Host "��������� ����:"
Write-Host "1. ���������� ����� '$exportBaseFolder' �� ������ Samba ��� � ��������� ��� ���� �����."
Write-Host "2. ����������� ���������� ������� ������� �� Samba ��� ��������� ������:"
Write-Host "   - '$($OUsStructureExportPath.Split('\')[-1])': ������� ��������� OU (��������� DistinguishedName)."
Write-Host "   - '$($groupsDetailsExportPath.Split('\')[-1])': ������� ������ � �� ���������� � ������ OU (��������� DistinguishedName)."
Write-Host "   - '$($usersExportPath.Split('\')[-1])': ������� ������������� � �� ���������� � ������ OU (��������� DistinguishedName), ���������� ��������� ������."
Write-Host "   - '$($groupsMembershipsExportPath.Split('\')[-1])': �������� �������������/������ � ��������������� ������."
Write-Host "   - '$($sharedFoldersExportPath.Split('\')[-1])': ��������� ����� ����� � ���������� �� ������ ���� � smb.conf."
Write-Host "3. ��������� �������� ����� ������ ��� ������ ����� ��� ��������������� ������������� �� Samba!"
Write-Host "4. ���������� �������� ������ � ��������� ���������� NTFS �� �������� ������� ������� Samba."
Write-Host "5. ��������� �������������� ������������ ������ ��� HQ-CLI (��������, ����� login scripts � Samba ��� �������� �� ��������)."
Write-Host "-----------------------------------------------------"