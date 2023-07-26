<#
.SYNOPSIS
This script generates HTML report from Runecast Analyzer for a given system

.DESCRIPTION
This script demonstrates the use of Runecast Analyzer API and how the results of analysis can be retrieved and post-processed to generate a report for a specific profile or issue severity. If multiple systems are specified, a separate report will be generated for each of them

.PARAMETER RcaAddress
FQDN or IP address of Runecast Analyzer

.PARAMETER RcaToken
API access token. It can be generated from the Runecast UI at "Settings" -> "Runecast API" page

.PARAMETER Ecosystems
Comma separated list of one or multiple systems

.PARAMETER SkipCertificateCheck
Boolean parameter to specify if not trusted certificates should be ignored

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
C:\PS> .\RunecastFindingsSummary.ps1 -RcaAddress rca.company.local -RcaToken 111-222-333-444 -Ecosystems system1.domain.local, system2.domain.local -SkipCertificateCheck $True

Description
-----------
This command will generate HTML reports for system1.domain.local and system2.domain.local from Runecast Analyzer rca.company.local, using authentication token 111-222-333-444 and will skip the certificate validation check

.NOTES
Version    : 25.07.2023
Changes    : Initial version
File Name  : RunecastFindingsSummaryReport.ps1

.LINK
https://github.com/Runecast/public/tree/master/PowerCLI

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]
    [String]$RcaAddress,
    [Parameter(Mandatory=$True)]
    [String]$RcaToken,
    [Parameter(Mandatory=$True)]
    [String[]]$Ecosystems,
    [bool]$SkipCertificateCheck = $False
)

if ($SkipCertificateCheck) {
    #Accept self signed certificates for earlier PS versions#
    if ($PsVersionTable.PSVersion.Major -lt 6) {
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
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
    }
}

