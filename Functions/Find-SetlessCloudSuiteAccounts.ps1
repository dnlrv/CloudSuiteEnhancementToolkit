###########
#region ### global:Find-SetlessCloudSuiteAccounts # Finds all VaultAccount objects in a Cloud Suite tenant that do not belong to any Set.
###########
function global:Find-SetlessCloudSuiteAccounts
{
    <#
    .SYNOPSIS
    Finds all VaultAccount objects in a Cloud Suite tenant that do not belong to any Set.

    .DESCRIPTION
    This cmdlet will parse all VaultAccount Sets and their members to find any VaultAccounts that do not belong to any VaultAccount Set.

	The returned results are a custom PSObject that has two properties:

	- Name - A string, containing the parent name of the object and the name of the user account.
	- ID - A string, containing UUID of the VaultAccount object.
	
    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a custom class object with only 2 properties; Name, ID.

    .EXAMPLE
    C:\PS> Find-SetlessCloudSuiteAccounts
	Finds all VaultAccount objects in a Cloud Suite tenant that do not belong to any Set.

    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
		# no parameters defined
    )

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

    # setting the base query
    $query = "Select ID,Name,ObjectType FROM Sets WHERE ObjectType = 'VaultAccount' AND CollectionType = 'ManualBucket'"

    Write-Verbose ("SQLQuery: [{0}]" -f $query)

    # making the query for the IDs
    $basesqlquery = Query-RedRock -SQLQuery $query

	Write-Verbose ("basesqlquery objects [{0}]" -f $basesqlquery.Count)

	# ArrayList to hold objects
    $queries = New-Object System.Collections.ArrayList

	# synchronized arraylists to hold our error and object stacks
	$errorstack = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
	$objectstack = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    
    # if the base sqlquery isn't null
    if ($basesqlquery -ne $null)
    {
        # multithread start
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
        $RunspacePool.ApartmentState = 'STA'
        $RunspacePool.ThreadOptions = 'ReUseThread'
        $RunspacePool.Open()

        # jobs ArrayList
        $Jobs = New-Object System.Collections.ArrayList

        foreach ($query in $basesqlquery)
        {
            $PowerShell = [PowerShell]::Create()
            $PowerShell.RunspacePool = $RunspacePool
        
            # Counter for the account objects
            $g++; Write-Progress -Activity "Getting Sets" -Status ("{0} out of {1} Complete" -f $g,$basesqlquery.Count) -PercentComplete ($g/($basesqlquery | Measure-Object | Select-Object -ExpandProperty Count)*100)
            
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
                    $query,
					$errorstack,
					$objectstack
                )
                $global:CloudSuiteConnection         = $CloudSuiteConnection
                $global:CloudSuiteSessionInformation = $CloudSuiteSessionInformation

				$collection = $null
				
				Try # to create a new SetCollections object
				{
					$collection = New-Object SetCollection -ArgumentList ($query.Name, $query.ID, $query.ObjectType)
					#$objectstack.Add($collection) | Out-Null
				}
				Catch
				{
					# if an error occurred during New-Object, create a new CloudSuiteException and return that with the relevant data
					$e = New-Object CloudSuiteException -ArgumentList ("Error during New SetCollection object.")
					$e.AddExceptionData($_)
					$e.AddData("query",$query)
					$e.AddData("collection",$collection)
					$errorstack.Add($e) | Out-Null
				}# Catch

				Try # to get the members of this collection, and add it to the object
				{
					$setmemberuuids = Invoke-CloudSuiteAPI -APICall Collection/GetMembers -Body (@{ID=$collection.ID}|ConvertTo-Json) | Select-Object -ExpandProperty Key

					$collection.AddMembers($setmemberuuids)
				}
				Catch
				{
					# if an error occurred during New-Object, create a new CloudSuiteException and return that with the relevant data
					$e = New-Object CloudSuiteException -ArgumentList ("Error during Get Collection Members/Add Members to SetCollection object.")
					$e.AddExceptionData($_)
					$e.AddData("query",$query)
					$e.AddData("collection",$collection)
					$e.AddData("setmemberuuids",$setmemberuuids)
					$errorstack.Add($e) | Out-Null
				}# Catch

				$objectstack.Add($collection) | Out-Null
            })# [void]$PowerShell.AddScript(
            [void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
            [void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
            [void]$PowerShell.AddParameter('query',$query)
			[void]$PowerShell.AddParameter('errorstack',$errorstack)
			[void]$PowerShell.AddParameter('objectstack',$objectstack)
                
            $JobObject = @{}
            $JobObject.Runspace   = $PowerShell.BeginInvoke()
            $JobObject.PowerShell = $PowerShell
        
            $Jobs.Add($JobObject) | Out-Null
        }# foreach ($query in $basesqlquery)

        foreach ($job in $jobs)
        {
            # Counter for the job objects
            $p++; Write-Progress -Activity "Processing Sets" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
            
            $queries.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
            $job.PowerShell.Dispose()
        }# foreach ($job in $jobs)
    }# if ($query -ne $null)
    else
    {
        return $false
    }

	# setting all the errored into the LastErrorStack
	$global:LastErrorStack = $errorstack

	# get all VaultAccount ids
	$vaultaccountids = Query-RedRock -SQLQuery "Select ID FROM VaultAccount" | Select-Object -ExpandProperty ID

	# now find those that are not in the objectstack memberuuids
	$setlessvaultaccountids = $vaultaccountids | Where-Object {-Not ($objectstack.MemberUuids.Contains($_))}

	$global:setlessvaultaccountids = $setlessvaultaccountids

	# now get the SSNames of those accounts
	if (($setlessvaultaccountids | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
	{
		$returnednames = New-Object System.Collections.ArrayList

		# for each one, get the name and ID of the VaultAccount object
		foreach ($setlessvaultaccountid in $setlessvaultaccountids)
		{
			$namequery = Query-RedRock -SQLQuery ("SELECT (Name || '\' || User) AS Name,ID FROM VaultAccount WHERE ID = '{0}'" -f $setlessvaultaccountid)
			$returnednames.Add($namequery) | Out-Null
		}

		# and return them
		return $returnednames
	}# if (($setlessvaultaccountids | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
	else # otherwise
	{
		# return false
		return $false
	}
}# function global:Find-SetlessCloudSuiteAccounts
#endregion
###########
#>