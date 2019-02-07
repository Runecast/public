$vc = Read-Host -Prompt 'Connect to vCenter'
$user = Read-Host -Prompt 'Username'
$pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($(Read-Host -AsSecureString -Prompt 'Password')))
$vcconn = Connect-VIServer $vc -User $user -Password $pass

if (!$vcconn) {
Write-Host "Connection to $vc failed" -ForegroundColor red
} else {
	$hosts = Get-View -ViewType HostSystem -Server $vcconn -Property @('name','hardware','summary') | Where-Object {$_.Summary.Runtime.ConnectionState -eq "connected"}
	$hostObjects=@()
	$hosts | %{
		$hv = $_
		"Collecting info from host: " + $hv.Name
		$ec = Get-Esxcli -VMHost $_.Name -V2
		$networkNics = $ec.network.nic.list.Invoke()
		$networkNics | %{
			$nicdetails = $ec.network.nic.get.Invoke(@{nicname=$_.Name})
			$_ | Add-Member -Name Details -Value $nicdetails -MemberType NoteProperty
		}
		$iscsiAdapters = $ec.iscsi.adapter.list.Invoke()
		$iscsiAdapters | %{
			$iscsidetails = $ec.iscsi.adapter.get.Invoke(@{adapter=$_.Adapter})
			$_ | Add-Member -Name Details -Value $iscsidetails -MemberType NoteProperty
		}
		if ($hv.summary.config.product.version -gt '6.0.0') {
			$nvmeDevices = $ec.nvme.device.list.Invoke()
			$nvmeDevices | %{
				$nvmeDetails = $ec.nvme.device.get(@{adapter=$_.HBAName})
				$_ | Add-Member -Name Details -Value $nvmeDetails -MemberType NoteProperty
			}
		}
		$hostProps = [ordered]@{
			EsxiVersion = $hv.summary.config.product.version
			EsxiBuild = $hv.summary.config.product.build
			Vendor = $hv.Hardware.SystemInfo.Vendor
			Model = $hv.Hardware.SystemInfo.Model
			Cpu = $hv.Hardware.CpuPkg
			MemorySize = $hv.Hardware.memorySize
			BiosVersion = $hv.Hardware.BiosInfo.BiosVersion
			PciDevices = $ec.hardware.pci.list.invoke()
			SoftwareVibs = $ec.software.vib.list.Invoke()
			NetworkNics = $networkNics
			StorageCoreAdapterList = $ec.storage.core.adapter.list.Invoke()
			SanSasList = $ec.storage.san.sas.list.Invoke()
			SanFcList = $ec.storage.san.fc.list.Invoke()
			SanFcoeList = $ec.storage.san.fcoe.list.Invoke()
			SanIscsiList = $ec.storage.san.iscsi.list.Invoke()
			IscsiList = $iscsiAdapters
			NvmeDevices = $nvmeDevices
		}
		$hostObj = New-Object -TypeName PSObject -Property $hostProps
		$hostObjects += $hostObj
	}
	Write-Host "Exporting results..."
	$timestamp = Get-Date -Format HHmmss
	$hostObjects | ConvertTo-Json -Depth 6 > hw_data_$timestamp.json
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$zip =  [System.IO.Compression.ZipFile]::Open("$pwd/hw_data_$timestamp.zip","Update")
	$compress = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$pwd/hw_data_$timestamp.json", "hw_data_$timestamp.json","optimal")
	$zip.Dispose()
	try {
		$result = Invoke-WebRequest -Uri https://portal.runecast.com/api/hw -Method Post -InFile "./hw_data_$timestamp.zip"
	} catch { Write-Host "No access to runecast.com"}
	Disconnect-VIServer -Server $vcconn -Confirm:$false
}