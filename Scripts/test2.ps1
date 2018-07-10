$Report = @()

$hosts = Get-VMHost 

foreach ($host in $hosts) {
Name = Get-VMHost | Select Name
Version = Get-VMHost | Select Version
Build = Get-VMHost | select Build
NetworkInfo = Get-VMHost | Select NetworkInfo
Model = Get-VMHost | Select Model
Datastore = @{N="DataCenter";E={Get-Datacenter -VMHost (Get-VMHost $_.Name)}}
Cluster = @{N="Cluster";E={Get-Cluster -VMHost (Get-VMHost $_.Name)}}
HostName = Get-VMHost | Get-VMHostNetwork | Select HostName
VMHost =  Get-VMHost | Get-VMHostNetwork | Select VMHost
DNSAddress =  Get-VMHost | Get-VMHostNetwork | Select DNSAddress
 }
 
 $Report += New-Object psobject -
 $hostInfo | Export-Csv C:\Posh\FULLTEST.csv 