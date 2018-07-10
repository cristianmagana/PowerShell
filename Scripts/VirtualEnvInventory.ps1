﻿##########################################################################
 # 
 # Get-VMwareVMList
 # SAM Gold Toolkit
 # Original Source: Jon Mulligan (Sam360)
 #
 ##########################################################################

 <#
.SYNOPSIS
Retrieves physical host and virtual machine data from a VMware vSphere or vCenter server
.DESCRIPTION
The Get-VMwareVMList script queries a single vSphere or vCenter server and produces a CSV file
including virtual machine and physical host details. The file (VMwareData.csv) contains one 
record per virtual machine. Data collected includes
	VM Name
	VM CPU, Memory & Network details
	Physical Host Name
	Physical Host CPU, Memory, Network, Cluster & vMotion details
If a vCenter server is queried, details for all VMs in the farm are retrieved.
.PARAMETER Server 
Host name of vSphere or vCenter server to scan
.PARAMETER Username
VMware Username (Required)
e.g. root (for vSphere server i.e. local account)
     jon.mulligan (for vCenter server i.e. Windows domain account)
.PARAMETER Password
VMware Password (Required)
.EXAMPLE
Get all guest & host info from from the farm managed by the vSphere server 'Reliant'. 
Get-VMwareVMList –VMserver Reliant
#>

Param(
	[switch]$TestCredentials,
	[alias("o1")]
    $OutputFile1 = "VMwareData.csv",
	[alias("username")]
	$VMwareUsername,
	[alias("password")]
	$VMwarePassword,
	[alias("server")]
	$VMserver,
	[alias("log")]
	[string] $LogFile = "VMLogFile.txt",
	[switch]
	$Verbose)

 function InitialiseLogFile {
	if ($LogFile -and (Test-Path $LogFile)) {
		Remove-Item $LogFile
	}
}

function LogText {
	param(
		[Parameter(Position=0, ValueFromRemainingArguments=$true, ValueFromPipeline=$true)]
		[Object] $Object,
		[System.ConsoleColor]$color = [System.Console]::ForegroundColor,
		[switch]$noNewLine = $false 
	)

	# Display text on screen
	Write-Host -Object $Object -ForegroundColor $color -NoNewline:$noNewLine

	if ($LogFile) {
		$Object | Out-File $LogFile -Encoding utf8 -Append 
	}
}

function LogError([string[]]$errorDescription){
	if ($Verbose){
		LogText ""
	}

	$output = Get-Date -Format HH:mm:ss.ff
	$output += " - "
	$output += $errorDescription -join "`r`n              "
	LogText $output -Color Red
	Start-Sleep -s 3
}

function LogLastException() {
    $currentException = $Error[0].Exception;

    while ($currentException)
    {
        LogText -Color Red $currentException
        LogText -Color Red $currentException.Data
        LogText -Color Red $currentException.HelpLink
        LogText -Color Red $currentException.HResult
        LogText -Color Red $currentException.Message
        LogText -Color Red $currentException.Source
        LogText -Color Red $currentException.StackTrace
        LogText -Color Red $currentException.TargetSite

        $currentException = $currentException.InnerException
    }

	Start-Sleep -s 3
}

function LogProgress($progressDescription){
	if ($Verbose){
		LogText ""
	}

	$output = Get-Date -Format HH:mm:ss.ff
	$output += " - "
	$output += $progressDescription
	LogText $output -Color Green
}
                                                                          
