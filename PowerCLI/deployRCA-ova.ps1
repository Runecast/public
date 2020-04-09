#Variables#
$vcenter = '' #address of the vCenter Server
$cluster = '' #cluster name
$datastore = '' #datastore name
$vmName = '' #name for the Runecast Analyzer VM
$ovaPath = '' #path to the OVA
$rcHostname = '' #Runeacast Analyzer hostname
$rcDeployOption = '' #valid values: small, medium, large
$rcNetwork = '' #portgroup or dvportgroup
$rcIP = '' #Leave blank if DHCP desired
$rcNetMask = '' #Leave blank if DHCP desired
$rcGateway = '' #Leave blank if DHCP desired
$rcDNS = '' #Comma separated if multiple, leave blank if DHCP desired
#End of Variables#

#Do not edit beyond here#
Write-Host "`nConnecting to $vCenter...`n"
Connect-VIServer -server $vCenter
$ovaConfig = Get-OvfConfiguration -Ovf $ovaPath
$ovaConfig.rc.Runecast_Analyzer.hostname.value = $rcHostname
$ovaConfig.DeploymentOption.Value = $rcDeployOption
$ovaConfig.NetworkMapping.Network_1.Value = $rcNetwork
$ovaConfig.rc.Runecast_Analyzer.gateway.Value = $rcGateway
$ovaConfig.rc.Runecast_Analyzer.DNS.Value = $rcDNS
$ovaConfig.rc.Runecast_Analyzer.ip0.Value = $rcIP
$ovaConfig.rc.Runecast_Analyzer.netmask0.Value = $rcNetMask
$vmHost = Get-Cluster -Name $cluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"} | Get-Random
$targetDatastore = Get-Datastore -Name $datastore
Write-Host "`nDeploying Runecast Analyzer...`n"
$RC = Import-VApp -Source $ovaPath -OvfConfiguration $ovaConfig -Name $vmName -VMHost $vmHost -Datastore $targetDatastore -DiskStorageFormat "Thin"
Start-VM -VM $RC
Disconnect-VIServer -Confirm:$false