###########
#region ### global:Checkout-CloudSuiteAccountPassword # Checkouts the password to the provided CloudSuiteAccount objects
###########
function global:Checkout-CloudSuiteAccountPassword
{
    <#
    .SYNOPSIS
    Checkouts the password for the provided CloudSuiteAccount objects. Stores the password in the Password field.

    .DESCRIPTION
	This function will attempt to checkout the password for the provided CloudSuiteAccount objects. By default, a 
	global encryption key needs to be set in order to checkout passwords. See Set-CloudSuiteEncryptionKey for more information.

	The encrypted password will be stored in the Password field of the CloudSuiteAccount object. You need to use
	the Decrypt-CloudSuiteAccountPassword function to show the password in cleartext.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function does not return any objects.

    .PARAMETER CloudSuiteAccounts
    The CloudSuiteAccount objects to checkout the password.

	.EXAMPLE
    C:\PS> Checkout-CloudSuiteAccountPassword -CloudSuiteAccounts $CloudSuiteAccounts
    This function will checkout the password of the provided accounts and store the encrypted password in the
	Password field. A global encryption key must be set for this to be successful.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteAccount objects to checkout.")]
        [PSTypeName('CloudSuiteAccount')]$CloudSuiteAccounts
    )

	# if clear text is off and global key is not set
	if ($global:CloudSuiteEnableClearTextPasswordsAndSecrets -eq $false -and (-Not ($global:CloudSuiteEncryptedKey)))
	{
		Write-Warning ("No global encrypted key set. Use Set-CloudSuiteEncryptionKey to set one.")
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

	# for each CloudSuiteAccount passed
	foreach ($cloudsuiteaccount in $CloudSuiteAccounts)
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
				$CloudSuiteEncryptedKey,
				$CloudSuiteEnableClearTextPasswordsAndSecrets,
				$cloudsuiteaccount
			)
			$global:CloudSuiteConnection                         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation                 = $CloudSuiteSessionInformation
			$global:CloudSuiteEncryptedKey                       = $CloudSuiteEncryptedKey
			$global:CloudSuiteEnableClearTextPasswordsAndSecrets = $CloudSuiteEnableClearTextPasswordsAndSecrets

			$cloudsuiteaccount.CheckoutPassword()
			
			return $cloudsuiteaccount
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('CloudSuiteEncyptedKey',$global:CloudSuiteEncryptedKey)
		[void]$PowerShell.AddParameter('CloudSuiteEnableClearTextPasswordsAndSecrets',$global:CloudSuiteEnableClearTextPasswordsAndSecrets)
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
}# function global:Checkout-CloudSuiteAccountPassword
#endregion
###########