function LogEnvironmentDetails {
	LogText -Color Gray "   _____         __  __    _____       _     _   _______          _ _    _ _   "
	LogText -Color Gray "  / ____|  /\   |  \/  |  / ____|     | |   | | |__   __|        | | |  (_) |  "
	LogText -Color Gray " | (___   /  \  | \  / | | |  __  ___ | | __| |    | | ___   ___ | | | ___| |_ "
	LogText -Color Gray "  \___ \ / /\ \ | |\/| | | | |_ |/ _ \| |/ _`` |    | |/ _ \ / _ \| | |/ / | __|"
	LogText -Color Gray "  ____) / ____ \| |  | | | |__| | (_) | | (_| |    | | (_) | (_) | |   <| | |_ "
	LogText -Color Gray " |_____/_/    \_\_|  |_|  \_____|\___/|_|\__,_|    |_|\___/ \___/|_|_|\_\_|\__|"
	LogText -Color Gray " "
	LogText -Color Gray " Get-VMwareVMList.ps1"
	LogText -Color Gray " "

	$OSDetails = Get-WmiObject Win32_OperatingSystem
	LogText -Color Gray "Computer Name:        $($env:COMPUTERNAME)"
	LogText -Color Gray "User Name:            $($env:USERNAME)@$($env:USERDNSDOMAIN)"
	LogText -Color Gray "Windows Version:      $($OSDetails.Caption)($($OSDetails.Version))"
	LogText -Color Gray "PowerShell Host:      $($host.Version.Major)"
	LogText -Color Gray "PowerShell Version:   $($PSVersionTable.PSVersion)"
	LogText -Color Gray "PowerShell Word size: $($([IntPtr]::size) * 8) bit"
	LogText -Color Gray "CLR Version:          $($PSVersionTable.CLRVersion)"
	LogText -Color Gray "Current Date Time:    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
	LogText -Color Gray "Username Parameter:   $VMwareUsername"
	LogText -Color Gray "Server Parameter:     $VMserver"
	LogText -Color Gray "Output File 1:        $OutputFile1"
	LogText -Color Gray "Log File:             $LogFile"
	LogText -Color Gray ""
}

