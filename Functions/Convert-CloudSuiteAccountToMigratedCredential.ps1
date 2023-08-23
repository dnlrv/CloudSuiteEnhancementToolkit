###########
#region ### global:Convert-CloudSuiteAccountToMigratedCredential # Gets a CloudSuite Account object
###########
function global:Convert-CloudSuiteAccountToMigratedCredential
{
    <#
    .SYNOPSIS
    Gets an Account object from a connected Cloud Suite tenant.

    .DESCRIPTION
    Gets an Account object from a connected Cloud Suite tenant. This returns a CloudSuiteAccount class object containing properties about
    the Account object. By default, Convert-CloudSuiteAccountToMigratedCredential without any parameters will get all Account objects in the Cloud Suite. 
    In addition, the CloudSuiteAccount class also contains methods to help interact with that Account.

    The additional methods are the following:

    .CheckInPassword()
      - Checks in a password that has been checked out by the CheckOutPassword() method.
    
    .CheckOutPassword()
      - Checks out the password to this Account.
    
    .ManageAccount()
      - Sets this Account to be managed by the Cloud Suite.

    .UnmanageAccount()
      - Sets this Account to be un-managed by the Cloud Suite.

    .UpdatePassword([System.String]$newpassword)
      - Updates the password to this Account.
    
    .VerifyPassword()
      - Verifies if this password on this Account is correct.
    
    If this function gets all Accounts from the Cloud Suite Tenant, then everything will also be saved into the global
    $CloudSuiteAccountBank variable. This makes it easier to reference these objects without having to make additional 
    API calls.

    .PARAMETER Type
    Gets only Accounts of this type. Currently only "Local","Domain","Database", or "Cloud" is supported.

    .PARAMETER SourceName
    Gets only Accounts with the name of the Parent object that hosts this account. For local accounts, this would
    be the hostname of the system the account exists on. For domain accounts, this is the name of the domain.

    .PARAMETER UserName
    Gets only Accounts with this as the username.

    .PARAMETER Uuid
    Gets only Accounts with this UUID.

    .PARAMETER Limit
    Limits the number of potential Account objects returned.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteAccount class object.

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential
    Gets all Account objects from the Delinea CloudSuite.

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential -Limit 10
    Gets 10 Account objects from the Delinea CloudSuite.

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential -Type Domain
    Get all domain-based Accounts.

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential -Username "root"
    Gets all Account objects with the username, "root".

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential -SourceName "LINUXSERVER01.DOMAIN.COM"
    Get all Account objects who's source (parent) object is LINUXSERVER01.DOMAIN.COM.

    .EXAMPLE
    C:\PS> Convert-CloudSuiteAccountToMigratedCredential -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Get an Account object with the specified UUID.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [PSCustomObject[]]$CloudSuiteAccounts,

        [Parameter(Mandatory = $false, HelpMessage = "The SetBank to use for Set memberships.", ParameterSetName = "SetBank")]
        [PSCustomObject]$SetBank
    )

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

	# multithread start
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
	$RunspacePool.ApartmentState = 'STA'
	$RunspacePool.ThreadOptions = 'ReUseThread'
	$RunspacePool.Open()

	# jobs ArrayList
	$Jobs = New-Object System.Collections.ArrayList

	# returned ArrayList
	$MigratedCredentials = New-Object System.Collections.ArrayList

	foreach ($csa in $CloudSuiteAccounts)
	{
		$PowerShell = [PowerShell]::Create()
		$PowerShell.RunspacePool = $RunspacePool

		# Counter for the account objects
		$g++; Write-Progress -Activity "Getting Accounts" -Status ("{0} out of {1} Complete" -f $g,$CloudSuiteAccounts.Count) -PercentComplete ($g/($CloudSuiteAccounts | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		# for each script in our CloudSuiteEnhancementToolkitScriptBlocks
		foreach ($script in $global:CloudSuiteEnhancementToolkitScriptBlocks)
		{
			# add it to this thread as a script, this makes all classes and functions available to this thread
			[void]$PowerShell.AddScript($script.ScriptBlock)
		}
		[void]$PowerShell.AddScript(
		{
			Param
			(
				$CloudSuiteConnection,
				$CloudSuiteSessionInformation,
				$csa
			)
			$global:CloudSuiteConnection         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation = $CloudSuiteSessionInformation

			$mc = New-Object MigratedCredential

			# placeholder to determine target
			[System.String]$FQDN = $null

			switch ($csa.AccountType)
			{
				'Local' 
				{
					if ($csa.ComputerClass -eq "Windows") { $mc.SecretTemplate = "Windows Account" }
					if ($csa.ComputerClass -eq "Unix")    { $mc.SecretTemplate = "Unix Account (SSH)" }
					$FQDN = $csa.SourceName
					break
				}# 'Local'
				'Domain'
				{
					$mc.SecretTemplate = "Active Directory Account"
					$FQDN = $csa.SourceName
					break
				}
				'Database'
				{
					# this requires extrachecking DatabaseClass and ID from VaultDatabase table
					$query = Query-RedRock -SQLQuery ("SELECT FQDN,DatabaseClass FROM VaultDatabase WHERE ID = '{0}'" -f $csa.SourceID)
					
					switch ($query.DatabaseClass)
					{
						'Oracle'    { $mc.SecretTemplate = "Oracle Account"; break}
						'SAPAse'    { $mc.SecretTemplate = "SAP Account"; break }
						'SQLServer' { $mc.SecretTemplate = "SQL Server Account"; break }
					}
	
					$FQDN = $query.FQDN
					break
				}# 'Database'
			}# switch ($csa.AccountType)
	
			# setting the Secret Name and others
			$mc.SecretName  = $csa.SSName
			$mc.Target      = $FQDN 
			$mc.Username    = $csa.Username
			$mc.Password    = $csa.Password
			$mc.PASDataType = "VaultAccount"
			$mc.PASUUID     = $csa.ID
	
			# Permissions
			foreach ($rowace in $csa.PermissionRowAces)
			{
				$mc.Permissions.Add((ConvertTo-SecretServerPermission -Type self -Name $csa.SSName -RowAce $rowace)) | Out-Null
			}
	
			$mc.OriginalObject = $csa

			return $mc
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('csa',$csa)
			
		$JobObject = @{}
		$JobObject.Runspace   = $PowerShell.BeginInvoke()
		$JobObject.PowerShell = $PowerShell

		$Jobs.Add($JobObject) | Out-Null
	}# foreach ($query in $basesqlquery)

	foreach ($job in $jobs)
	{
		# Counter for the job objects
		$j++; Write-Progress -Activity "Processing Accounts" -Status ("{0} out of {1} Complete" -f $j,$jobs.Count) -PercentComplete ($j/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$MigratedCredentials.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)

	# converting back to MigratedCredential because multithreaded objects return an Automation object Type
	$returned = ConvertFrom-DataToMigratedCredential -DataMigratedCredentials $MigratedCredentials

	return $returned
}# function global:Convert-CloudSuiteAccountToMigratedCredential
#endregion
###########