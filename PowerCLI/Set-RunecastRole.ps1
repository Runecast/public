<#
.SYNOPSIS
This script helps to set up the VI role required to scan a vCenter by Runecast.

.DESCRIPTION
If not specified otherwise, the role is named 'Runecast'. Optionally when Principal is specified (existing user or group), it will get assigned the role privileges at the vCenter level. 

.PARAMETER Server
One or more vCenters where the roles should be created.

.PARAMETER Credential
Admin credential for the specified vCenter.
This parameter accepts an object that was created by Get-Credential command.

.PARAMETER SkipCertificateCheck
Boolean parameter to ignore the certificate trust when connecting to the specified vCenter, not recommended.

.PARAMETER RoleName
Name of the Runecast role that should be created on the specified vCenter and assigned on the vCenter level.
If not specified, default 'Runecast' will be used.

.PARAMETER Principal
If specified, this principal will be assigned all roles at the top vCenter level.
The user or group must already exist and is passed in the format of 'domain.name\user.name'

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
$Credential = Get-Credential
./Set-RunecastRole.ps1 -Server vcenter1,vcenter2 -Credential $Credential

Description
-----------
Connects seqentially to specified vCenters using given credentials and creates the role 'Runecast'.

.EXAMPLE
$Credential = Get-Credential
./Set-RunecastRole.ps1 -Server vcenter.domain.local `
                       -Credential $Credential `
                       -RoleName 'MyCustomRoleName' `
                       -Principal 'vsphere.local\runecast'

Description
-----------
Connects to the vcenter server 'vcenter.domain.local' using given credentials, creates the role with name 'MyCustomRoleName' and assigns it to existing user 'vsphere.local/runecast' at the vCenter level.

.NOTES
Version    : 18. 12. 2023
Changes    : Initial version
File Name  : Set-RunecastRole.ps1

.LINK
https://github.com/Runecast/public/tree/master/PowerCLI

#>

Param (
    [Parameter(Mandatory)]
    [Object]$Server,
    [Parameter(Mandatory)]
    [PSCredential]$Credential,
    [Switch]$SkipCertificateCheck,
    [String]$RoleName = 'Runecast',
    [String]$Principal
)

function Set-Role {
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Server,
        [Parameter(Mandatory=$True)]
        [String]$Name,
        [Parameter(Mandatory=$True)]
        [Object]$Privilege
    )

    $Role = Get-VIRole -Name $Name -Server $Server -ErrorAction SilentlyContinue
    if ($Role) {
        Write-Host "Role '$Name' already exists" -ForegroundColor Yellow
        Return $Role
    }

    Write-Host "Creating role '$Name'"
    $Role = New-VIRole  -Name $Name `
                        -Privilege (Get-VIPrivilege -Id $Privilege -Server $Server) `
                        -Server $Server `
                        -ErrorAction SilentlyContinue
    if ($Role) {
        Write-Host "Role '$Name' created succesfully on vCenter '$Server'" -ForegroundColor Green
        Return $Role
    } else {
        Write-Host "Error while creating role '$Name' on vCenter '$Server'" -ForegroundColor Red
        Write-Host "$($Error[0].Exception.Message)" -ForegroundColor Red
    }

}

function Set-Privilege {
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Server,
        [Parameter(Mandatory=$True)]
        [String]$Principal,
        [Parameter(Mandatory=$True)]
        [Object]$Role
    )

    $Folder = Get-Folder 'Datacenters' -Type 'Datacenter' -Server "$VCenter"
    $Permission = Get-VIPermission -Entity $Folder -Principal "$Principal" -Server "$Server" -ErrorAction SilentlyContinue
    if ($Permission.role -eq $Role.Name) {
        Write-Host "Permissions for '$Principal' already exist" -ForegroundColor Yellow
        Return        
    }

    Write-Host "Setting permissions for '$Principal'"
    $Permission = New-VIPermission -Role $Role -Entity $Folder -Principal "$Principal" -Propagate:$true -Server "$VCenter" -ErrorAction Continue
    if ($Permission) {
        Write-Host "Successfully set permissions" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to set permissions" -ForegroundColor Red
    }

}

$AnalyzerPrivileges = @(
    "Global.Settings"
    "Host.Cim.CimInteraction"
    "Host.Config.AdvancedConfig"
    "Host.Config.Firmware"
    "Host.Config.NetService"
    "Host.Config.Settings"
    "Extension.Register"
    "Extension.Update"
    "Profile.View"
    "Profile.Edit"
    "VirtualMachine.Config.AdvancedConfig"
)

foreach ($VCenter in $Server) {
    Write-Host "Connecting to vCenter '$VCenter'"
    if ($SkipCertificateCheck) {
        $Connection = Connect-VIServer -Server "$VCenter" -Credential $Credential -Force -ErrorAction SilentlyContinue
    }
    else {
        $Connection = Connect-VIServer -Server "$VCenter" -Credential $Credential -ErrorAction SilentlyContinue
    }

    if (-not $Connection.IsConnected) {
        Write-Host "Unable to connect to vCenter '$VCenter'" -ForegroundColor Red
        Write-Host "$($Error[0].Exception.Message)" -ForegroundColor Red
        return
    }

    # Create Runecast Analyzer role (if not exists)
    $Role = Set-Role -Name "$RoleName" -Server "$VCenter" -Privilege $AnalyzerPrivileges

    # If principal is specified, set its privileges at vCenter root level
    if ($Principal) {
        Set-Privilege -Role $Role -Principal "$Principal" -Server "$VCenter"
    }

    Write-Host "Disconnecting from vCenter '$VCenter'"
    Disconnect-VIServer $Connection -Confirm:$false
}
