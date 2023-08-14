###########
#region ### global:Get-CloudSuiteRole # Gets CloudSuite Role objects, along with the role's Members and Assigned Adminisrtative Rights
###########
function global:Get-CloudSuiteRole
{
    <#
    .SYNOPSIS
    Gets a Role object from the Delinea Cloud Suite.

    .DESCRIPTION
    Gets a Role object from the Delinea Cloud Suite. This returns a CloudSuiteRole class object containing properties about
    the Role object. By default, Get-CloudSuiteRole without any parameters will get all Role objects in the CloudSuite. 

    .PARAMETER Name
    Gets only Roles with this name.

    .PARAMETER Limit
    Limits the number of potential Role objects returned.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteRole class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteRole
    Gets all Role objects from the Delinea Cloud Suite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteRole -Limit 10
    Gets 10 Role objects from the Delinea Cloud Suite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteRole -Name "Infrastructure Team"
    Gets all Role objects with the Name "Infrastructure Team".
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the Role to search.", ParameterSetName = "Name")]
        [System.String]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "A limit on number of objects to query.")]
        [System.Int32]$Limit
    )

    # verify an active CloudSuite connection
    Verify-CloudSuiteConnection

    # set the base query
    $query = "Select * FROM Role"

    # arraylist for extra options
    $extras = New-Object System.Collections.ArrayList

    # if the All set was not used
    if ($PSCmdlet.ParameterSetName -ne "All")
    {
        # appending the WHERE 
        $query += " WHERE "
        
        if ($PSBoundParameters.ContainsKey("Name")) { $extras.Add(("Name = '{0}'" -f $Name)) | Out-Null }
        # if ($PSBoundParameters.ContainsKey("SuppressPrincipalsList")) { $extras.Add(("SuppressPrincipalsList = '{0}'" -f $FQDN)) | Out-Null }

        # join them together with " AND " and append it to the query
        $query += ($extras -join " AND ")
    }# if ($PSCmdlet.ParameterSetName -ne "All")

    # if Limit was used, append it to the query
    if ($PSBoundParameters.ContainsKey("Limit")) { $query += (" LIMIT {0}" -f $Limit) }

    Write-Verbose ("SQLQuery: [{0}]" -f $query)

    # making the query
    $basesqlquery = Query-RedRock -SQLQuery $query

    # ArrayList to hold objects
    $queries = New-Object System.Collections.ArrayList


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
			$g++; Write-Progress -Activity "Getting Roles" -Status ("{0} out of {1} Complete" -f $g,$basesqlquery.Count) -PercentComplete ($g/($basesqlquery | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
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
					$query
				)
				$global:CloudSuiteConnection         = $CloudSuiteConnection
				$global:CloudSuiteSessionInformation = $CloudSuiteSessionInformation

				# create a new CloudSuite Account object
				$role = New-Object CloudSuiteRole -ArgumentList ($query)

				return $role
		
			})# [void]$PowerShell.AddScript(
			[void]$PowerShell.AddParameter('CloudSuiteConnection',$global:CloudSuiteConnection)
			[void]$PowerShell.AddParameter('CloudSuiteSessionInformation',$global:CloudSuiteSessionInformation)
			[void]$PowerShell.AddParameter('query',$query)
				
			$JobObject = @{}
			$JobObject.Runspace   = $PowerShell.BeginInvoke()
			$JobObject.PowerShell = $PowerShell
		
			$Jobs.Add($JobObject) | Out-Null
		}# foreach ($query in $basesqlquery)

		foreach ($job in $jobs)
		{
			# Counter for the job objects
			$p++; Write-Progress -Activity "Processing Roles" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
			$queries.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
			$job.PowerShell.Dispose()
		}# foreach ($job in $jobs)
	}# if ($query -ne $null)
	else
	{
		return $false
	}

	# converting back to CloudSuiteRole because multithreaded objects return an Automation object Type
		$returned = ConvertFrom-DataToCloudSuiteRole -DataRoles $queries  
	
	#return $returned
	return $returned
}# function global:Get-CloudSuiteRole
#endregion
###########