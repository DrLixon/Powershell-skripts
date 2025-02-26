<# 
 ********************************************************************
 IZPIS WINDOWS STREŽNIKOV
 ********************************************************************
 kreirana dne 10.02.2025, s strani uporabnika K.H.

 OPIS: 
 Skripta izpiše vse Windows strežnike v sistemu.
 ********************************************************************
#>

# Definiraj globalno spremenljivko za pot izhodne mape
$global:OutputFilePath = "C:\ADD-Reports\"

# Definiraj globalno spremenljivko za ime izvozne datoteke z datumom in časom
$global:OutputFileName = "ReportOfWinSrv_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"

# Preveri, ali izhodna mapa obstaja, in jo ustvari, če ne obstaja.
if (-not (Test-Path -Path $global:OutputFilePath)) {
    New-Item -ItemType Directory -Path $global:OutputFilePath
    Write-Host "Created output directory at $global:OutputFilePath"
} else {
    Write-Host "Output directory already exists at $global:OutputFilePath"
}

# Uvozi modul Active Directory
Import-Module ActiveDirectory

# Pridobi seznam vseh omogočenih strežnikov v domeni
$servers = Get-ADComputer -Filter {(Enabled -eq $True) -and (OperatingSystem -like "*Server*")} -Property Name, IPv4Address, OperatingSystem, OperatingSystemVersion

#Ustvari prilagojen objekt za vsak strežnik z želenimi lastnostmi
$serverList = $servers | Select-Object Name, IPv4Address, OperatingSystem, OperatingSystemVersion

# Izvozi rezultate v CSV datoteko
$serverList | Export-Csv -Path "$global:OutputFilePath\$global:OutputFileName" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Exported server list to $global:OutputFilePath\$global:OutputFileName"
