###########
#region ### global:Retrieve-CloudSuiteSecretText # Checkouts the password to the provided CloudSuiteSecret objects
###########
function global:Retrieve-CloudSuiteSecretText
{
    <#
    .SYNOPSIS
    Retrieves the SecretText for the provided CloudSuiteSecret objects. Stores the Secret Text in the SecretText field.

    .DESCRIPTION
	This function will attempt to retrieve the text for the provided CloudSuiteSecret objects. By default, a global 
	encryption key needs to be set in order to retrieve the text. See Set-CloudSuiteEncryptionKey for more information.

	The encrypted secret text will be stored in the SecretText field of the CloudSuiteSecret object. You need to use
	the Decrypt-CloudSuiteSecretText function to show the secret in cleartext.

	This function does not work for File Type CloudSuiteSecret objects.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function does not return any objects.

    .PARAMETER CloudSuiteSecrets
    The CloudSuiteSecret objects to retrieve the text secret.

	.EXAMPLE
    C:\PS> Retrieve-CloudSuiteSecretText -CloudSuiteSecrets $CloudSuiteSecrets
    This function will retrieve the text secret of the provided Secrets and store the encrypted text in the
	SecretText field. A global encryption key must be set for this to be successful.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteSecret objects to retrieve.")]
        [PSTypeName('CloudSuiteSecret')]$CloudSuiteSecrets
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

	# for each CloudSuiteSecret passed
	foreach ($cloudsuitesecret in $CloudSuiteSecrets)
	{
		# if the Secret is a File Secret
		if ($cloudsuitesecret.Type -eq "File")
		{
			Write-Verbose ("Secret [{0}] is a File Secret." -f $cloudsuitesecret.Name)
			continue
		}

		$PowerShell = [PowerShell]::Create()
		$PowerShell.RunspacePool = $RunspacePool
	
		# Counter for the secret objects
		$g++; Write-Progress -Activity "Getting Secrets" -Status ("{0} out of {1} Complete" -f $g,$CloudSuiteSecrets.Count) -PercentComplete ($g/($CloudSuiteSecrets | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
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
				$cloudsuitesecret
			)
			$global:CloudSuiteConnection                         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation                 = $CloudSuiteSessionInformation
			$global:CloudSuiteEncryptedKey                       = $CloudSuiteEncryptedKey
			$global:CloudSuiteEnableClearTextPasswordsAndSecrets = $CloudSuiteEnableClearTextPasswordsAndSecrets

			$cloudsuitesecret.RetrieveSecret()
			
			return $cloudsuitesecret
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('CloudSuiteEncyptedKey',$global:CloudSuiteEncryptedKey)
		[void]$PowerShell.AddParameter('CloudSuiteEnableClearTextPasswordsAndSecrets',$global:CloudSuiteEnableClearTextPasswordsAndSecrets)
		[void]$PowerShell.AddParameter('cloudsuitesecret',$cloudsuitesecret)
			
		$JobObject = @{}
		$JobObject.Runspace   = $PowerShell.BeginInvoke()
		$JobObject.PowerShell = $PowerShell
	
		$Jobs.Add($JobObject) | Out-Null
	}# foreach ($cloudsuitesecret in $CloudSuiteSecrets)

	foreach ($job in $jobs)
	{
		# Counter for the job objects
		$p++; Write-Progress -Activity "Processing Secrets" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$processed.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)

	# closing the pool
	$RunspacePool.Close()
	$RunspacePool.Dispose()
}# function global:Retrieve-CloudSuiteSecretText
#endregion
###########