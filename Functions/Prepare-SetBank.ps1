###########
#region ### global:Prepare-SetBank # Prepares a SetBank of Set and Set Member UUIDs for easier set conflict resolving.
###########
function global:Prepare-SetBank
{
    <#
    .SYNOPSIS
    Prepares a SetBank of Set and Set Member UUIDs for easier set conflict resolving.

    .DESCRIPTION
    This function takes either Account or Secret Set data and finds every Set of that type, and the members
    of that Set and compiles it into a new SetBank object.

    This makes it easier to find Set Conflicts for other classes and functions.
    
    .PARAMETER Type
    Retieve only Account or Secret Sets.

    .EXAMPLE
    C:\PS> Prepare-SetBank -Type Account
    Gets all Account Sets IDs and Set Members IDs from the Cloud Suite Tenant. Returns a SetBank object.

    .EXAMPLE
    C:\PS> Prepare-SetBank -Type Secret
    Gets all Secret Sets IDs and Set Members IDs from the Cloud Suite Tenant. Returns a SetBank object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The type of the SetBank to create.",ParameterSetName = "Type")]
        [ValidateSet("Account","Secret")]
        [System.String]$Type
    )

    # verifying an active Cloud Suite connection
    Verify-CloudSuiteConnection

	# placeholder for type
	[System.String]$banktype = $null

	switch ($Type)
	{
		"Account" { $banktype = "VaultAccount" ; break }
		"Secret"  { $banktype = "DataVault"    ; break }
		default   { break }
	}

	$Sets = Query-RedRock -SQLQuery ("Select Name,ID from Sets WHERE CollectionType = 'ManualBucket' AND ObjectType = '{0}'" -f $banktype)
  $SetBank = New-Object SetBank -ArgumentList ($Type)
    
	# multithread start
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
	$RunspacePool.ApartmentState = 'STA'
	$RunspacePool.ThreadOptions = 'ReUseThread'
	$RunspacePool.Open()

	$Jobs = New-Object System.Collections.ArrayList

	foreach ($set in $Sets)
	{
		$PowerShell = [PowerShell]::Create()
		$PowerShell.RunspacePool = $RunspacePool

		# Counter for the secret objects
		$p++; Write-Progress -Activity "Processing Sets" -Status ("{0} out of {1} Complete" -f $p,$Sets.Count) -PercentComplete ($p/($Sets | Measure-Object | Select-Object -ExpandProperty Count)*100)
            

		# for each script in our CloudSuiteEnhancementToolkitScriptBlocks
		foreach ($script in $global:CloudSuiteEnhancementToolkitScriptBlocks)
		{
			# add it to this thread as a script, this makes all classes and functions available to this thread
			[void]$PowerShell.AddScript($script.ScriptBlock)
		}

		[void]$PowerShell.AddScript(
		{
			Param
			(
				$CloudSuiteConnection,
				$CloudSuiteSessionInformation,
				$set
			)
			$global:CloudSuiteConnection         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation = $CloudSuiteSessionInformation

			$obj = New-Object SetMember -ArgumentList ($set.Name, $set.ID)

			$members = Invoke-CloudSuiteAPI -APICall Collection/GetMembers -Body (@{ID=$set.ID} | ConvertTo-Json)

            $obj.addMembers($members)
			
			return $obj
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
		[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
		[void]$PowerShell.AddParameter('set',$set)
			
		$JobObject = @{}
		$JobObject.Runspace   = $PowerShell.BeginInvoke()
		$JobObject.PowerShell = $PowerShell
	
		$Jobs.Add($JobObject) | Out-Null
	}# foreach ($query in $basesqlquery)

	foreach ($job in $jobs)
	{
		# Counter for the job objects
		$j++; Write-Progress -Activity "Processing Sets" -Status ("{0} out of {1} Complete" -f $j,$jobs.Count) -PercentComplete ($j/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$SetBank.AddSets($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)
	
	return $SetBank
}# global:Prepare-SetBank
#endregion
###########