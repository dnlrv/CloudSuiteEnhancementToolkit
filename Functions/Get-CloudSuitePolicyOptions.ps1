###########
#region ### global:Get-CloudSuitePolicyOptions # Gets the Policy Options that apply to this Server or CloudSuiteAccount object
###########
function global:Get-CloudSuitePolicyOptions
{
    <#
    .SYNOPSIS
    Gets the Policy Options that apply to this Server or CloudSuiteAccount object.

    .DESCRIPTION
	Get the Policy options, source and values from the Delinea Cloud Suite. This returns an ArrayList of CloudSuitePolicyOption
	class objects containing the name of the policy option, where the policy option is set from, and the value associated with this policy option.

    .PARAMETER EntityId
    The UUID of the object to search.

    .PARAMETER TableName
    The Table to search with SQL. Only supports "Server" or "VaultAccount" options.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of CloudSuitePolicyOption class objects.

    .EXAMPLE
    C:\PS> Get-CloudSuiteRole -EntityId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -TableName VaultAccount
    Gets the policy options for the CloudSuiteAccount with the ID of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.

    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the Role to search.", ParameterSetName = "Name")]
        [System.String]$EntityId,

        [Parameter(Mandatory = $false, HelpMessage = "A limit on number of objects to query.")]
		[ValidateSet("Server","VaultAccount")]
        [System.String]$TableName
    )

    # verify an active CloudSuite connection
    Verify-CloudSuiteConnection

	# get the Policy stack for this entity
	$policystack = Invoke-CLoudSuiteAPI -APICall ServerManage/GetRsop -Body (@{EntityId=$EntityId;TableName=$TableName} | ConvertTo-Json)

	# get the names from the members of the PSObject itself
	$policynames = $policystack.contributingPolicies.PSObject.Members | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -ExpandProperty Name

	# new ArrayList for returning policy options
	$PolicyOptions = New-Object System.Collections.ArrayList

	# for each policy name returned
	foreach ($policyname in $policynames)
	{
		# get the source policy and the policy value
		$frompolicy = $policystack.contributingPolicies.("{0}" -f $policyname)
		$policyvalue = $policystack.rsop.("{0}" -f $policyname)

		# create a new CloudSuitePolicyOption object
		$obj = New-Object CloudSuitePolicyOption -ArgumentList ($policyname, $frompolicy, $policyvalue)

		# add it to the ArrayList
		$PolicyOptions.Add($obj) | Out-Null
	}# foreach ($policyname in $policynames)

	# return the ArrayList
	return $PolicyOptions
}# function global:Get-CloudSuitePolicyOptions
#endregion
###########