# Date: 06/13/2018
# Title: CUCSi.org Virtual Infrastructure Snapshot Inventory (-3.5 Days)
# By: Cristian Magana
# Version: 1.0

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


# Retrieves All Snapshots In All Cucsi.org Virtual Infrastructures.
"`n"
Write-Host "Collecting and Sorting Snapshots.." -ForegroundColor Green
Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-3.5)} | Select-Object VM,Name,Created,@{N="SizeGB";E={[math]::Round($_.SizeGB,2)}} | Sort Created | FT 

#Get-VM | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-7)} | Select-Object VM,Name,Created,@{N="SizeGB";E={[math]::Round($_.SizeGB,2)}} | Sort Created | Export-CSV C:\Users\##YOUR USER ID##\Desktop\Snapshots.CSV




 