function Generate-Summary($ecosystemInfo, $analysisResult) {
    $rcLogo = '<svg width="219" height="48" viewBox="0 0 146 34" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_894_8787)"><path fill-rule="evenodd" clip-rule="evenodd" d="M56.3971 30.4684H53.0926C52.796 30.4684 52.6896 30.2091 52.5527 29.9498L48.674 23.0315H48.2937C47.5902 23.0315 46.5064 22.9553 45.8828 22.9286V29.9498C45.8843 30.018 45.8722 30.0858 45.8469 30.1492C45.8217 30.2125 45.7841 30.2702 45.7361 30.3186C45.6882 30.367 45.631 30.4053 45.568 30.431C45.505 30.4567 45.4375 30.4695 45.3694 30.4684H42.662C42.5214 30.4715 42.3853 30.4187 42.2835 30.3215C42.1816 30.2243 42.1222 30.0907 42.1182 29.9498V12.1279C42.1182 11.6092 42.4452 11.4261 42.9852 11.3651C44.75 11.1314 46.5288 11.0193 48.3089 11.0295C52.4918 11.0295 56.1081 12.4559 56.1081 16.8837V17.1163C56.1081 19.8623 54.6745 21.5708 52.4538 22.4023L56.6595 29.9498C56.6988 30.0109 56.7175 30.0831 56.7128 30.1557C56.7156 30.1978 56.7094 30.2401 56.6945 30.2796C56.6796 30.3191 56.6564 30.3549 56.6264 30.3846C56.5965 30.4143 56.5605 30.4372 56.5209 30.4516C56.4813 30.4661 56.4391 30.4718 56.3971 30.4684ZM52.3359 16.8684C52.3359 14.9234 50.9822 14.0958 48.2747 14.0958C47.7081 14.0958 46.3505 14.1492 45.8638 14.1988V20.0301C46.2973 20.053 47.8146 20.1063 48.2747 20.1063C51.062 20.1063 52.3359 19.3817 52.3359 17.1011V16.8684Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M69.5657 30.4684H67.075C66.937 30.4675 66.8049 30.4129 66.7063 30.3161C66.6077 30.2194 66.5504 30.088 66.5464 29.9497V29.3662C65.3016 30.2349 63.8151 30.6874 62.2989 30.6591C60.9413 30.6591 59.7511 30.3235 58.9677 29.5722C57.9638 28.6149 57.614 27.0093 57.614 24.8583V16.3993C57.6159 16.2559 57.6733 16.1189 57.7741 16.0172C57.8748 15.9154 58.011 15.8569 58.154 15.8539H60.6447C60.7853 15.8607 60.9182 15.9208 61.0163 16.022C61.1144 16.1233 61.1705 16.2581 61.1733 16.3993V24.8469C61.1733 26.1436 61.2797 26.8911 61.7931 27.3335C62.1734 27.6424 62.6335 27.7988 63.4701 27.7988C64.474 27.7988 65.7745 27.1504 66.5312 26.7652V16.3993C66.5341 16.2556 66.5924 16.1186 66.6937 16.0169C66.7951 15.9153 66.9317 15.8569 67.075 15.8539H69.5657C69.7087 15.8569 69.8449 15.9154 69.9456 16.0172C70.0464 16.1189 70.1038 16.2559 70.1057 16.3993V29.9497C70.1042 30.0194 70.0891 30.088 70.0611 30.1518C70.0332 30.2155 69.993 30.2731 69.9429 30.3213C69.8927 30.3694 69.8336 30.4072 69.7689 30.4325C69.7042 30.4577 69.6351 30.4699 69.5657 30.4684Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M84.0158 30.4684H81.5251C81.3841 30.4626 81.2508 30.4028 81.1525 30.3013C81.0541 30.1999 80.9983 30.0645 80.9965 29.923V21.4793C80.9965 19.2253 80.7797 18.577 78.6921 18.577C77.7718 18.577 76.7908 18.9393 75.65 19.5114V29.923C75.6471 30.0668 75.5888 30.2038 75.4875 30.3054C75.3861 30.4071 75.2495 30.4655 75.1062 30.4684H72.6155C72.4725 30.4654 72.3363 30.4069 72.2356 30.3052C72.1348 30.2034 72.0774 30.0664 72.0755 29.923V16.3764C72.077 16.3068 72.0921 16.2382 72.12 16.1744C72.148 16.1107 72.1882 16.0531 72.2383 16.0049C72.2885 15.9567 72.3476 15.9189 72.4123 15.8937C72.477 15.8684 72.546 15.8562 72.6155 15.8577H74.9731C75.0425 15.8562 75.1115 15.8684 75.1763 15.8937C75.241 15.9189 75.3001 15.9567 75.3502 16.0049C75.4004 16.0531 75.4406 16.1107 75.4685 16.1744C75.4964 16.2382 75.5116 16.3068 75.5131 16.3764V16.918C76.8052 16.0426 78.3435 15.6067 79.9013 15.6747C83.799 15.6747 84.5862 18.188 84.5862 21.4793V29.923C84.5833 30.0668 84.5251 30.2038 84.4237 30.3054C84.3223 30.4071 84.1857 30.4655 84.0424 30.4684" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M98.405 24.3549H89.5791V24.4312C89.5791 25.9338 90.2293 27.7225 92.8266 27.7225C94.8039 27.7225 96.671 27.5661 97.8118 27.4631H97.8917C98.1617 27.4631 98.3784 27.5928 98.3784 27.8445V29.5531C98.3784 29.9688 98.2986 30.148 97.8118 30.2281C96.08 30.5568 94.3187 30.7038 92.5566 30.6667C89.8491 30.6667 86.0046 29.2671 86.0046 24.1642V22.2573C86.0046 18.2147 88.3584 15.6747 92.5033 15.6747C96.6482 15.6747 98.9488 18.3977 98.9488 22.2573V23.7065C98.9488 24.1222 98.7853 24.3549 98.405 24.3549ZM95.3629 21.8149C95.3629 19.7936 94.1955 18.6304 92.5185 18.6304C90.8416 18.6304 89.6209 19.7745 89.6209 21.8149V21.9179H95.3629V21.8149Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M109.623 30.3388C108.474 30.581 107.302 30.6935 106.128 30.6744C102.611 30.6744 99.9565 28.6035 99.9565 24.3778V21.9713C99.9565 17.7494 102.618 15.6747 106.128 15.6747C107.302 15.6542 108.475 15.7681 109.623 16.0141C110.083 16.1171 110.189 16.2697 110.189 16.6854V18.3711C110.189 18.6304 109.973 18.7524 109.703 18.7524H109.623C108.464 18.6074 107.296 18.5462 106.128 18.5694C104.858 18.5694 103.531 19.2711 103.531 21.9637V24.3702C103.531 27.0665 104.858 27.7644 106.128 27.7644C107.296 27.7885 108.464 27.7286 109.623 27.5852H109.703C109.973 27.5852 110.189 27.7149 110.189 27.9666V29.6485C110.189 30.0642 110.083 30.2205 109.623 30.3235" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M122.445 30.4684H120.145C120.004 30.4715 119.868 30.4187 119.766 30.3215C119.664 30.2243 119.605 30.0907 119.601 29.9497V29.534C118.458 30.2487 117.145 30.6438 115.798 30.6782C113.551 30.6782 111.114 29.8506 111.114 26.3533V26.2504C111.114 23.2947 113.015 21.7692 117.719 21.7692H119.403V20.625C119.403 18.9393 118.616 18.5236 117.019 18.5236C115.285 18.5236 113.498 18.6304 112.604 18.7334H112.471C112.201 18.7334 111.981 18.6533 111.981 18.2948V16.6358C111.981 16.3497 112.144 16.1667 112.498 16.0904C113.989 15.8119 115.502 15.6727 117.019 15.6747C120.864 15.6747 122.978 17.3108 122.978 20.6326V29.9497C122.974 30.0887 122.916 30.2206 122.817 30.3175C122.717 30.4143 122.584 30.4685 122.445 30.4684ZM119.403 24.0269H117.696C115.232 24.0269 114.688 24.7897 114.688 26.2313V26.3343C114.688 27.6043 115.285 27.9399 116.639 27.9399C117.603 27.9226 118.549 27.6796 119.403 27.2305V24.0269Z" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M129.747 30.6743C128.117 30.6709 126.492 30.497 124.898 30.1557C124.755 30.1362 124.624 30.065 124.529 29.9554C124.435 29.8459 124.383 29.7056 124.385 29.5607V28.0047C124.393 27.8893 124.445 27.7817 124.531 27.7047C124.617 27.6277 124.73 27.5875 124.845 27.5928H124.951C126.252 27.7492 128.689 27.8788 129.515 27.8788C131.192 27.8788 131.435 27.3335 131.435 26.6355C131.435 26.1435 131.112 25.8308 130.245 25.3121L126.537 23.1383C125.21 22.3755 124.255 21.0636 124.255 19.5609C124.255 16.9714 125.963 15.6747 129.4 15.6747C131.026 15.6606 132.648 15.8347 134.234 16.1934C134.369 16.2181 134.491 16.2912 134.577 16.3992C134.663 16.5071 134.707 16.6426 134.701 16.7807V18.3062C134.701 18.6151 134.538 18.7982 134.268 18.7982H134.158C132.676 18.6122 131.186 18.5078 129.693 18.4854C128.393 18.4854 127.822 18.7715 127.822 19.5724C127.822 19.9881 128.229 20.2474 128.906 20.6364L132.454 22.7073C134.736 24.0269 135.055 25.3236 135.055 26.647C135.055 28.8971 133.294 30.6858 129.731 30.6858" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M144.759 30.5104C144.151 30.6216 143.534 30.6828 142.915 30.6934C139.873 30.6934 138.61 30.0451 138.61 26.5745V18.4244L136.067 18.043C135.766 17.9935 135.527 17.8104 135.527 17.5244V16.3764C135.528 16.3068 135.543 16.2382 135.571 16.1744C135.599 16.1107 135.639 16.053 135.689 16.0049C135.74 15.9567 135.799 15.9189 135.863 15.8937C135.928 15.8684 135.997 15.8562 136.067 15.8577H138.61V13.7296C138.61 13.4436 138.854 13.2644 139.15 13.211L141.672 12.7953H141.778C141.832 12.7876 141.888 12.7917 141.94 12.8074C141.992 12.8231 142.041 12.85 142.082 12.8862C142.123 12.9224 142.156 12.9671 142.179 13.0172C142.201 13.0674 142.212 13.1217 142.212 13.1766V15.8463H144.649C144.719 15.8448 144.788 15.857 144.852 15.8822C144.917 15.9075 144.976 15.9453 145.026 15.9934C145.076 16.0416 145.117 16.0992 145.145 16.163C145.172 16.2267 145.188 16.2954 145.189 16.365V17.8905C145.186 18.0314 145.128 18.1655 145.026 18.2634C144.925 18.3612 144.79 18.415 144.649 18.413H142.219V26.5554C142.219 27.8521 142.303 28.0047 143.276 28.0047H144.71C145.064 28.0047 145.28 28.1344 145.28 28.3861V30.0184C145.28 30.2777 145.117 30.4341 144.767 30.4837" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M0 21.0254V24.6371L9.02369 11.8838V3.28748L0 21.0254Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M9.02369 14.3399L0 25.6859V29.3205L9.02369 22.9362V14.3399Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M9.0351 25.3961L0 30.3578V34L9.0351 33.9924V25.3961Z" fill="#6D6E71"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M10.6322 22.9362L28.7747 24.866V17.7685L10.6322 14.3399V22.9362Z" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M10.5638 25.3961V33.9924H28.7747V26.8987L10.5638 25.3961Z" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M26.2041 10.5108C26.2041 10.5108 26.2421 7.94412 26.2421 7.89836L10.6474 3.28748V11.8838L28.7861 15.7357V11.06L26.2155 10.5108" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M29.6949 10.1523V7.71528L27.265 6.99829C27.265 7.95174 27.265 8.86324 27.265 9.59549L29.7063 10.1523" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M26.3334 5.40417L28.7747 5.96099V3.52397L26.3448 2.80316C26.3448 3.76042 26.341 4.67574 26.3334 5.40417Z" fill="#F39318"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M31.8434 6.91823V5.07998L30.0105 4.54224C30.0105 5.26304 30.0105 5.94953 30.0105 6.49871L31.851 6.91823" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M31.562 3.47055V1.96791L30.041 1.52551C30.041 2.11284 30.041 2.66965 30.041 3.12731L31.562 3.47055Z" fill="#F39316"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M33.1515 1.5484V0.350869L31.9613 0C31.9613 0.469097 31.9613 0.915311 31.9613 1.27381L33.1591 1.5484" fill="#F39316"></path></g><defs><clipPath id="clip0_894_8787"><rect width="145.273" height="34" fill="white"></rect></clipPath></defs></svg>'
    $preContent = @"
    <!doctype html>
    <html>
    <head>
        <title>Runecast Analysis Results</title>
        <style> 
            :root {
                --white-dark1: #f7f7f7;
                --smoky-black: #0b0a09;
                --low-grey-dark1: #4d4d4d;
                --low-grey: #696969;
                --low-grey-light2: #999999;
                --white-dark3: #e5e7eb;
                --critical-red: #cc0018;
                --warning-yellow: #f39316;
                --medium-gold: #ebcf47;
                --info-blue-dark1: #1269e2;
            }

            body {
                background-color: var(--white-dark1);
                color: var(--smoky-black);
                font-family: sans-serif;
                padding: 16px;
                min-width: 832px;
            }

            header {
                display: flex;
                align-items: center;
                gap: 16px;
                margin: 0px 16px;
            }

            h1 {
                margin: 0px;
                font-weight: 400;
                font-size: 24px;
            }

            table {
                border-collapse: collapse; 
            }

            table tr {
                border-bottom: 1pt solid var(--white-dark3);
                margin: 0px 16px
            }

            table tr:last-child {
                border-bottom: none;
            }

            table th {
                font-size: 14px;
                font-weight: 600;
                color: var(--low-grey-dark1);
                text-align: left;
                padding: 16px;
            }

            table td {
                font-size: 14px;
                font-weight: 400;
                padding: 16px;
                vertical-align: top;

            }

            th {
                background-color: white;
                position: sticky;
            }
        
            thead tr th {
                top: 0;
            }
        
            tbody tr th {
                top: 0;
            }

            td a {
                text-decoration: none;
                color: var(--info-blue-dark1);
            }

            td a:hover {
                text-decoration: underline;
            }

            .title {
                border-left: 2px solid var(--white-dark3);
                padding: 2px 16px;
            }

            .meta-info {
                margin: 1px 0px;
                font-size: 14px;
                color: var(--low-grey-dark1);
            }

            .summary {
                padding: 8px 16px;
                display: flex;
                align-items: center;
                background-color: white;
                border: 1px solid var(--white-dark3);
                border-radius: 4px;
                margin: 16px 0px;
                gap: 32px;
                width: fit-content;
            }

            .score-card {
                padding: 4px;
                display: flex;
                align-items: center;
            }

            .score-card .indicator {
                width: 4px;
                border-radius: 4px;
                border: none;
                height: 32px;
                margin-right: 8px;
            }

            .score-card .sum {
                font-size: 24px;
                font-weight: 600;
                margin: 0px;
            }

            .score-card .label {
                font-size: 14px;
                margin: 0px;
                color: var(--low-grey-dark1);
            }

            .critical {
                color: var(--critical-red);
            }

            .bg-critical {
                background-color: var(--critical-red);
            }

            .bg-major {
                background-color: var(--warning-yellow);
            }
            
            .bg-medium {
                background-color: var(--medium-gold);
            }

            .bg-low {
                background-color: var(--low-grey-light2);
            }

            .report {
                background-color: white;
                border: 1px solid var(--white-dark3);
                border-radius: 4px;
                padding: 16px;
            }

            .cell-severity {
                font-weight: 600;
                color: var(--low-grey-dark1);
            }

            .cell-status {
                text-transform: lowercase;
            }

            .cell-status::first-letter {
                text-transform: capitalize;
            }

            .cell-count {
                text-align: right;
            }

        </style>
    </head>
    <body>
    <header>
        <a href="https://$($RcaAddress)" target="_blank">
            <div class="logo">$($rcLogo)</div>
        </a>
        <div class="title">
            <h1>Analysis Results</h1>
            <p class="meta-info">System: $($ecosystemInfo.viewName), Scanned at: $(([System.DateTimeOffset]::FromUnixTimeMilliseconds($analysisResult.createdTs)).DateTime)</p>
        </div>

    </header>

    <div class="summary"> 
        <div class="score-card">
            <hr class="indicator bg-critical"/>
            <div>
                <p class="sum">$($analysisResult.configScanResultSummary.foundCriticalIssuesCount)</p>
                <p class="label">Critical issues</p>
            </div>
        </div>
        <div class="score-card">
            <hr class="indicator bg-major"/>
            <div>
                <p class="sum">$($analysisResult.configScanResultSummary.foundMajorIssuesCount)</p>
                <p class="label">Major issues</p>
            </div>
        </div>
        <div class="score-card">
            <hr class="indicator bg-medium"/>
            <div>
                <p class="sum">$($analysisResult.configScanResultSummary.foundMediumIssuesCount)</p>
                <p class="label">Medium issues</p>
            </div>
        </div>
        <div class="score-card">
            <hr class="indicator bg-low"/>
            <div>
                <p class="sum">$($analysisResult.configScanResultSummary.foundLowIssuesCount)</p>
                <p class="label">Low issues</p>
            </div>
        </div>
        <div class="score-card">
            <hr class="indicator bg-critical"/>
            <div>
                <p class="sum critical">$($analysisResult.configScanResultSummary.foundVulnerabilitiesCount)</p>
                <p class="label">Vulnerabilities</p>
            </div>
        </div>
    </div>
"@
    return $preContent
 }

