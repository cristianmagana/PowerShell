function renameLocalAdmin() {
    #function variables
    $chgPWD = $false


    # Renames the Local Administrator
    Write-Host "Renaming The Local Administrator" -ForegroundColor Green
    $NewUser = Read-Host "Enter the New User Name"
    $admin=[adsi]"WinNT://./Administrator,user"
    $admin.psbase.rename($NewUser)
    # Enables & Sets User Password
   
   <#
    Write-Host "Updating" $NewUsers " Password" -ForegroundColor Green
    while ($chgPWD -eq $false) {
        $newPWD = Read-Host "Enter the new password" -AsSecureString
        $confirmPWD = Read-Host "Confirm the new password" -AsSecureString
        if($newPWD -eq $confirmPWD) {
            ([adsi]"WinNT://./$NewUser").SetPassword($confirmPWD)
            $chgPWD -eq $true
            exit
           }
        else{
            Write-Error "Entered passwords are not same"
            }
    }
    #>

}

function disableNetBios () {
    
    Write-Host ("Disabling NetBIOS by updating the Regsitry") -ForegroundColor Green
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"

    Get-ChildItem $key | ForEach {
    
        Set-ItemProperty -Path "$key\$($_.pschildname)" -Name NetBiosOptions -Value 2
        $NetbiosOptions_Value = (Get-ItemProperty "$key\$($_.pschildname)").NetbiosOptions
        Write-Host("Netbios Options updated value is $NetbiosOptions_Value")
    }

    Write-Host("NetBIOS is now disabled")
}


function disableIPV6 () {

    Write-Host "Disabling IPv6 on the System" -ForegroundColor Green
    # Disables IPv6 on all Network Adapters (Unchecks the Box)
    Write-Host "Listing Network Adapters" -ForegroundColor Yellow
    Get-NetAdapter | ForEach { Get-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
    Write-Host " "
    Write-Host "Disabling IPV6 on Network Adapters (Unchecking IPv6)" -ForegroundColor Yellow
    Get-NetAdapter | ForEach { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
    Write-Host "Disabled IPV6 on Network Adapters (Unchecked IPv6)" -ForegroundColor Yellow
    Get-NetAdapter | ForEach { Get-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }

    #Disables IPv6 in Registry
    Write-Host "Disabling IPv6 in the Registry" -ForegroundColor Yellow
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -Name DisabledComponents -PropertyType DWord -Value 0xffffffff

    Write-Host "Disabling IPv6 Complete" -ForegroundColor Green
}

function systemPageFile () {
    
}


function disableAutomaticUpdates () {

   # stop-service wuauserv
   # set-service wuauserv –startup disabled
    	
   # get-wmiobject win32_service –filter "name='wuauserv'"
   Write-Host "Disabling Automatic Updates" -ForegroundColor Green
    $service = Get-WmiObject Win32_Service -Filter 'Name="wuauserv"' 
	if ($service)
	{
		if ($service.StartMode -ne "Disabled")
		{
			$result = $service.ChangeStartMode("Disabled").ReturnValue
			if($result)
			{
				"Failed to disable the 'wuauserv' service on $_. The return value was $result."
			}
			else {"Success to disable the 'wuauserv' service on $_."}
			
			if ($service.State -eq "Running")
			{
				$result = $service.StopService().ReturnValue
				if ($result)
				{
					"Failed to stop the 'wuauserv' service on $_. The return value was $result."
				}
				else {"Success to stop the 'wuauserv' service on $_."}
			}
		}
		else {"The 'wuauserv' service on $_ is already disabled."}
	}
	else {"Failed to retrieve the service 'wuauserv' from $_."}
}

function renameServer () {
    Write-Host "Renaming the Server Name" -ForegroundColor Green
    $NewServerName = Read-Host "Enter the Servers New Name"
    Rename-Computer -NewName $NewServerName

}

function enableShadowCopy () {

    Write-Host "Listing out volumes to create shadow copies" -ForegroundColor Green

    Get-Volume | Where-Object {$_.FileSystem -eq "NTFS"}

    Read-Host "Press enter to continue" 

    vssadmin add shadowstorage /for=C: /on=C:  /maxsize=80%

    #Create Shadows
    vssadmin create shadow /for=C:

    #Set Shadow Copy Scheduled Task for C: AM
    $Action=new-scheduledtaskaction -execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=C:"
    $Trigger=new-scheduledtasktrigger -daily -at 6:00AM
    Register-ScheduledTask -TaskName ShadowCopyC_AM -Trigger $Trigger -Action $Action -Description "ShadowCopyC_AM"

    #Set Shadow Copy Scheduled Task for C: PM
    $Action=new-scheduledtaskaction -execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=C:"
    $Trigger=new-scheduledtasktrigger -daily -at 6:00PM
    Register-ScheduledTask -TaskName ShadowCopyC_PM -Trigger $Trigger -Action $Action -Description "ShadowCopyC_PM"

}

function secreenSaveTimeout () {
    Param([int]$value)
    $path = ‘HKCU:\Control Panel\Desktop’
    $name = ‘ScreenSaveTimeOut’

    #To get the ScreenSaveTimeOut value.
    $old_value=(Get-ItemProperty -path $path -name $name).$name
    echo “Old ScreenSaveTimeout: $old_value”

    #To set the new ScreenSaveTimeOut value.
    Set-ItemProperty -Path $path -name $name -value $value

    #To get the new ScreenSaveTimeOut value.
    $new_value=(Get-ItemProperty -path $path -name $name).$name
    echo “New ScreenSaveTimeout: $new_value”

}


function reviewScript() {
    Write-Host "Review and Reboot" -ForegroundColor Green
    Read-Host "Please check for errors"
    Read-Host "Press Enter to reboot"
    Restart-Computer

}


enableShadowCopy
Write-Host " " 
disableAutomaticUpdates
Write-Host " " 
disableIPV6
Write-Host " " 
renameLocalAdmin
Write-Host " " 
renameServer
Write-Host " " 
disableNetBios
Write-Host " " 
reviewScript



