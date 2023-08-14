###########
#region ### global:ConvertFrom-DataToCloudSuiteRole # Converts stored data back into a CloudSuiteRole object with class methods
###########
function global:ConvertFrom-DataToCloudSuiteRole
{
    <#
    .SYNOPSIS
    Converts CloudSuiteRole-data back into a CloudSuiteRole object. Returns an ArrayList of CloudSuiteRole class objects.

    .DESCRIPTION
    This function will take data that was created from a CloudSuiteRole class object, and recreate that CloudSuiteRole
    class object that has all available methods for a CloudSuiteRole object. This is returned as an ArrayList of CloudSuiteRole
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataRoles
    Provides the data for CloudSuiteRole.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of CloudSuiteRole class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToCloudSuiteRole -DataRoles $DataRoles
    Converts  CloudSuiteRole-data into a CloudSuiteRole class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteRole data to convert to a CloudSuiteRole object.")]
        [PSCustomObject[]]$DataRoles
    )

    # a new ArrayList to return
    $NewCloudSuiteRoles = New-Object System.Collections.ArrayList

    # for each set object in our Data data
    foreach ($cloudsuiterole in $DataRoles)
    {
        # new empty CloudSuiteRole object
        $obj = New-Object CloudSuiteRole

		$obj.ID                   = $cloudsuiterole.ID
		$obj.Name                 = $cloudsuiterole.Name
		$obj.RoleType             = $cloudsuiterole.RoleType
		$obj.ReadOnly             = $cloudsuiterole.ReadOnly
		$obj.Description          = $cloudsuiterole.Description
		$obj.DirectoryServiceUuid = $cloudsuiterole.DirectoryServiceUuid

		# new ArrayList for the Members property
		$members = New-Object System.Collections.ArrayList

		# for each Member in our CloudSuiteRole object
		foreach ($member in $cloudsuiterole.Members)
		{
			# create a new RoleMember object from that member data
			$mem = New-Object CloudSuiteRoleMember -ArgumentList ($member)

			# add it to the PermissionRowAces ArrayList
			$members.Add($mem) | Out-Null
		}# foreach ($member in $cloudsuiterole.Members)

		# add these Members to our CloudSuiteRole object
		$obj.Members = $members

		# new ArrayList for the AssignedRights property
		$assignedrights = New-Object System.Collections.ArrayList

		# for each assigned right in our CloudSuiteRole object
		foreach ($assignedright in $cloudsuiterole.AssignedRights)
		{
			# create a new CloudSuiteRoleAssignedRights object from that member data
			$rights = New-Object CloudSuiteRoleAssignedRights -ArgumentList ($assignedright)

			# add it to the PermissionRowAces ArrayList
			$assignedrights.Add($rights) | Out-Null
		}# foreach ($member in $cloudsuiterole.Members)

		# add these AssignedRights to our CloudSuiteRole object
		$obj.AssignedRights = $assignedrights

		# add this object to our return ArrayList
        $NewCloudSuiteRoles.Add($obj) | Out-Null
	}# foreach ($cloudsuiterole in $DataRoles)

    # return the ArrayList
    return $NewCloudSuiteRoles
}# function global:ConvertFrom-DataToCloudSuiteRole
#endregion
###########