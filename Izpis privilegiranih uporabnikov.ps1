<# 
 ********************************************************************
 IZPIS PRIVILEGIRANIH UPORABNIKOV V SISTEMU
 ********************************************************************
 kreirana dne 10.02.2025, s strani uporabnika K.H.

 OPIS: 
 Skripta izpiše vse priviligirane uporabnike.

 Tipi priviligiranih uporabnikov:
    - "Domain Admins",
    - "Enterprise Admins" in
    - "Schema Admins".
 ********************************************************************
#>

# Global variable for output folder location
$global:OutputFolderPath = "C:\ADD-Reports"

# Ensure the output folder exists and create it if it doesn't
if (-not (Test-Path -Path $global:OutputFolderPath)) {
    New-Item -ItemType Directory -Path $global:OutputFolderPath
    Write-Host "Created output directory at $global:OutputFolderPath"
} else {
    Write-Host "Output directory already exists at $global:OutputFolderPath"
}

# Import Active Directory module
Import-Module ActiveDirectory

# Function to export group members to CSV
function Export-GroupMembers {
    param (
        [string]$groupName,
        [string]$outputFileName
    )

    # Get members of the specified group
    $groupMembers = Get-ADGroupMember -Identity $groupName

    # Create an array to store user details
    $userDetails = @()

    # Iterate through each group member
    foreach ($member in $groupMembers) {
        # Check if the member is a user
        if ($member.objectClass -eq "user") {
            # Get user details
            $user = Get-ADUser -Identity $member -Properties Name, SamAccountName, Enabled, PasswordExpired
            # Add user details to the array
            $userDetails += $user
        }
    }

    # Export the user details to a CSV file
    $outputFilePath = "$global:OutputFolderPath\$outputFileName"
    $userDetails | Select-Object Name, SamAccountName, Enabled, PasswordExpired | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8
    Write-Host "$groupName members exported to $outputFilePath"
}

# Export Domain Admins
Export-GroupMembers -groupName "Domain Admins" -outputFileName "DomainAdmins.csv"

# Export Enterprise Admins
Export-GroupMembers -groupName "Enterprise Admins" -outputFileName "EnterpriseAdmins.csv"

# Export Schema Admins
Export-GroupMembers -groupName "Schema Admins" -outputFileName "SchemaAdmins.csv"