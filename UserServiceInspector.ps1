<# 
 ********************************************************************
 USER SERVICE INSPECTOR SCRIPT
 ********************************************************************
 kreirana dne 10.02.2025, s strani uporabnika K.H.

 OPIS: 
 Skripta zajame vse aktivne servise na izbranih strežnikih in prikaže,
 kateri uporabniki so povezani z določenimi servisi.
 ********************************************************************
#>

# Definiraj globalno spremenljivko za ime izvozne datoteke z datumom in časom
$global:OutputFileName = "UserServiceInspector_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"
$global:ErrorFileName = "UserServiceInspector-ServerErrors_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"
$global:OutputFolderPath = "C:\ADD-Reports"
$global:ServersCsvPath = "C:\ADD-Reports\ServerList.csv"  # Pot do CSV datoteke z imeni strežnikov

# Preveri, ali izhodna mapa obstaja, in jo ustvari, če ne obstaja.
if (-not (Test-Path -Path $global:OutputFolderPath)) {
    New-Item -ItemType Directory -Path $global:OutputFolderPath
    Write-Host "Created output directory at $global:OutputFolderPath"
} else {
    Write-Host "Izhodna mapa že obstaja na $global:OutputFolderPath"
}

# Uvozi seznam strežnikov iz CSV datoteke
$servers = Import-Csv -Path $global:ServersCsvPath

# Ustvari prazno tabelo za shranjevanje rezultatov
$results = @()
$errorResults = @()
$totalServers = $servers.Count
$successfulServers = 0

# Iteriraj skozi vsak strežnik
foreach ($server in $servers) {
    Write-Host "Obdelujem strežnik: $($server.HostName)"
    try {
        # Izvedi ukaz na oddaljenem strežniku za pridobitev storitev in uporabnikov
        $services = Invoke-Command -ComputerName $server.HostName -ScriptBlock {
            Get-WmiObject Win32_Service | Select-Object Name, StartName
        }
        
        # Dodaj ime strežnika k vsakemu rezultatu
        foreach ($service in $services) {
            $results += [PSCustomObject]@{
                ServerName = $server.HostName
                ServiceName = $service.Name
                UserName = $service.StartName
            }
        }
        Write-Host -ForegroundColor Green "Strežnik $($server.HostName) obdelan uspešno."
        $successfulServers++
    } catch {
        if ($_.Exception.Message -like "*The server name or address could not be resolved*" -or 
            $_.Exception.Message -like "*The WinRM client cannot process the request because the server name cannot be resolved*") {
            Write-Host "Napaka pri dostopu do strežnika $($server.HostName): The server name cannot be resolved. Preskakujem..."
            $errorResults += [PSCustomObject]@{
                ServerName = $server.HostName
                Status = "neobdelano"
            }
        } else {
            Write-Host -ForegroundColor Red "Napaka pri dostopu do strežnika $($server.HostName): $_"
            $errorResults += [PSCustomObject]@{
                ServerName = $server.HostName
                Status = "neobdelano"
            }
        }
    }
}

# Izračunaj procentualni uspeh obdelave
$successRate = ($successfulServers / $totalServers) * 100
Write-Host "Procentualni uspeh obdelave: $successRate%"

# Izvozi rezultate v CSV datoteko
$results | Export-Csv -Path "$global:OutputFolderPath\$global:OutputFileName" -NoTypeInformation -Encoding UTF8

# Izvozi napake v ločeno CSV datoteko
$errorResults | Export-Csv -Path "$global:OutputFolderPath\$global:ErrorFileName" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Rezultati so bili izvoženi v $global:OutputFolderPath\$global:OutputFileName"
Write-Host "Napake so bile izvožene v $global:OutputFolderPath\$global:ErrorFileName"
Write-Host ""
Write-Host "Procentualni uspeh obdelave: $successRate%"
