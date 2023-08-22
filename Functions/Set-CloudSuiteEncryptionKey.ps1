###########
#region ### global:Set-CloudSuiteEncryptionKey # Sets the global encryption key to use for encrypted password checkouts and secret text retrieves
###########
function global:Set-CloudSuiteEncryptionKey
{
    <#
    .SYNOPSIS
    This function will set the global variable encryption key for symmetric encrypted SecureStrings used with this toolkit.

    .DESCRIPTION
	This function will prompt you for a passphrase string to turn into an encryption key for use with all CloudSuiteAccount
	and CloudSuiteSecret objects.

	By default, when you .checkoutPassword() or .retrieveSecret() on those objects, the password or secret text will be
	encrypted using this encryption key. You will then need to use the .decryptPassword() or .exposeSecret() methods to
	with the same key to convert them into their plain-text versions.

    .INPUTS
    A System.String  or System.Security.SecureString can be piped in to create the key.

    .OUTPUTS
    This function only outputs a System.Byte[] array if the -ReturnAsVariable switch is used.

    .EXAMPLE
    C:\PS> Set-CloudSuiteEncryptionKey
	This function will prompt the user for a string passphrase. With this passphrase set, it will encrypt all
	passwords and secrets it retrieves from the Cloud Suite tenant with this passphrase.

	.EXAMPLE
    C:\PS> $key = Set-CloudSuiteEncryptionKey -ReturnAsVariable
    This function will prompt the user for a string passphrase. It will then convert the passphrase into a key
	and return it to the user as a System.Byte[] object.

	.EXAMPLE
	C:\PS> "myPassphrase" | Set-CloudSuiteEncryptionKey
	This function will take the pipeline input ("myPassphrase") to use as the string to create the encryption
	key. This version of the function use is more intended for non-interactive creations of encryption keys, 
	especially in conjunction with auto retrieval of strings from other mechanisms.
	#>
	[CmdletBinding(DefaultParameterSetName="Prompt")]
    param
    (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline=$true, HelpMessage = "The .", ParameterSetName="Pipeline")]
		[PSObject]$Pipeline,

        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Return the key as a variable instead of setting it as global.", ParameterSetName="Prompt")]
		[Parameter(Position = 0, Mandatory = $false, HelpMessage = "Return the key as a variable instead of setting it as global.", ParameterSetName="Pipeline")]
        [Switch]$ReturnAsVariable
    )

	# if the pipeline was used
	if ($PSCmdlet.ParameterSetName -eq "Pipeline")
	{
		# if the piped in object is a String
		if ($Pipeline.GetType().Name -eq "String")
		{
			$prompt = ConvertTo-SecureString -String $Pipeline -AsPlainText -Force
		}
		elseif ($Pipeline.GetType().Name -eq "SecureString")
		{
			$prompt = $Pipeline
		}
		else
		{
			throw "The input is neither a String or a SecureString."
		}
	}# if ($PSCmdlet.ParameterSetName -eq "Pipeline")
	else
	{
		# prompt the user for the passphrase
		$prompt = Read-Host -Prompt "Enter Passphrase" -AsSecureString
	}

	# getting the basephrase
	$basephrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($prompt))))

	# convert the basephrase to a md5 hash
    $md5  = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($basephrase)))

	# remove hyphens
    $hash = $hash -replace '-', ''

	# new secure key ArrayList object
	$securekey = New-Object System.Collections.ArrayList

	# convert our hash into a 8-bit unsigned integer array and add it to our ArrayList
	$securekey.AddRange(@([System.Convert]::FromBase64String(($hash)))) | Out-Null

	# if -ReturnAsVariable was used
	if ($ReturnAsVariable.IsPresent)
	{
		return $securekey
	}
	else # otherwise
	{
		# set it as our global encryption key
		$global:CloudSuiteEncryptedKey = $securekey
	}
}# function global:Set-CloudSuiteEncryptionKey 
#endregion
###########