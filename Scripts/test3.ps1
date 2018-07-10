# Stores All CUCSI.ORG VCSAs In An Array
$vCSA = @( 
    "CFSCAVMWARE.CUCSI.ORG", 
    "CFSDRVCSA.CUCSI.ORG", 
    "CFSGAVCSA.CUCSI.ORG",
    "CFSTXVCSA.CUCSI.ORG", 
    "CFSMIVCSA.CUCSI.ORG"
);

# Securely Pass Credentials Over The Network.
$Credentials = Get-Credential

# Establishes Connection To VCSAs.
clear
Write-Host "Connecting To All CUCSi vCenters.." -ForegroundColor Green
Connect-VIServer -Server $vCSA -Credential $Credentials

Get-VMHost -Server $vCSA | Select-Object Name,NetworkInfo,Model,Version,Build,Parent | Export-CSV C:\Posh\HostInfo.csv
Get-VMHost -Server $vCSA | Get-VMHostNetwork | Select HostName,VMHost, DNSAddress |Export-CSV C:\Posh\networkinfo.csv