function Get-VMwareVMList
{
	try
	{
		InitialiseLogFile
		LogEnvironmentDetails

		LogProgress "Importing modules"
		$allSnapIns = get-pssnapin -registered | sort -Descending
		foreach ($snapIn in $allSnapIns){
			if (($snapIn.name -eq 'VMware.DeployAutomation') -or
				($snapIn.name -eq 'VMware.ImageBuilder') -or
				($snapIn.name -eq 'VMware.VimAutomation.Core') -or
				($snapIn.name -eq 'VMware.VimAutomation.License') -or
				($snapIn.name -eq 'VMware.VimAutomation.Vds')){
				LogText "Adding SnapIn: $($snapIn.Name)"
				add-PSSnapin -Name $snapIn.name
			}
		}

		if (!(EnvironmentConfigured))
		{
			LogError("VMware PowerShell modules could not be loaded", 
				"Please ensure that VMware PowerCLI module is installed on this computer",
			    "https://www.vmware.com/support/developer/PowerCLI/")
			
			return
		}

		if (!($VMserver))
		{
			$strPrompt = "VMware host or vCenter Name (Default [$($env:computerName)])"
			$VMserver = @( 
                    "192.168.36.140"         
                 );

			if (!($VMserver))
			{
				$VMserver = $env:computerName
			}
		}

		if(!($VMwareUsername -and $VMwarePassword)){
			LogText "VMware Credentials Required"
			$creds = Get-Credential
			if (!($creds)) {
				LogError("Missing Parameter: Username and Password must be specified")
				return
			}
			$VMwareUsername = $creds.GetNetworkCredential().Username
			$VMwarePassword = $creds.GetNetworkCredential().Password
		}
	}
	catch 
	{
		LogLastException
        return
	}
    
    try
    {
		# Connect to the VMware server
        LogProgress "Connecting to VMware server"
        $viServer = Connect-VIServer -Server $VMServer -User $VMwareUsername -Password $VMwarePassword
		
		if($viServer){
			LogProgress "Connected to VMware server"
		}
		else {
			Throw "VMware logon failed"
		}
    }
    catch
    {
        LogLastException
        return
    }
	
	if ($TestCredentials)
	{
		# We're only testing credentials
		return
	}

    # Get the VM Data
    try
    {
        LogProgress "Getting VM Info"

        $VmInfo = ForEach ($Datacenter in (Get-Datacenter | Sort-Object -Property Name)) {
            ForEach ($VM in ($Datacenter | Get-VM | Sort-Object -Property Name)) {
                
                $IPAddresses = "";
                $MACAddresses = "";
                $NetworkNames = "";
                foreach ($NIC in $VM.Guest.Nics) {
                    $IPAddresses += $NIC.IPAddress -join ','
                    $MACAddresses += $NIC.MacAddress
                    $NetworkNames += $NIC.NetworkName
                
                    $IPAddresses += ','
                    $MACAddresses += ','
                    $NetworkNames += ','
                }
                
                "" | Select-Object -Property @{N="VM";E={$VM.Name}},
                @{N="PowerState";E={$VM.PowerState}},
                @{N="Version";E={$VM.Version}},
                @{N="Maintenance Window";E={ ($VM | Get-Annotation -CustomAttribute "Maintenance Window").Value}},
                @{N="Notes";E={$VM.Notes}},
                @{N="MemoryMB";E={$VM.MemoryMB}},
                @{N="GuestIP";E={$VM.ExtensionData.Summary.Guest.IpAddress}},
                @{N="IPs";E={$IPAddresses}},
                @{N="MACs";E={$MACAddresses}},
                @{N="NetworkNames";E={$NetworkNames}},
                @{N="OS";E={$VM.Guest.OSFullName}},
                @{N="FQDN";E={$VM.Guest.HostName}},
                @{N="Datacenter";E={$Datacenter.name}},
                @{N="Cluster";E={$vm.VMHost.Parent.Name}},
                @{N="HostName1";E={$vm.VMHost.Name}},
                @{N="HostName2";E={$VM.VMHost.NetworkInfo.HostName}},
                @{N="HostDomainName";E={$VM.VMHost.NetworkInfo.DomainName}},
                @{N="HostVendor";E={$VM.VMHost.ExtensionData.Hardware.SystemInfo.Vendor}},
                @{N="HostModel";E={$VM.VMHost.ExtensionData.Hardware.SystemInfo.Model}},
                @{N="HostRAM";E={$VM.VMHost.ExtensionData.Summary.Hardware.MemorySize}},
                @{N="HostProductName";E={$VM.VMHost.ExtensionData.Summary.Config.Product.Name}},
                @{N="HostProductVersion";E={$VM.VMHost.ExtensionData.Summary.Config.Product.Version}},
                @{N="HostProductBuild";E={$VM.VMHost.ExtensionData.Summary.Config.Product.Build}},
                @{N="HostProductLicenseKey";E={$VM.VMHost.LicenseKey}},
                @{N="HostProductLicenseName";E={$VM.VMHost.ExtensionData.Summary.Config.Product.LicenseProductName}},
                @{N="HostProductLicense Version";E={$VM.VMHost.ExtensionData.Summary.Config.Product.LicenseProductVersion}},
                @{N="HostvMotionEnabled";E={$vm.VMHost.ExtensionData.Summary.Config.VmotionEnabled}},
                @{N="HostvMotionIPAddress";E={$VM.VMHost.ExtensionData.Config.vMotion.IPConfig.IpAddress}},
                @{N="HostvMotionSubnetMask";E={$VM.VMHost.ExtensionData.Config.vMotion.IPConfig.SubnetMask}} 

                 
            }
          }
        $VmInfo | Export-Csv -NoTypeInformation -Path $OutputFile1

		LogProgress "All VM data exported"
    }
    catch
    {
        LogLastException
    }
}

function EnvironmentConfigured {
	if (Get-Command "Connect-VIServer" -errorAction SilentlyContinue){
		return $true}
	else {
		return $false}
}

Get-VMwareVMList