function Generate-IssueTable($analysisResult) {

    $content = @"
    <div class="report">
        <table>
        <tr>
            <th>Severity</th>
            <th>Type</th>
            <th>Title</th>
            <th>Status</th>
            <th>Affected&nbsp;objects</th>
        </tr>
"@

    #You can filter and include only issues matching specific criteria like shown in the example below
    #$filteredIssues = $analysisResult.scannedIssues | Where-Object {$_.issue.type -eq "VUL"}
    $filteredIssues = $analysisResult.scannedIssues

    $severity = "Critical", "Major", "Medium", "Low"
    $issueStatus = "FAIL", "M_FAIL", "MANUAL", "UNLICENSED", "PASS", "M_PASS", "FILTERED", "NOT_RELEVANT", "NOT_APPLICABLE"
    
    #You can adjust the sorting as needed
    $sortedIssues = $filteredIssues | Sort-Object -Property @{Expression={$issueStatus.IndexOf($_.status)}}, @{Expression={$severity.IndexOf($_.issue.severity)}}, @{Expression={$_.issue.type}}
    
    foreach ($scannedIssue in $sortedIssues) {
    $content += @"
        <tr>
            <td class="cell-severity">$($scannedIssue.issue.severity)</td>
            <td>$($scannedIssue.issue.type)</td>
            <td><a href="https://$($RcaAddress)/rca/issues/$($scannedIssue.issue.issueDisplayId)" target="_blank">$($scannedIssue.issue.title)</a></td>
            <td class="cell-status">$($scannedIssue.status)</td>
            <td class="cell-count">$($scannedIssue.affectedObjectsCount)</td>
        </tr>
"@
    }

    $content += "</table></div></body></html>"
    return $content
}

