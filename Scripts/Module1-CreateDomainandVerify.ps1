#Installera Azura AD modulen
Install-Module AzureAD

#Connect with John Doe
Import-Module AzureAD
Connect-AzureAD

#installera AZ modulen
Install-Module AZ

#Connect with Atea account
Connect-AzAccount

$DomainName = Get-ADForest | select upnsuffixes -ExpandProperty upnsuffixes

New-AzureADDomain -Name $DomainName -IsDefault $true
$verificationTXT = (Get-AzureADDomainVerificationDnsRecord -Name $DomainName | Where-Object {$_.RecordType -eq 'txt'}).text

$ResourceGroup = (Get-AzResourceGroup |where resourcegroupname -like M365*).ResourceGroupName

$Records = @()
$Records += New-AzDnsRecordConfig -Value $verificationTXT
$RecordSet = New-AzDnsRecordSet -Name "@" -RecordType TXT -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

    DO
    {
    Write-Host "Domain is not verified yet, please wait" -ForegroundColor Red
    Start-Sleep -Seconds 20
    Confirm-AzureADDomain -Name $DomainName


    $verificationstatus = Get-AzureADDomain -Name $domainname | select IsVerified -ExpandProperty IsVerified
    } Until ($verificationstatus -eq $true)

Set-AzureADDomain -Name $DomainName -IsDefault $true
Write-Host "Domain is verified and set as default, DNS Config will continue" -ForegroundColor Green

#Add records to DNS
$MX = $DomainName + ".mail.protection.outlook.com" -replace ".m365masterclass.space", "-m365masterclass-space"

$Records = @()
$Records += New-AzDnsRecordConfig -Cname EnterpriseEnrollment-s.manage.microsoft.com
$RecordSet = New-AzDnsRecordSet -Name "EnterpriseEnrollment" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Cname EnterpriseRegistration.windows.net
$RecordSet = New-AzDnsRecordSet -Name "EnterpriseRegistration" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Cname clientconfig.microsoftonline-p.net
$RecordSet = New-AzDnsRecordSet -Name "MSOID" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records


$Records = @()
$Records += New-AzDnsRecordConfig -Cname autodiscover.outlook.com
$RecordSet = New-AzDnsRecordSet -Name "autodiscover" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Cname sipdir.online.lync.com
$RecordSet = New-AzDnsRecordSet -Name "sip" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Cname webdir.online.lync.com
$RecordSet = New-AzDnsRecordSet -Name "lyncdiscover" -RecordType CNAME -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Exchange $MX -Preference 10
$RecordSet = New-AzDnsRecordSet -Name "@" -RecordType MX -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Priority 100 -Weight 1 -Port 443 -Target sipdir.online.lync.com
$RecordSet = New-AzDnsRecordSet -Name "_sip._tls" -RecordType SRV -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$Records = @()
$Records += New-AzDnsRecordConfig -Priority 100 -Weight 1 -Port 5061 -Target sipfed.online.lync.com
$RecordSet = New-AzDnsRecordSet -Name "_sipfederationtls._tcp" -RecordType SRV -ResourceGroupName $ResourceGroup -TTL 3600 -ZoneName $DomainName -DnsRecords $Records

$RecordSet = Get-AzDnsRecordSet -Name "@" -RecordType TXT -ResourceGroupName $ResourceGroup -ZoneName $DomainName
Add-AzDnsRecordConfig -RecordSet $RecordSet -Value "v=spf1 include:spf.protection.outlook.com -all"
Set-AZDnsRecordSet -RecordSet $RecordSet