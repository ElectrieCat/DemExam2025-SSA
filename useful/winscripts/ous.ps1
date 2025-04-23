# Export-OUs.ps1
Import-Module ActiveDirectory

# ���������
$exportPath = "C:\OUsExport.csv"

# ���������� ����������� OU, ������� ����� ���������
$standardOUs = @(
    "Users",
    "Computers",
    "Domain Controllers",
    "Managed",
    "ForeignSecurityPrincipals",
    "System"
)

# �������� ��� �������������, �������� �����������
$OUs = Get-ADOrganizationalUnit -Filter * | Where-Object { 
    $ouName = $_.Name
    -not ($standardOUs -contains $ouName)
} | Select-Object Name, DistinguishedName

# ������� ������ ��� �������� ������
$exportData = @()

foreach ($ou in $OUs) {
    # �������� ������������� � ������ � ������ �������������
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

# ������������ ������ � CSV ����
$exportData | Export-Csv -Path $exportPath -NoTypeInformation