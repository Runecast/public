#This script can be used to add multiple vCenter Servers with the same service account to Runecast Analyzer
#Variables#
$rcaAddress = '' #FQDN or IP address of runecast analyzer, for example: runecast.company.local
$rcaToken = '' #API access token
$vCenters = @(
  'vc1.company.local'
  'vc2.company.local'
)
$vcPort = 443
#End of variables section#

#Accept self signed certificates for Desktop PS#
if ($PSVersionTable.PSEdition -ne 'Core') {
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

#Do not edit beyond here#
$vcUser = Read-Host 'Enter service user name: '
$vcPasswordInput = Read-Host 'Enter service user password: ' -AsSecureString

$temp = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vcPasswordInput)
$vcPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($temp)

$headers = @{"Authorization"=$rcaToken;"Content-Type"="application/json";"Accept"="application/json"}
$url = "https://"+$rcaAddress+"/rc2/api/v1/vcenters"

foreach ($vCenter in $vCenters) {
  $body = '{
    "address": "'+$vCenter+'",
    "password": "'+$vcPassword+'",
    "port": '+$vcPort+',
    "username": "'+$vcUser+'"
  }'
  Write-Host "Adding $vCenter..." -foregroundcolor "yellow"
  if ($PSVersionTable.PSEdition -ne 'Core') {
    $addVC = Invoke-WebRequest -Uri $url -Method Put -Body $body -Headers $headers 
  } else {
    $addVC = Invoke-WebRequest -Uri $url -Method Put -Body $body -Headers $headers -SkipCertificateCheck
  }
  if ($null -ne $addVC) {
      if ($addVC.StatusCode -eq '200') {
      Write-Host "vCenter Server $vCenter added successfully!"
      }
  } else { Write-Host "vCenter Server $vCenter not added!" -ForegroundColor Red }
}
