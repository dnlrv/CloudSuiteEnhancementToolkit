###########
#region ### global:ConvertFrom-DataToCloudSuiteSecret # Converts stored data back into a CloudSuiteSecret object with class methods
###########
function global:ConvertFrom-DataToCloudSuiteSecret
{
    <#
    .SYNOPSIS
    Converts CloudSuiteSecret-data back into a CloudSuiteSecret object. Returns an ArrayList of CloudSuiteSecret class objects.

    .DESCRIPTION
    This function will take data that was created from a CloudSuiteSecret class object, and recreate that CloudSuiteSecret
    class object that has all available methods for a CloudSuiteSecret object. This is returned as an ArrayList of CloudSuiteSecret
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataSecrets
    Provides the data for CloudSuiteSecret.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of CloudSuiteSecret class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToCloudSuiteSecret -DataSecrets $DataSecrets
    Converts  CloudSuiteSecret-data into a CloudSuiteSecret class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuiteSecret data to convert to a CloudSuiteSecret object.")]
        [PSCustomObject[]]$DataSecrets
    )

    # a new ArrayList to return
    $NewCloudSuiteSecrets = New-Object System.Collections.ArrayList

    # for each set object in our Data data
    foreach ($cloudsuitesecret in $DataSecrets)
    {
		# new empty CloudSuiteSet object
        $obj = New-Object CloudSuiteSecret

        # copying information over
        $obj.Name            = $cloudsuitesecret.Name
        $obj.Type            = $cloudsuitesecret.Type
        $obj.ParentPath      = $cloudsuitesecret.ParentPath
        $obj.Description     = $cloudsuitesecret.Description
        $obj.ID              = $cloudsuitesecret.ID
        $obj.FolderId        = $cloudsuitesecret.FolderId
        $obj.SecretText      = $cloudsuitesecret.SecretText
        $obj.SecretFileName  = $cloudsuitesecret.SecretFileName
        $obj.SecretFileSize  = $cloudsuitesecret.SecretFileSize
        $obj.SecretFilePath  = $cloudsuitesecret.SecretFilePath
        $obj.WorkflowEnabled = $cloudsuitesecret.WorkflowEnabled

        # DateTime null checks
        if ($cloudsuitesecret.whenCreated -ne $null)   { $obj.whenCreated   = $cloudsuitesecret.whenCreated   }
        if ($cloudsuitesecret.whenModified -ne $null)  { $obj.whenModified  = $cloudsuitesecret.whenModified  }
        if ($cloudsuitesecret.lastRetrieved -ne $null) { $obj.lastRetrieved = $cloudsuitesecret.lastRetrieved } 

        # new ArrayList for the RowAces property
        $rowaces = New-Object System.Collections.ArrayList

        # for each RowAce in our CloudSuiteSecret object
        foreach ($rowace in $cloudsuitesecret.RowAces)
        {
            # create a new CloudSuiteRowAce object from that rowace data
		    $pra = New-Object PermissionRowAce -ArgumentList ($rowace)

            # add it to the RowAces ArrayList
            $rowaces.Add($pra) | Out-Null
        }# foreach ($rowace in $cloudsuitesecret.RowAces)

        # add these row aces to our CloudSuiteSecret object
        $obj.RowAces = $rowaces

        # new ArrayList for the WorkflowApprovers property
        $approvers = New-Object System.Collections.ArrayList

        # for each approver in our CloudSuiteSecret object
        foreach ($approver in $cloudsuitesecret.WorkflowApprovers)
        {
			$aprv = New-Object CloudSuiteWorkflowApprover -ArgumentList ($approver, $approver.isBackUp)

            # add it to the approvers ArrayList
            $approvers.Add($aprv) | Out-Null
        }# foreach ($approver in $cloudsuitesecret.WorkflowApprovers)

        # add these approvers to our CloudSuiteSecret object
        $obj.WorkflowApprovers = $approvers
        
        # add this object to our return ArrayList
        $NewCloudSuiteSecrets.Add($obj) | Out-Null
    }# foreach ($cloudsuitesecret in $DataSecrets)

    # return the ArrayList
    return $NewCloudSuiteSecrets
}# function global:ConvertFrom-DataToCloudSuiteAccount
#endregion
###########