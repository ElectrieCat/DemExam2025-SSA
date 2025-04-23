# Export-Users.ps1
Import-Module ActiveDirectory

# ���������
$exportPath = "C:\users.csv"

# ������� �������������
Get-ADUser -Filter * -Property SamAccountName, Name, Description, PasswordLastSet | 
Select-Object SamAccountName, Name, Description | 
Export-Csv -Path $exportPath -NoTypeInformation