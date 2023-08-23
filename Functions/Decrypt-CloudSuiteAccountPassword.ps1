###########
#region ### global:Decrypt-CloudSuiteAccountPassword # Decrypts the password to the provided CloudSuiteAccount objects
###########
function global:Decrypt-CloudSuiteAccountPassword
{
    <#
    .SYNOPSIS
    Decrypts the password for the provided CloudSuiteAccount objects. The encrypted password must already exist in the Password field.

    .DESCRIPTION
	This function will attempt to decrypt the password for the provided CloudSuiteAccount objects into cleartext. The encrypted password
	must already be stored in the Password field of the CloudSuiteAccount object.

	By default, a global encryption key needs to be set in order to decrypt the password. Alternatively, the -Key paramter
	can be used to also provide an encryption key.

	If successful, the cleartext password will be stored in the Password field.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function does not return any objects.

    .PARAMETER CloudSuiteAccounts
    The CloudSuiteAccount objects to checkout the password.

	.PARAMETER Key
	The key to provide for decryption. This overrides the global key.

	.EXAMPLE
    C:\PS> Decrypt-CloudSuiteAccountPassword -CloudSuiteAccounts $CloudSuiteAccounts
    This function will decrypt the password of the provided accounts and store the clear text password in the
	Password field. A global encryption key must be set for this to be successful.

	.EXAMPLE
    C:\PS> Decrypt-CloudSuiteAccountPassword -CloudSuiteAccounts $CloudSuiteAccounts -Key $Key
    This function will decrypt the password of the provided accounts using the supplied encryption key instead 
	of the global encryption key and store the clear text password in the Password field.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteAccount objects to checkout.")]
        [PSTypeName('CloudSuiteAccount')]$CloudSuiteAccounts,

		[Parameter(Mandatory = $false, Position = 1, HelpMessage = "The key to provide for decryption.")]
		[Byte[]]$Key
    )

	# if clear text is off and global key is not set (and a Key was not provided)
	if ($global:CloudSuiteEnableClearTextPasswordsAndSecrets -eq $false -and (-Not ($global:CloudSuiteEncryptedKey) -and (-Not ($PSBoundParameters.ContainsKey('Key')))))
	{
		Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
		Write-Warning ("Or provide a key with the -Key variable.")
		throw "`$CloudSuiteEnableClearTextPasswordsAndSecrets is `$false and no global key is set."
	}

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

	# multithread start
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
	$RunspacePool.ApartmentState = 'STA'
	$RunspacePool.ThreadOptions = 'ReUseThread'
	$RunspacePool.Open()

	# processed ArrayList
	$processed = New-Object System.Collections.ArrayList

	# jobs ArrayList
	$Jobs = New-Object System.Collections.ArrayList


	# if a Key was provided, use that key
	if ($PSBoundParameters.ContainsKey('Key'))
	{
		$keytouse = $Key
	}
	else # otherwise, use the global one
	{
		$keytouse = $global:CloudSuiteEncryptedKey
	}

	# for each CloudSuiteAccount passed
	foreach ($cloudsuiteaccount in $CloudSuiteAccounts)
	{
		# if the Password field is null or empty, skip it
		if ([System.String]::IsNullOrEmpty($cloudsuiteaccount.Password))
		{
			Write-Verbose ("Account [{0}] password field is null" -f $cloudsuiteaccount.SSName)
			continue
		}

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
				$keytouse,
				$cloudsuiteaccount
			)
			$global:CloudSuiteConnection                         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation                 = $CloudSuiteSessionInformation
			$global:CloudSuiteEncryptedKey                       = $CloudSuiteEncryptedKey
			$global:CloudSuiteEnableClearTextPasswordsAndSecrets = $CloudSuiteEnableClearTextPasswordsAndSecrets

			$cloudsuiteaccount.Password = $cloudsuiteaccount.decryptPassword($keytouse)
			
			return $cloudsuiteaccount
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('keytouse',$keytouse)
		[void]$PowerShell.AddParameter('cloudsuiteaccount',$cloudsuiteaccount)
			
		$JobObject = @{}
		$JobObject.Runspace   = $PowerShell.BeginInvoke()
		$JobObject.PowerShell = $PowerShell
	
		$Jobs.Add($JobObject) | Out-Null
	}# foreach ($cloudsuiteaccount in $CloudSuiteAccounts)

	foreach ($job in $jobs)
	{
		# Counter for the job objects
		$p++; Write-Progress -Activity "Processing Accounts" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$processed.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)

	# closing the pool
	$RunspacePool.Close()
	$RunspacePool.Dispose()
}# function global:Decrypt-CloudSuiteAccountPassword
#endregion
###########