###########
#region ### global:ConvertFrom-DataToMigratedCredential # Converts stored data back into a MigratedCredential object with class methods
###########
function global:ConvertFrom-DataToMigratedCredential
{
    <#
    .SYNOPSIS
    Converts MigratedCredential-data back into a MigratedCredential object. Returns an ArrayList of MigratedCredential class objects.

    .DESCRIPTION
    This function will take data that was created from a MigratedCredential class object, and recreate that MigratedCredential
    class object that has all available methods for a MigratedCredential object. This is returned as an ArrayList of MigratedCredential
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataMigratedCredentials
    Provides the data for MigratedCredential.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of MigratedCredential class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToMigratedCredential -DataMigratedCredentials $DataMigratedCredentials
    Converts  MigratedCredential-data into a MigratedCredential class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The MigratedCredential data to convert to a MigratedCredential object.")]
        [PSCustomObject[]]$DataMigratedCredentials
    )

    # a new ArrayList to return
    $NewMigratedCredentials = New-Object System.Collections.ArrayList

    # for each set object in our Data data
    foreach ($migratedcredential in $DataMigratedCredentials)
    {
        # new empty MigratedCredential object
        $obj = New-Object MigratedCredential

		# resetting properties
		$obj.SecretTemplate = $migratedcredential.SecretTemplate
		$obj.SecretName     = $migratedcredential.SecretName
		$obj.Target         = $migratedcredential.Target
		$obj.Username       = $migratedcredential.Username
		$obj.Password       = $migratedcredential.Password
		$obj.Folder         = $migratedcredential.Folder
		$obj.hasConflicts   = $migratedcredential.hasConflicts
		$obj.PASDataType    = $migratedcredential.PASDataType
		$obj.PASUUID        = $migratedcredential.PASUUID
		$obj.Slugs          = $migratedcredential.Slugs
		$obj.OriginalObject = $migratedcredential.OriginalObject

		# adding member of Sets if there is something to add
		if (($migratedcredential.MemberofSets | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			$obj.memberofSets.AddRange(@($migratedcredential.memberofSets)) | Out-Null
		}

		# adding Permissions if there is something to add
		if (($migratedcredential.Permissions | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			$obj.Permissions.AddRange(@($migratedcredential.Permissions)) | Out-Null
		}
		
		# adding Folder Permissions of Sets if there is something to add
		if (($migratedcredential.FolderPermissions | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			$obj.FolderPermissions.AddRange(@($migratedcredential.FolderPermissions)) | Out-Null
		}

		# adding Set Permissions if there is something to add
		if (($migratedcredential.SetPermissions | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
		{
			$obj.SetPermissions.AddRange(@($migratedcredential.SetPermissions)) | Out-Null
		}

		# adding it to our ArrayList
		$NewMigratedCredentials.Add($obj) | Out-Null
	}

    # return the ArrayList
    return $NewMigratedCredentials
}# function global:ConvertFrom-DataToMigratedCredential
#endregion
###########