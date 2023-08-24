###########
#region ### global:Get-CloudSuiteMetrics # Gets basic object counts from the connected Cloud Suite tenant.
###########
function global:Get-CloudSuiteMetrics
{
    <#
    .SYNOPSIS
    Gets basic object counts from the connected Cloud Suite tenant.

    .DESCRIPTION
    Gets basic object counts from the connected Cloud Suite tenant. This will return a CloudSuiteMetric class object
	that stores these counts.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteMetric class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteMetrics
    Gets basic object counts from the connected Cloud Suite tenant.
    #>

    # Sysinfo version
    Write-Host ("Getting Version metrics ... ") -NoNewline
    $Version = Invoke-CloudSuiteAPI -APICall Sysinfo/Version
    Write-Host ("Done!") -ForegroundColor Green

    # Servers
    Write-Host ("Getting Server metrics ... ") -NoNewline
    $Servers = Query-RedRock -SQLQuery "SELECT ComputerClass, ComputerClassDisplayName, FQDN, HealthStatus, HealthStatusError, ID, LastHealthCheck, LastState, Name, OperatingSystem FROM Server"
    Write-Host ("Done!") -ForegroundColor Green

    # Accounts
    Write-Host ("Getting Account metrics ... ") -NoNewline
    # This is written as it is because the parent object type was never contined in a single column
    $Accounts = Query-RedRock -SQLQuery "SELECT (CASE WHEN DomainID != '' THEN DomainID WHEN Host != '' THEN Host WHEN DatabaseID != '' THEN DatabaseID WHEN DeviceID != '' THEN DeviceID WHEN KmipId != '' THEN KmipId WHEN VaultId != '' THEN VaultId WHEN VaultSecretId != '' THEN VaultSecretId ELSE 'Other' END) AS ParentID, (CASE WHEN DomainID != '' THEN 'DomainID' WHEN Host != '' THEN 'Host' WHEN DatabaseID != '' THEN 'DatabaseID' WHEN DeviceID != '' THEN 'DeviceID' WHEN KmipId != '' THEN 'KmipId' WHEN VaultId != '' THEN 'VaultId' WHEN VaultSecretId != '' THEN 'VaultSecretId' ELSE 'Other' END) AS ParentType,FQDN,HealthError,Healthy,ID,LastChange,LastHealthCheck,MissingPassword,Name,NeedsPasswordReset,User,UserDisplayName FROM VaultAccount"
    Write-Host ("Done!") -ForegroundColor Green

    # Secrets
    Write-Host ("Getting Secret metrics ... ") -NoNewline
    $Secrets = Query-RedRock -SQLQuery "SELECT SecretFileName,WhenCreated,SecretFileSize,ID,ParentPath,FolderId,Description,SecretName,Type FROM DataVault"
    Write-Host ("Done!") -ForegroundColor Green

    # Sets
    Write-Host ("Getting Set metrics ... ") -NoNewline
    $Sets = Query-RedRock -SQLQuery "SELECT ObjectType,Name,WhenCreated,ID,ParentPath,CollectionType,Description FROM Sets"
    Write-Host ("Done!") -ForegroundColor Green

    # Domains
    Write-Host ("Getting Domain metrics ... ") -NoNewline
    $Domains = Query-RedRock -SQLQuery "SELECT ID,LastHealthCheck,LastState,Name FROM VaultDomain"
    Write-Host ("Done!") -ForegroundColor Green

    # Privilege Elevation Commands
    Write-Host ("Getting Privileged Elevation Command metrics ... ") -NoNewline
    $Commands = Query-RedRock -SQLQuery "SELECT Name,DisplayName,ID,CommandPattern,RunAsUser,RunAsGroup,Description FROM PrivilegeElevationCommand"
    Write-Host ("Done!") -ForegroundColor Green

    # WebApps
    Write-Host ("Getting Applications metrics ... ") -NoNewline
    $Apps = Query-RedRock -SQLQuery "SELECT Name,Category,DisplayName,ID,Description,AppType,State FROM Application"
    Write-Host ("Done!") -ForegroundColor Green

    # SSH Keys
    Write-Host ("Getting SSH Key metrics ... ") -NoNewline
    $SSHKeys = Query-RedRock -SQLQuery "SELECT Comment,Created,CreatedBy,ID,IsManaged,LastUpdated,KeyType,Name,Revision,State FROM SSHKeys"
    Write-Host ("Done!") -ForegroundColor Green

    # CentrifyClients
    Write-Host ("Getting Centrify Client metrics ... ") -NoNewline
    $CentrifyClients = Query-RedRock -SQLQuery "SELECT ID,JoinDate,LastUpdate,Name,ResourceID,ResourceName FROM CentrifyClients"
    Write-Host ("Done!") -ForegroundColor Green

    # Roles
    Write-Host ("Getting Role metrics ... ") -NoNewline
    $Roles = Query-RedRock -SQLQuery "SELECT Name,ID,Description FROM Role"
    Write-Host ("Done!") -ForegroundColor Green

    # Connectors
    Write-Host ("Getting Connector metrics ... ") -NoNewline
    $Connectors = Query-RedRock -SQLQuery "SELECT DnsHostName,LastPingAttempted,ID,Version FROM Proxy"
    Write-Host ("Done!") -ForegroundColor Green

    # CloudProviders TOADD

    # Policies TOADD

    # creating the CloudSuiteData object
	$data = New-Object CloudSuiteMetricData -ArgumentList ($Servers,$Accounts,$Secrets,$Sets,$Domains,$Commands,$Apps,$CentrifyClients,$Roles,$Connectors)

    # creating the CloudSuiteMetric object
	$metric = New-Object CloudSuiteMetric ($data,$Version)
    
    return $metric
}# function global:Get-CloudSuiteMetrics
#endregion
###########