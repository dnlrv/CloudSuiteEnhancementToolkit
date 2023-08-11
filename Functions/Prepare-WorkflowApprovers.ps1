###########
#region ### global:Prepare-WorkflowApprovers # Prepares Workflow Approvers
###########
function global:Prepare-WorkflowApprovers
{
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The Workflow Approvers converted from.")]
        $Approvers
    )

    # setting a new ArrayList object
    $WorkflowApprovers = New-Object System.Collections.ArrayList

    # for each workflow approver
    foreach ($approver in $Approvers)
    {        
        # if the approver contains the NoManagerAction AND the BackupApprover Properties
        if ($approver.NoManagerAction -ne $null -and $approver.BackupApprover -ne $null)
        {
            # then this is a specified backup approver
            $backup = $approver.BackupApprover

            # search for that approver that is listed in the $approver.BackupApprover property
            if ($backup.ObjectType -eq "Role")
            {
                $approver = Get-CloudSuiteWorkflowApprover -Role $backup.Name
            }
            else
            {
                $approver = Get-CloudSuiteWorkflowApprover -User $backup.Name
            }
            
            # create our new CloudSuiteWorkflowApprover object with the isBackup property set to true
            $obj = New-Object CloudSuiteWorkflowApprover -ArgumentList ($approver, $true)
        }
        # otherwise if the NoManagerAction exists and it contains either "approve" or "deny"
        elseif ($approver.NoManagerAction -eq "approve" -or ($approver.NoManagerAction -eq "deny"))
        {
            # create our new CloudSuiteWorkflowApprover object with the isBackup property set to true
            $obj = New-Object CloudSuiteWorkflowApprover -ArgumentList ($approver, $true)
        }
        else # otherwise, it was a listed approver, and we can just
        {
            # create our new CloudSuiteWorkflowApprover object with the isBackup property set to false
            $obj = New-Object CloudSuiteWorkflowApprover -ArgumentList ($approver, $false)
        }

        # adding it to our ArrayList
        $WorkflowApprovers.Add($obj) | Out-Null
    }# foreach ($approver in $approvers.WorkflowApproversList)

    # returning the ArrayList
    return $WorkflowApprovers
}# function global:Prepare-WorkflowApprovers
#endregion
###########