#Usage
#Update the variables section below by specifying:
# 1. Target vCenter Servers systems
# 2. Name of the Runecast role
#
# After that save and execute the script
#
###Variables###
#List vCenter Servers
$vCenters = @(
"vc1.company.local"
"vc2.company.local"
)
$runecastRoleName = "RunecastRole"
###End of variables section

#Get Credentials
#Assuming same credentials are valid across all vCenter Servers
$creds = Get-Credential

#####Do not edit beyond here#####
#Runecast role definition as per the user guide
$privileges = @(
    "Global.Settings"
    "Host.Config.NetService"
    "Host.Config.AdvancedConfig"
    "Host.Config.Settings"
    "Host.Config.Firmware"
    "Host.Cim.CimInteraction"
    "VirtualMachine.Config.AdvancedConfig"
    "Extension.Register"
    "Extension.Update"
    "Profile.View"
    "Profile.Edit"
)
#End of Runecast role definition

foreach ($vc in $vCenters) {
    #Connect to vCenter
    Write-Host "Connecting to vCenter $vc"
    $vcConnection = Connect-VIServer -Server $vc -Credential $creds

    if ($vcConnection) {
        $rcRole = $null
        Write-Host "Creating new role: $runecastRoleName"
        $rcRole = New-VIRole -Name $runecastRoleName -Privilege (Get-VIPrivilege -id $privileges -Server $vc) -Server $vc -ErrorAction SilentlyContinue
        if ($rcRole) {
            Write-Host "$runecastRoleName role created succesfully on vCenter $vc" -ForegroundColor Green
        } else {
            Write-Host "Error while creating $runecastRoleName role on vCenter $vc" -ForegroundColor Red
            Write-Host "$($Error[0].Exception.Message)" -ForegroundColor Red
        }

        #Disconnect from vCenter
        Write-Host "Disconnecting from vCenter $vc"
        Disconnect-VIServer $vcConnection -Confirm:$false
    } else {
        Write-Host "Unable to connect to vCenter $vc" -ForegroundColor Red
    }  
}
