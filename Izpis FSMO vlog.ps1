<# 
 ********************************************************************
 IZPIS FSMO VLOG
 ********************************************************************
 kreirana dne 10.02.2025, s strani uporabnika K.H.

 OPIS: 
 Skripta izpiše vse "Flexible Single Master Operations" - FSMO vloge.

 Vloge so: 
    - "Schema Master", 
    - "Domain Naming Master", 
    - "RID Master", 
    - "PDC Emulator" in
    - "Infrastructure Master".
 ********************************************************************
#>

# Definiraj globalno spremenljivko za pot izhodne mape
$global:OutputFolderPath = "C:\ADD-Reports"

# Definiraj globalno spremenljivko za ime izvozne datoteke z datumom in časom
$global:OutputFileName = "ReportOfFSMO_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"

# Preveri, ali izhodna mapa obstaja, in jo ustvari, če ne obstaja.
if (-not (Test-Path -Path $global:OutputFolderPath)) {
    New-Item -ItemType Directory -Path $global:OutputFolderPath
    Write-Host "Created output directory at $global:OutputFolderPath"
} else {
    Write-Host "Izhodna mapa že obstaja na $global:OutputFolderPath"
}

# Pridobite FSMO vloge za gozd
$forestRoles = Get-ADForest | Select-Object -Property DomainNamingMaster, SchemaMaster

# Pridobite FSMO vloge za domeno
$domainRoles = Get-ADDomain | Select-Object -Property PDCEmulator, RIDMaster, InfrastructureMaster

# Ustvarite prazno tabelo za shranjevanje rezultatov
$fsmoRoles = @()

# Dodajte vloge iz gozda v tabelo
$fsmoRoles += [PSCustomObject]@{
    FSMORole = "Domain Naming Master"
    DomainControllerName = $forestRoles.DomainNamingMaster
}
$fsmoRoles += [PSCustomObject]@{
    FSMORole = "Schema Master"
    DomainControllerName = $forestRoles.SchemaMaster
}

# Dodajte vloge iz domene v tabelo
$fsmoRoles += [PSCustomObject]@{
    FSMORole = "PDC Emulator"
    DomainControllerName = $domainRoles.PDCEmulator
}
$fsmoRoles += [PSCustomObject]@{
    FSMORole = "RID Master"
    DomainControllerName = $domainRoles.RIDMaster
}
$fsmoRoles += [PSCustomObject]@{
    FSMORole = "Infrastructure Master"
    DomainControllerName = $domainRoles.InfrastructureMaster
}

# Izpišite rezultate v tabeli
$fsmoRoles | Format-Table -AutoSize

# Shranite rezultate v CSV datoteko
$fsmoRoles | Export-Csv -Path $global:OutputFilePath -NoTypeInformation -Encoding UTF8

Write-Host "FSMO roles exported to $global:OutputFilePath"