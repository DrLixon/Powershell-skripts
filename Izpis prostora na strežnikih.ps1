<# 
 ********************************************************************
 SKRIPTA ZA ANALIZO PROSTORA NA STREŽNIKIH
 ********************************************************************
 kreirana dne 10.02.2025, dopolnjena s strani uporabnika K.H.

 OPIS: 
 Skripta zajame strežnike iz csv datoteke "ADSrvComputers.csv" shranjene
 na lokaciji "C:\ADD-Reports\Input-Data".  Izvozi podatke zasedenosti
 prostora na strežnikih v obliki GB in %.
 ********************************************************************
#>

Import-Module ActiveDirectory

# Definiraj globalno spremenljivko za pot vhodne mape
$global:InputFolderPath = "C:\ADD-Reports\Input-Data"

# Definiraj globalno spremenljivko za pot izhodne mape
$global:OutputFolderPath = "C:\ADD-Reports"

# Preveri, ali je vhodna mapa ustvarjena, če ni, jo ustvari
if (-not (Test-Path -Path $global:InputFolderPath)) {
    New-Item -ItemType Directory -Path $global:InputFolderPath
}

# Preveri, ali je izhodna mapa ustvarjena, če ni, jo ustvari
if (-not (Test-Path -Path $global:OutputFolderPath)) {
    New-Item -ItemType Directory -Path $global:OutputFolderPath
}

# Definiraj globalno spremenljivko za ime izvozne datoteke z datumom in časom
$global:OutputFileName = "DiskReport_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"

# Preveri, ali CSV datoteka za uvoz obstaja, če ne, prekini in napiši napako
$csvFilePath = "$global:InputFolderPath\ADSrvComputers.csv"
if (-not (Test-Path -Path $csvFilePath)) {
    Write-Host "Napaka: Datoteka $csvFilePath ne obstaja."
    exit
}

# Uvozi CSV datoteko
$Servers = Import-Csv $csvFilePath

# Izpiši imena stolpcev za odpravljanje napak
Write-Host "Stolpci v CSV datoteki: $($Servers[0].PSObject.Properties.Name -join ', ')"

# Preveri, ali stolpec 'Hostname' obstaja
if (-not $Servers[0].PSObject.Properties.Match("Hostname")) {
    Write-Host "Napaka: Stolpec 'Hostname' ne obstaja v CSV datoteki."
    exit
}

# Inicializiraj vrstico napredka
$totalServers = $Servers.Count
$currentServer = 0

# Iteriraj skozi vsak sistem
$DiskReport = ForEach ($Server in $Servers) {
    $currentServer++
    $percentComplete = ($currentServer / $totalServers) * 100
    Write-Progress -Activity "Generiranje poročila o diskih" -Status "Obdelava $currentServer od $totalServers" -PercentComplete $percentComplete

    # Izpiši celoten objekt za odpravljanje napak
    Write-Host "Obdelava strežnika: $($Server | Out-String)"

    # Pridobi sistem
    $hostname = $Server.'Hostname'
    $System = Get-ADComputer -Filter { Name -eq $hostname } -ErrorAction SilentlyContinue
    if ($null -eq $System) {
        Write-Host "Napaka: Računalnik $hostname ne obstaja v Active Directory."
        continue
    }

    Get-CimInstance win32_logicaldisk `
        -ComputerName $System.DNSHostName -Filter "Drivetype=3" `
        -ErrorAction SilentlyContinue
}

# Ustvari poročilo o diskih
$DiskReport | Select-Object `
@{Label = "HostName"; Expression = { $_.SystemName } },
@{Label = "DriveLetter"; Expression = { $_.DeviceID } },
@{Label = "DriveName"; Expression = { $_.VolumeName } },
@{Label = "Total Capacity (GB)"; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } },
@{Label = "Free Space (GB)"; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb ) } },
@{Label = 'Free Space (%)'; Expression = { "{0:P0}" -f ($_.Freespace / $_.Size) } } |

# Izvozi poročilo v CSV datoteko z UTF-8 kodiranjem
Export-Csv -Path "$global:OutputFolderPath\$global:OutputFileName" -Encoding UTF8 -NoTypeInformation -Delimiter ";"

Write-Host "Poročilo o diskih je bilo izvoženo v $global:OutputFolderPath\$global:OutputFileName"