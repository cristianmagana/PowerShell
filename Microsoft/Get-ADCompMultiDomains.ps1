$ADs = "DC1","DC2", "DC3", "DC4" 

foreach ($AD in $ADs) {

    $Comps = Get-ADComputer -Filter * -Properties * -Server $AD -Credentials CO-OP\user | Select-Object Name,DNSHostName,OperatingSystem,IPv4Address,LastLogonDate | Sort OperatingSystem,LastLogonDate,DNSHostName

    $Report += $Comps
}

$Report | Export-CSV C:\Users\%user%\Desktop\ADReport.csv

