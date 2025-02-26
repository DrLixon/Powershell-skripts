<# 
 ********************************************************************
 SKRIPTA USER Active Directory INSPECTOR
 ********************************************************************
 kreirana dne 10.02.2025, s strani uporabnika K.H.

 OPIS: 
 Skripta izpiše vse uporabnike v AD.
 Zajeti atributi so:
    - "Uporabnik",
    - "Ime",
    - "Priimek",
    - "Display Name",
    - "Datum Kreiranja",
    - "Zadnja Prijava",
    - "Št. dni od zadnje prijave",
    - "Aktiven (boolean)",
    - "Organizacijska Enota uporabnika",
    - "Geslo poteče (boolean)" in
    - "Opis".
 ********************************************************************
#>
# Global variable for output folder location
$global:OutputFolderPath = "C:\ADD-Reports"

# Definiraj globalno spremenljivko za ime izvozne datoteke z datumom in časom
$global:OutputFileName = "ReportOfUserADInspector_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"

# Ensure the output folder exists and create it if it doesn't
if (-not (Test-Path -Path $global:OutputFolderPath)) {
    New-Item -ItemType Directory -Path $global:OutputFolderPath
    Write-Host "Created output directory at $global:OutputFolderPath"
} else {
    Write-Host "Output directory already exists at $global:OutputFolderPath"
}

# Uvozi modul Active Directory
Import-Module ActiveDirectory

# Pridobi vse domenske uporabnike
$domainUsers = Get-ADUser -Filter * -Property LastLogonDate, WhenCreated, Enabled, PasswordNeverExpires, DistinguishedName, Description, GivenName, Surname, DisplayName

# Pripravi seznam za shranjevanje rezultatov
$results = @()

foreach ($user in $domainUsers) {
    $lastLogon = $user.LastLogonDate
    $creationDate = $user.WhenCreated
    $isActive = if ($user.Enabled) { "True" } else { "False" }
    $passwordExpires = if (-not $user.PasswordNeverExpires) { "True" } else { "False" }
    $ou = ($user.DistinguishedName -split ',')[1] -replace 'OU=', ''
    $description = $user.Description
    $firstName = $user.GivenName
    $lastName = $user.Surname
    $displayName = $user.DisplayName

    if ($lastLogon) {
        # Preračunaj število dni od zadnje prijave
        $daysSinceLastLogon = (Get-Date) - $lastLogon
        $daysSinceLastLogon = $daysSinceLastLogon.Days

        # Dodaj podatke v seznam rezultatov
        $results += [PSCustomObject]@{
            Uporabnik = $user.SamAccountName
            Ime = $firstName
            Priimek = $lastName
            DisplayName = $displayName
            DatumKreiranja = $creationDate
            ZadnjaPrijava = $lastLogon
            DniOdZadnjePrijave = $daysSinceLastLogon
            Aktiven = $isActive
            OrganizacijskaEnota = $ou
            GesloPotece = $passwordExpires
            Opis = $description
        }
    } else {
        # Dodaj podatke v seznam rezultatov
        $results += [PSCustomObject]@{
            Uporabnik = $user.SamAccountName
            Ime = $firstName
            Priimek = $lastName
            DisplayName = $displayName
            DatumKreiranja = $creationDate
            ZadnjaPrijava = "Ni podatka"
            DniOdZadnjePrijave = "Ni podatka"
            Aktiven = $isActive
            OrganizacijskaEnota = $ou
            GesloPotece = $passwordExpires
            Opis = $description
        }
    }
}

# Shrani rezultate v datoteko
$results | Export-Csv -Path "$global:OutputFolderPath\$global:OutputFileName" -NoTypeInformation -Encoding UTF8

# Izpiši sporočilo o uspehu
Write-Output "Poročilo je bilo uspešno shranjeno v $global:OutputFolderPath\$global:OutputFileName"
