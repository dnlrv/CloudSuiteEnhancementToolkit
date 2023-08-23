###########
#region ### global:Convert-OtherToMigratedCredential # Generic catch-all convert something to a MigratedCredential class object 
###########
function global:Convert-OtherToMigratedCredential
{
    <#
    .SYNOPSIS
    Converts generic data into a MigratedCredential class object.

    .DESCRIPTION
    This function provides a generic means to create a MigratedCredential class object from outside data. Typically from .csv data.

    .PARAMETER SecretTemplate
    The name of the Secret Template to use.

    .PARAMETER SecretName
    The name of the Secret as it should appear in Secret Server.

    .PARAMETER Target
    The Target for the Secret, this would be the FQDN of the hostname for a local account,
    the domain for a domain account, etc.

    .PARAMETER Username
    The username for the Secret.

    .PARAMETER Folder
    The name of the Secret Secret Folder where this Secret should be created.
    
    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteAccount class object.

    .EXAMPLE
    C:\PS> Convert-OtherToMigratedCredential -SecretTemplate "Windows Account" -SecretName "Server01\Administrator"
        -Target "Server01.domain.com" -Username "Administrator" -Folder "Local Windows Admin Accounts"
    Creates a MigratedCredential class with the specified information from the provided parameters.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $false, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [System.String]$SecretTemplate,

		[Parameter(Mandatory = $false, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [System.String]$SecretName,

		[Parameter(Mandatory = $false, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [System.String]$Target,

		[Parameter(Mandatory = $false, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [System.String]$Username,

		[Parameter(Mandatory = $false, HelpMessage = "The CloudSuiteAccounts to convert.")]
        [System.String]$Folder
    )

	$MigratedCredential = New-Object MigratedCredential

	# setting values that may have been passed
	if ($PSBoundParameters.ContainsKey('SecretTemplate')) { $MigratedCredential.SecretTemplate = $SecretTemplate }
	if ($PSBoundParameters.ContainsKey('SecretName'))     { $MigratedCredential.SecretName = $SecretName }
	if ($PSBoundParameters.ContainsKey('Target'))         { $MigratedCredential.Target = $Target }
	if ($PSBoundParameters.ContainsKey('Username'))       { $MigratedCredential.Username = $Username }
	if ($PSBoundParameters.ContainsKey('Folder'))         { $MigratedCredential.Folder = $Folder }

	return $MigratedCredential
}# function global:Convert-OtherToMigratedCredential
#endregion
###########