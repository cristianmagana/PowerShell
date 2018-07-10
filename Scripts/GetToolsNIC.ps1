New-VIProperty -ObjectType VirtualMachine -Name ToolsVersion -ValueFromExtensionProperty ‘Guest.ToolsVersion’
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus'
Get-VM | Select Name,Version,ToolsVersion,ToolsVersionStatus, PowerState | Export-csv C:\Users\cristianm\Desktop\RANCHO.CSV
Get-VM | Get-NetworkAdapter | Export-csv C:\Users\cristianm\Desktop\DULUTHNICS.CSV