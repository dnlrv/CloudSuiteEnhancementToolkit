###########
#region ### global:Decrypt-CloudSuiteSecretText # Decrypts the SecretText to the provided CloudSuiteSecret objects
###########
function global:Decrypt-CloudSuiteSecretText
{
    <#
    .SYNOPSIS
    Decrypts the Secret Text for the provided CloudSuiteSecret objects. The encrypted Secret Text must already exist in the SecretText field.

    .DESCRIPTION
	This function will attempt to decrypt the Secret Text for the provided CloudSuiteSecret objects into cleartext. The encrypted Secret Text
	must already be stored in the SecretText field of the CloudSuiteSecret object.

	By default, a global encryption key needs to be set in order to decrypt the Secret Text. Alternatively, the -Key paramter
	can be used to also provide an encryption key.

	If successful, the cleartext Secret Text will be stored in the SecretText field.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function does not return any objects.

    .PARAMETER CloudSuiteSecrets
    The CloudSuiteSecret objects to checkout the Secret Text.

	.PARAMETER Key
	The key to provide for decryption. This overrides the global key.

	.EXAMPLE
    C:\PS> Decrypt-CloudSuiteSecretText -CloudSuiteSecrets $CloudSuiteSecrets
    This function will decrypt the Secret Text of the provided secrets and store the clear text Secret Text in the
	SecretText field. A global encryption key must be set for this to be successful.

	.EXAMPLE
    C:\PS> Decrypt-CloudSuiteSecretText -CloudSuiteSecrets $CloudSuiteSecrets -Key $Key
    This function will decrypt the Secret Text of the provided secrets using the supplied encryption key instead 
	of the global encryption key and store the clear text Secret Text in the SecretText field.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteSecret objects to retrieve.")]
        [PSTypeName('CloudSuiteSecret')]$CloudSuiteSecrets,

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

	# for each CloudSuiteSecret passed
	foreach ($cloudsuitesecret in $CloudSuiteSecrets)
	{
		# if the Secret is a File Secret
		if ($cloudsuitesecret.Type -eq "File")
		{
			Write-Verbose ("Secret [{0}] is a File Secret." -f $cloudsuitesecret.Name)
			continue
		}

		# if the SecretText field is null or empty, skip it
		if ([System.String]::IsNullOrEmpty($cloudsuitesecret.SecretText))
		{
			Write-Verbose ("Secret [{0}] SecretText field is null" -f $cloudsuitesecret.Name)
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
				$keytouse,
				$cloudsuitesecret
			)
			$global:CloudSuiteConnection                         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation                 = $CloudSuiteSessionInformation
			
			$cloudsuitesecret.SecretText = $cloudsuitesecret.decryptSecret($keytouse)
			
			return $cloudsuitesecret
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('keytouse',$keytouse)
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
}# function global:Decrypt-CloudSuiteSecretText
#endregion
###########