$date = Get-Date -Format "dd-MMM-yyyy"
$headers = @{"Authorization"=$RcaToken;"Content-Type"="application/json";"Accept"="application/json"}

$ecosystemsUrl = "https://"+$RcaAddress+"/rca/api/v2/rca-instances/1/ecosystems"

try {
    Write-Host "Getting ecosystem info..."
    if ($PsVersionTable.PSVersion.Major -lt 6) {
        $allEcosystems = Invoke-RestMethod -Uri $ecosystemsUrl -Headers $headers
    } else {
        $allEcosystems = Invoke-RestMethod -Uri $ecosystemsUrl -Headers $headers -SkipCertificateCheck:$SkipCertificateCheck
    }

    foreach ($ecosystem in $Ecosystems) {

        $ecosystemInfo = $null
        $ecosystemInfo = $allEcosystems.ecosystems | where viewName -ieq $ecosystem

        if ($ecosystemInfo -eq $null) {
            Write-Host "Ecosystem " $ecosystem "not found. Skipping." -ForegroundColor "Red"
            continue;
        }

        Write-Host "Generating report for: " $ecosystem
        $resultUrl = "https://"+$RcaAddress+"/rca/api/v2/ecosystems/"+$($ecosystemInfo.id)+"/config-scans/latest?includeAllAnalyzedObjects=false"

        if ($PsVersionTable.PSVersion.Major -lt 6) {
            $analysisResult = Invoke-RestMethod -Uri $resultUrl -Method Get -Headers $headers
        } else {
            $analysisResult = Invoke-RestMethod -Uri $resultUrl -Method Get -Headers $headers -SkipCertificateCheck:$SkipCertificateCheck
        }

        $content = Generate-Summary $ecosystemInfo $analysisResult
        $content+= Generate-IssueTable $analysisResult
        $content | Out-File ./RunecastReport-$ecosystem-$date.html

        Write-Host "Runecast report generated for: " $ecosystem
    } 
} catch {
    Write-Host "There was an error while generating report" -ForegroundColor "Red"
    $_.Exception
}
