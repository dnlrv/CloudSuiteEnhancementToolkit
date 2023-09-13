###########
#region ### global:ConvertFrom-DataToCloudSuiteAccount # Converts stored data back into a CloudSuiteAccount object with class methods
###########
function global:ConvertFrom-DataToCloudSuiteAccount
{
    <#
    .SYNOPSIS
    Converts CloudSuiteAccount-data back into a CloudSuiteAccount object. Returns an ArrayList of CloudSuiteAccount class objects.

    .DESCRIPTION
    This function will take data that was created from a CloudSuiteAccount class object, and recreate that CloudSuiteAccount
    class object that has all available methods for a CloudSuiteAccount object. This is returned as an ArrayList of CloudSuiteAccount
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataAccounts
    Provides the data for CloudSuiteAccount.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of CloudSuiteAccount class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToCloudSuiteAccount -DataAccounts $DataAccounts
    Converts  CloudSuiteAccount-data into a CloudSuiteAccount class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteAccount data to convert to a CloudSuiteAccount object.")]
        [PSCustomObject[]]$DataAccounts
    )

    # a new ArrayList to return
    $NewCloudSuiteAccounts = New-Object System.Collections.ArrayList

    # for each set object in our Data data
    foreach ($CloudSuiteaccount in $DataAccounts)
    {
        # new empty CloudSuiteAccount object
        $obj = New-Object CloudSuiteAccount

        # copying information over
        $obj.AccountType         = $CloudSuiteaccount.AccountType
        $obj.ComputerClass       = $CloudSuiteaccount.ComputerClass
        $obj.SourceName          = $CloudSuiteaccount.SourceName
        $obj.SourceType          = $CloudSuiteaccount.SourceType
        $obj.SourceID            = $CloudSuiteaccount.SourceID
        $obj.Username            = $CloudSuiteaccount.Username
        $obj.ID                  = $CloudSuiteaccount.ID
        $obj.isManaged           = $CloudSuiteaccount.isManaged
        $obj.Healthy             = $CloudSuiteaccount.Healthy
        $obj.Password            = $CloudSuiteaccount.Password
        $obj.Description         = $CloudSuiteaccount.Description
        $obj.WorkflowEnabled     = $CloudSuiteaccount.WorkflowEnabled
        $obj.SSName              = $CloudSuiteaccount.SSName
        $obj.CheckOutID          = $CloudSuiteaccount.CheckOutID
		$obj.DatabaseClass       = $CloudSuiteaccount.DatabaseClass
		$obj.DatabasePort        = $CloudSuiteaccount.DatabasePort
		$obj.DatabaseServiceName = $CloudSuiteaccount.DatabaseServiceName
		$obj.DatabaseSSLEnabled  = $CloudSuiteaccount.DatabaseSSLEnabled

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

		# new ArrayList for the CloudSuiteAccount property
		$accountevents = New-Object System.Collections.ArrayList

		# for each accountevent in our AccountEvent object
		foreach ($accountevent in $CloudSuiteaccount.AccountEvents)
		{
			$event = New-Object CloudSuiteAccountEvent -ArgumentList ($accountevent)

			# add it to the accountevents ArrayList
			$accountevents.Add($event) | Out-Null
		}# foreach ($accountevent in $CloudSuiteaccount.AccountEvents)

		# add these accountevents to our CloudSuiteAccount object
		$obj.AccountEvents = $accountevents
        
        # add this object to our return ArrayList
        $NewCloudSuiteAccounts.Add($obj) | Out-Null
    }# foreach ($CloudSuiteaccount in $DataAccounts)

    # return the ArrayList
    return $NewCloudSuiteAccounts
}# function global:ConvertFrom-DataToCloudSuiteAccount
#endregion
###########