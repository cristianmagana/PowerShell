<#
Name: Get-OOBMIP.ps1
Date: June 15th, 2018
Created by: Michael Albert, modified by Erick Sevilla - 
            https://linkedin.com/in/ericksevilla/
            https://tech.mavericksevmont.com/blog/get-servers-oobm-ip-ilo-idrac-irmc-etc-remotely-with-powershell
            This is a mod of Michael Albert's script: http://michlstechblog.info/blog/windows-read-the-ip-address-of-a-bmc-board/

Purpose:    Get IP, MAC and Subnet addresses from OOBM devices such as HP iLO's, Dell iDRAC's or Fujitsu's iRMC, 
            IBM's IMM etc.from a list of remote servers

Instructions:  1) From PowerShell as Admin, cd to script's path and run Get-OOBMIP.ps1 
               2) A .txt file will prompt, enter a list of hosts, IP's or FQDN's or remote machines
               3) Find results in console and csv file report
#>

 $ErrorActionPreference = "SilentlyContinue" # Don't use this, it's bad practice :) -- Remove to debug
 $Timestamp = (Get-Date -f yyyy-MM-dd-hhmmss) # Current DateTime for logs
 $SourceFile = "$PSScriptRoot\Serverlist.txt" # Server list source, currently set as script's location
 $DestinationFile =  "$PSScriptRoot\Results_Get-OOBMIP_$Timestamp.csv" # Report file export name and location, currently set as script's location
 
 Write-Output "Replace this text with list of hosts you want to query, save and close..."| Out-File -FilePath $SourceFile -Encoding ASCII
 Start-Process $SourceFile -Wait # Propmts hosts.txt for user to populate with list of hosts
 Write-Host @("`r`nRunning Get-OOBMIP script...") -NoNewline -ForegroundColor Cyan -BackgroundColor Black

# OOBM Query function
function GetOOBMData {
    [cmdletbinding()]
    Param($Server)

    $oIPMI=Get-WmiObject -Namespace root\WMI -Class MICROSOFT_IPMI -ComputerName $Server
    [byte]$BMCResponderAddress = 0x20
    [byte]$GetLANInfoCmd = 0x02
    [byte]$GetChannelInfoCmd = 0x42
    [byte]$SetSystemInfoCmd = 0x58
    [byte]$GetSystemInfoCmd = 0x59
    [byte]$DefaultLUN = 0x00
    [byte]$IPMBProtocolType = 0x01
    [byte]$8023LANMediumType = 0x04
    [byte]$MaxChannel = 0x0b
    [byte]$EncodingAscii = 0x00
    [byte]$MaxSysInfoDataSize = 19

    [byte[]]$RequestData=@(0)
    $oMethodParameter=$oIPMI.GetMethodParameters("RequestResponse")
    $oMethodParameter.Command=$GetChannelInfoCmd
    $oMethodParameter.Lun=$DefaultLUN
    $oMethodParameter.NetworkFunction=0x06
    $oMethodParameter.RequestData=$RequestData
    $oMethodParameter.RequestDataSize=$RequestData.length
    $oMethodParameter.ResponderAddress=$BMCResponderAddress
    $RequestData=@(0)
    [Int16]$iLanChannel=0
    [bool]$bFoundLAN=$false

                                        for(;$iLanChannel -le $MaxChannel;$iLanChannel++){
	$RequestData=@($iLanChannel)
	$oMethodParameter.RequestData=$RequestData
	$oMethodParameter.RequestDataSize=$RequestData.length
	$oRet=$oIPMI.PSBase.InvokeMethod("RequestResponse",$oMethodParameter,(New-Object System.Management.InvokeMethodOptions))
	#$oRet
	if($oRet.ResponseData[2] -eq $8023LANMediumType){
		$bFoundLAN=$true
		break;
	}
    }


    $oMethodParameter.Command=$GetLANInfoCmd
    $oMethodParameter.NetworkFunction=0x0c
    if($bFoundLAN){
	    $RequestData=@($iLanChannel,3,0,0)
	    $oMethodParameter.RequestData=$RequestData
	    $oMethodParameter.RequestDataSize=$RequestData.length
	    $oRet=$oIPMI.PSBase.InvokeMethod("RequestResponse",$oMethodParameter,(New-Object System.Management.InvokeMethodOptions))

    $OOBIP = (""+$oRet.ResponseData[2]+"."+$oRet.ResponseData[3]+"."+$oRet.ResponseData[4]+"."+$oRet.ResponseData[5] )

	    $RequestData=@($iLanChannel,6,0,0)
	    $oMethodParameter.RequestData=$RequestData
	    $oMethodParameter.RequestDataSize=$RequestData.length
	    $oRet=$oIPMI.PSBase.InvokeMethod("RequestResponse",$oMethodParameter,(New-Object System.Management.InvokeMethodOptions))
    $OOBSubnet = (""+$oRet.ResponseData[2]+"."+$oRet.ResponseData[3]+"."+$oRet.ResponseData[4]+"."+$oRet.ResponseData[5] )
	    $RequestData=@($iLanChannel,5,0,0)
	    $oMethodParameter.RequestData=$RequestData
	    $oMethodParameter.RequestDataSize=$RequestData.length
	    $oRet=$oIPMI.PSBase.InvokeMethod("RequestResponse",$oMethodParameter,(New-Object System.Management.InvokeMethodOptions))
    $OOBMACAddress = (("{0:x2}:{1:x2}:{2:x2}:{3:x2}:{4:x2}:{5:x2}" -f $oRet.ResponseData[2],$oRet.ResponseData[3],$oRet.ResponseData[4],$oRet.ResponseData[5],$oRet.ResponseData[6],$oRet.ResponseData[7]))
    $Status='SUCCESS'
    $Message = ''
    New-Object PSObject -Property @{Hostname=$Server;Status=$Status;OOBIP=$OOBIP;OOBMACAddress=$OOBMACAddress;OOBSubnet=$OOBSubnet;Message=$Message}
}
     
     }

