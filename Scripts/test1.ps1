Get-Datacenter | ForEach-Object {
    $esxData = $_

    $_ | ForEach-Object {
        Datastore = 
        $cluster = Get-Cluster
        $cluster | ForEach-Object {
            $esxHost = Get-VMHost
            $esxHost | ForEach-Object {





    
    $esxHost = $_ | Get-Cluster | Get-VMHost
    $esxNet = Get-VMHostNetwork $esxHost 

    New-Object -TypeName PSObject -Property @{
        Name = $esxHost.Name
        Version = $esxHost.Version
        Build = $esxHost.Build
        NetInfo = $esxHost.NetworkInfo
        Model = $esxHost.Model
        DataSTore = 
        }
    }


