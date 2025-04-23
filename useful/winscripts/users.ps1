# Export-Users.ps1
Import-Module ActiveDirectory

# ѕараметры
$exportPath = "C:\users.csv"

# Ёкспорт пользователей
Get-ADUser -Filter * -Property SamAccountName, Name, Description, PasswordLastSet | 
Select-Object SamAccountName, Name, Description | 
Export-Csv -Path $exportPath -NoTypeInformation