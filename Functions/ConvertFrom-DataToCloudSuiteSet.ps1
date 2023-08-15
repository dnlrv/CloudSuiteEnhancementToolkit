###########
#region ### global:ConvertFrom-DataToCloudSuiteSet # Converts stored data back into a CloudSuiteSet object with class methods
###########
function global:ConvertFrom-DataToCloudSuiteSet
{
    <#
    .SYNOPSIS
    Converts CloudSuiteSet-data back into a CloudSuiteSet object. Returns an ArrayList of CloudSuiteSet class objects.

    .DESCRIPTION
    This function will take data that was created from a CloudSuiteSet class object, and recreate that CloudSuiteSet
    class object that has all available methods for a CloudSuiteSet object. This is returned as an ArrayList of CloudSuiteSet
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataAccounts
    Provides the data for CloudSuiteSet.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of CloudSuiteSet class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToCloudSuiteSet -DataAccounts $DataAccounts
    Converts CloudSuiteSet-data into a CloudSuiteSet class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteSet data to convert to a CloudSuiteSet object.")]
        [PSCustomObject[]]$DataSets
    )

	# a new ArrayList to return
	$NewCloudSuiteSets = New-Object System.Collections.ArrayList

	# for each set object in our Data data
    foreach ($cloudsuiteset in $DataSets)
    {
        # new empty CloudSuiteSet object
        $obj = New-Object CloudSuiteSet

        # copying information over
        $obj.SetType        = $cloudsuiteset.SetType
        $obj.ObjectType     = $cloudsuiteset.ObjectType
        $obj.Name           = $cloudsuiteset.Name
        $obj.ID             = $cloudsuiteset.ID
        $obj.whenCreated    = $cloudsuiteset.whenCreated
        $obj.ParentPath     = $cloudsuiteset.ParentPath
        $obj.PotentialOwner = $cloudsuiteset.PotentialOwner

        # new ArrayList for the PermissionRowAces property
        $rowaces = New-Object System.Collections.ArrayList

        # for each PermissionRowAce in our CloudSuiteSet object
        foreach ($permissionrowace in $cloudsuiteset.PermissionRowAces)
        {
            # create a new PermissionRowAce object from that rowace data
            $pra = New-Object PermissionRowAce -ArgumentList ($permissionrowace)

            # add it to the PermissionRowAces ArrayList
            $rowaces.Add($pra) | Out-Null
        }# foreach ($permissionrowace in $cloudsuiteset.PermissionRowAces)

        # add these permission row aces to our CloudSuiteSet object
        $obj.PermissionRowAces = $rowaces

        # new ArrayList for the PermissionRowAces property
        $memberrowaces = New-Object System.Collections.ArrayList

        # for each MemberPermissionRowAce in our CloudSuiteSet object
        foreach ($memberrowace in $cloudsuiteset.MemberPermissionRowAces)
        {
            # create a new PermissionRowAce object from that rowace data
            $pra = New-Object PermissionRowAce -ArgumentList ($memberrowace)
            
            # add it to the MemberPermissionRowAces ArrayList
            $memberrowaces.Add($pra) | Out-Null
        }# foreach ($memberrowace in $cloudsuiteset.MemberPermissionRowAces)

        # add these permission row aces to our CloudSuiteSet object
        $obj.MemberPermissionRowAces = $memberrowaces

        # for each setmember in our CloudSuiteSet object
        foreach ($setmember in $cloudsuiteset.SetMembers)
        {
            # create a new SetMember object from that setmember data
			$setmem = New-Object SetMember -ArgumentList ($setmember.Name, $setmember.Type, $setmember.Uuid)

            # add it to our SetMembers ArrayList
            $obj.SetMembers.Add($setmem) | Out-Null
        }# foreach ($setmember in $cloudsuiteset.SetMembers)

		# adding the member Uuids
		$obj.MembersUuid.AddRange(@($cloudsuiteset.MembersUuid)) | Out-Null

        # add this object to our return ArrayList
        $NewCloudSuiteSets.Add($obj) | Out-Null
    }# foreach ($cloudsuiteset in $DataSets)

    # return the ArrayList
    return $NewCloudSuiteSets

















    # a new ArrayList to return
    $NewCloudSuiteSets = New-Object System.Collections.ArrayList

    # for each set object in our Data data
    foreach ($CloudSuiteSet in $DataSets)
    {
        # new empty CloudSuiteSet object
        $obj = New-Object CloudSuiteSet

        # copying information over
        $obj.AccountType     = $CloudSuiteSet.AccountType
        $obj.ComputerClass   = $CloudSuiteSet.ComputerClass
        $obj.SourceName      = $CloudSuiteSet.SourceName
        $obj.SourceType      = $CloudSuiteSet.SourceType
        $obj.SourceID        = $CloudSuiteSet.SourceID
        $obj.Username        = $CloudSuiteSet.Username
        $obj.ID              = $CloudSuiteSet.ID
        $obj.isManaged       = $CloudSuiteSet.isManaged
        $obj.Healthy         = $CloudSuiteSet.Healthy
        $obj.Password        = $CloudSuiteSet.Password
        $obj.Description     = $CloudSuiteSet.Description
        $obj.WorkflowEnabled = $CloudSuiteSet.WorkflowEnabled
        $obj.SSName          = $CloudSuiteSet.SSName
        $obj.CheckOutID      = $CloudSuiteSet.CheckOutID

        # DateTime null checks
        if ($CloudSuiteaccount.LastChange -ne $null)      { $obj.LastChange      = $CloudSuiteaccount.LastChange      }
        if ($CloudSuiteaccount.LastHealthCheck -ne $null) { $obj.LastHealthCheck = $CloudSuiteaccount.LastHealthCheck }

		# if the vault is not null
        if ($CloudSuiteaccount.Vault -ne $null)
		{
			# new CloudSuiteVault object and add that to this object
			$obj.Vault = New-Object CloudSuiteVault -ArgumentList ($CloudSuiteaccount.Vault)
		}

        # new ArrayList for the PermissionRowAces property
        $rowaces = New-Object System.Collections.ArrayList

        # for each PermissionRowAce in our CloudSuiteAccount object
        foreach ($permissionrowace in $CloudSuiteaccount.PermissionRowAces)
        {
            # create a new CloudSuiteRowAce object from that rowace data
            $pra = New-Object PermissionRowAce -ArgumentList $permissionrowace

            # add it to the PermissionRowAces ArrayList
            $rowaces.Add($pra) | Out-Null
        }# foreach ($permissionrowace in $CloudSuiteaccount.PermissionRowAces)

        # add these permission row aces to our CloudSuiteAccount object
        $obj.PermissionRowAces = $rowaces

        # new ArrayList for the WorkflowApprovers property
        $approvers = New-Object System.Collections.ArrayList

        # for each approver in our CloudSuiteAccount object
        foreach ($approver in $CloudSuiteaccount.WorkflowApprovers)
        {
            $aprv = New-Object CloudSuiteWorkflowApprover -ArgumentList ($approver, $approver.isBackUp)

            # add it to the approvers ArrayList
            $approvers.Add($aprv) | Out-Null
        }# foreach ($approver in $CloudSuiteaccount.WorkflowApprovers)

        # add these approvers to our CloudSuiteAccount object
        $obj.WorkflowApprovers = $approvers
        
        # add this object to our return ArrayList
        $NewCloudSuiteAccounts.Add($obj) | Out-Null
    }# foreach ($CloudSuiteaccount in $DataAccounts)

    # return the ArrayList
    return $NewCloudSuiteAccounts
}# function global:ConvertFrom-DataToCloudSuiteSet
#endregion
###########