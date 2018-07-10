﻿Param (
    [Alias("Host")]
    [string]$VIServer = "cfscavmware.cucsi.org",
    [string]$Admin = "CO-OP\jiadmin"
)

if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
. “C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1”
}

$serverList = ("cfstxvcsa.cucsi.org")
#$serverList = ("cfscavmware.cucsi.org","cusc-vcenter01.creditunion.net","sfld-vmware.servicecenters.org","cfsdrvcsa.cucsi.org",""cfstxvcsa.cucsi.org","192.168.36.140")
$filePath = Split-Path $MyInvocation.MyCommand.Path
$fileName = "\LicenseReport.csv"
$fullName = $filePath + $fileName

$vSphereLicInfo = @()
#$Details = "" |Select VC, Name, Key, Total, Used, ExpirationDate , Information

Foreach($server in $serverList) {

Write-Host "Connecting to $server"

    Try {
        $Conn = Connect-VIServer $server
    }
    Catch {
        Throw "Error connecting to $server because ""$($Error[1])"""
    }

    # Get the license info from each VC in turn 
    #$vSphereLicInfo = @() 
    $ServiceInstance = Get-View ServiceInstance 
    Foreach ($LicenseMan in Get-View ($ServiceInstance | Select -First 1).Content.LicenseManager) { 
        Foreach ($License in ($LicenseMan | Select -ExpandProperty Licenses)) { 
            $Details = "" |Select VC, Name, Key, Total, Used, ExpirationDate , Information 
            $Details.VC = ([Uri]$LicenseMan.Client.ServiceUrl).Host 
            $Details.Name= $License.Name 
            $Details.Key= $License.LicenseKey 
            $Details.Total= $License.Total 
            $Details.Used= $License.Used 
            $Details.Information= $License.Labels | Select -expand Value 
            $Details.ExpirationDate = $License.Properties | Where { $_.key -eq "expirationDate" } | Select -ExpandProperty Value 
            $vSphereLicInfo += $Details 
        } 
    } 
    }
#$vSphereLicInfo | Format-Table -AutoSize
$vSphereLicInfo | ConvertTo-Csv | Out-File $fullName

(Get-Content $fullName | Select-Object -Skip 1) | Set-Content $fullName

@("sep=,") +  (Get-Content $fullName) | Set-Content $fullName