# Function processing: Foreach Loop, progress bar and try-catch, all in a tasty wrap     
$Wrapper = @(

     $Servers = Get-Content $SourceFile
     $i = 0;$CountDuckula = @($Servers).Count

     foreach ($Server in $Servers) {
     $i++;[int]$Percentage = (($i/$CountDuckula)*100)
     Write-Progress -Activity "Get-OOBM Tool: Querying $Server" -Status "Completed $i of $CountDuckula - $Percentage%" -PercentComplete $Percentage

     try { GetOOBMData -Server $Server -ErrorAction Stop } catch {
                                         $Message=$($PSItem.ToString())
                                         $Status='FAIL'
                                         New-Object PSObject -Property @{
                                         Hostname=$Server;
                                         Status=$Status;
                                         OOBIP=$OOBIP;
                                         OOBMACAddress=$OOBMACAddress;
                                         OOBSubnet=$OOBSubnet;
                                         Message=$Message                }
                                         $OOBIP='';$OOBMACAddress='';$OOBSubnet='';$Message=$($PSItem.ToString())}
         
                                        }
                )

# Processing wrapped results for output
$Wrapper | Select-Object Hostname,Status,OOBIP,OOBMACAddress,OOBSubnet,Message | 
Export-Csv -Path $DestinationFile -Append -NoTypeInformation -Force # Output to csv file

Write-Host " Done!" -ForegroundColor Green -BackgroundColor Black # One puppy a day keeps the questions away
Write-Host "Path to report: " -ForegroundColor Cyan -BackgroundColor Black -NoNewline # In case you are wondering the file's name and location
Write-Host "$DestinationFile" -BackgroundColor Black # More write-host 'cause we hate puppies
$Wrapper | Format-Table Hostname,Status,OOBIP,OOBMACAddress,OOBSubnet,Message # Output to console because we are Homo videns

start $PSScriptRoot # Opening folder where the report is located for your convenience
