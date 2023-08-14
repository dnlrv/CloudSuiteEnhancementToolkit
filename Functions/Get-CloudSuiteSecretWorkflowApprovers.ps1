###########
#region ### global:Get-CloudSuiteSecretWorkflowApprovers # Gets all Workflow Approvers for a Secret
###########
function global:Get-CloudSuiteSecretWorkflowApprovers
{
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the secret to search.",ParameterSetName = "Name")]
        [System.String]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the secret to search.",ParameterSetName = "Uuid")]
        [System.String]$Uuid
    )

    # if the Name parameter was used
    if ($PSBoundParameters.ContainsKey("Name"))
    {
        # getting the uuid of the object
        $uuid = Get-CloudSuiteObjectUuid -Type Secret -Name $Name
    }

    # getting the original approvers by API call
    $approvers = Invoke-CloudSuiteAPI -APICall ServerManage/GetSecretApprovers -Body (@{ ID = $uuid } | ConvertTo-Json)

    # preparing the workflow approver list
    $WorkflowApprovers = Prepare-WorkflowApprovers -Approvers ($approvers.WorkflowApproversList)
    
    # returning the ArrayList
    return $WorkflowApprovers
}# function global:Get-CloudSuiteSecretWorkflowApprovers
#endregion
###########