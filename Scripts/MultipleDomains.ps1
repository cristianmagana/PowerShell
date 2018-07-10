$domains = "172.16.1.60","10.50.0.24", "10.160.2.244", "10.50.0.23", "192.168.35.12"

foreach ($domain in $domains) 

{Get-ADDomain -Server $domain}