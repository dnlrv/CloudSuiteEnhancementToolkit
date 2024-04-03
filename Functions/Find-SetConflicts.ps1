###########
#region ### global:Find-SetConflicts # Finds all Set conflicts in the Cloud Suite tenant
###########
function global:Find-SetConflicts
{
    <#
    .SYNOPSIS
    Finds all Set conflicts in the Cloud Suite tenant.

    .DESCRIPTION
    This cmdlet will find all objects in the Cloud Suite tenant that exist in 2 or more Sets. A Set is a collection of objects 
	in the Cloud Suite, however an object (such as an account or Text Secret) can be a member of multiple Sets. This cmdlet will
	find all Sets where an object exists in two or more Set Collections.

	The returned results are a custom PSObject that has three properties:

	- Name - A string, contains the name of the object.
	- Type - A string, the type of Set where this object is a member.
	- InSets - A string, a comma separated list of all Sets (by name) where this object is a member.
	
    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a custom class object with only 3 properties; Name, SetType, and inSets.

    .EXAMPLE
    C:\PS> Find-SetConflicts
	Finds all objects that exist in multiple sets in the Cloud Suite tenant.

    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
		# no parameters defined
    )

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

    # setting the base query
    $query = "Select ID,Name,ObjectType FROM Sets"

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

	# new ArrayList to hold results
	$Conflicts = New-Object System.Collections.ArrayList

	# find those uuids that appear in 2 or more sets' memberuuids
	$conflictuuids = $objectstack.MemberUuids | Group-Object | Where-Object {$_.Count -gt 1} | Select-Object -ExpandProperty Name

	# for each conflicting uuid found
	foreach ($conflictinguuid in $conflictuuids)
	{
		# gets the SetCollection objects where this Uuid conflicts
		$inSets = ($objectstack | Where-Object {$_.MemberUuids.Contains($conflictinguuid)})

		# narrow down to the set type
		$settype = $inSets | Select-Object -ExpandProperty ObjectType -Unique -First 1

		# placeholder for the name
		$namequery = $null

		# base on which set type it is, get the name of the object using its uuid
		Switch ($settype)
		{
			"VaultAccount" { $namequery = Query-RedRock -SQLQuery ("SELECT (Name || '\' || User) AS Name FROM VaultAccount WHERE ID = '{0}'" -f $conflictinguuid) | Select-Object -ExpandProperty Name; break }
			"Server"       { $namequery = Query-RedRock -SQLQuery ("SELECT Name FROM Server WHERE ID = '{0}'" -f $conflictinguuid) | Select-Object -ExpandProperty Name; break }
			"DataVault"    { $namequery = Query-RedRock -SQLQuery ("SELECT SecretName FROM DataVault WHERE ID = '{0}'" -f $conflictinguuid) | Select-Object -ExpandProperty Name; break }
			default        { $namequery = "UNKNOWNTYPE"; break }
		}# Switch ($settype)

		# custom object to hold the new information
		$obj = New-Object PSObject

		# setting up the information
		$obj | Add-Member -MemberType NoteProperty -Name Name -Value $namequery
		$obj | Add-Member -MemberType NoteProperty -Name Type -Value $settype
		$obj | Add-Member -MemberType NoteProperty -Name InSets -Value ($inSets.Name -join ",")

		$Conflicts.Add($obj) | Out-Null
	}# foreach ($conflictinguuid in $conflictuuids)

	return $Conflicts
}# function global:Find-SetConflicts
#endregion
###########