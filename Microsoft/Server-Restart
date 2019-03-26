#####################################################################
# The following actions performed by this script
# 1. Get the list of servers from txt file located at c:\foo on your local PC
# 2. Ping the server to check the server is online
# 3. Get the list of services prior to reboot
# 4. Perform reboot on the server in 10 seconds with the comments
# 5. Perform continues ping to the server to verify the server availability after reboot
# 6. Get the list of services after the reboot
# 7. Compare the service status before and after the reboot
# 8. Wait for user to press enter to proceed with next server from the list
###########################################################

cls

$servers = Get-content c:\foo\server.txt

Foreach($server in $servers)

{

ping $server

$before = Get-Service -ComputerName $server

Write-host Restarting $server -ForegroundColor Green

shutdown /m \\$server /r /t 10 /c "Test Restart Script"

ping $server -n 50

$after = Get-Service -ComputerName $server

diff $before $after -Property Name, Status

Read-Host 'Press Enter to continue...' | Out-Null

}
