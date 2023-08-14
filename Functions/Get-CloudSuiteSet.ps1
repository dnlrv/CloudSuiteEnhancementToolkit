###########
#region ### global:Get-CloudSuiteSet # Gets a CloudSuite Set object
###########
function global:Get-CloudSuiteSet
{
    <#
    .SYNOPSIS
    Gets a Set object from a connected Cloud Suite tenant.

    .DESCRIPTION
    Gets an Set object from a connected Cloud Suite tenant. This returns a CloudSuiteSet class object containing properties about
    the Set object. By default, Get-CloudSuiteSet without any parameters will get all Set objects in the Cloud Suite. 
    In addition, the CloudSuiteSet class also contains methods to help interact with that Set.

    The additional methods are the following:

    .getCloudSuiteObjects()
	Returns the members of this Set as the relevant CloudSuiteObjects. For example, CloudSuiteAccount objects
	for an Account Set.

    .PARAMETER Type
    Gets only Sets of this type. Currently only "System","Database","Account", or "Secret" is supported.

    .PARAMETER Name
    Gets only Sets with this name.

    .PARAMETER Uuid
    Gets only Sets with this UUID.

    .PARAMETER Limit
    Limits the number of potential Set objects returned.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteSet class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSet
    Gets all Set objects from the Delinea Cloud Suite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSet -Limit 10
    Gets 10 Set objects from the Delinea Cloud Suite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSet -Type Account
    Get all Account Sets.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSet -Name "Security Team Accounts"
    Gets the Set with the name "Security Team Accounts".

    .EXAMPLE
    C:\PS> Get-CloudSuiteSet -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Get an Set object with the specified UUID.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The type of Set to search.", ParameterSetName = "Type")]
        [ValidateSet("System","Database","Account","Secret")]
        [System.String]$Type,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Set to search.", ParameterSetName = "Name")]
        [Parameter(Mandatory = $false, HelpMessage = "The name of the Set to search.", ParameterSetName = "Type")]
        [System.String]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the Set to search.",ParameterSetName = "Uuid")]
        [Parameter(Mandatory = $false, HelpMessage = "The name of the Set to search.", ParameterSetName = "Type")]
        [System.String]$Uuid,

        [Parameter(Mandatory = $false, HelpMessage = "Limits the number of results.")]
        [System.Int32]$Limit
    )

	# verifying an active Cloud Suite connection
    Verify-CloudSuiteConnection

    # setting the base query
    $query = "Select * FROM Sets"

    # arraylist for extra options
    $extras = New-Object System.Collections.ArrayList

    # if the All set was not used
    if ($PSCmdlet.ParameterSetName -ne "All")
    {
        # placeholder to translate type names
        [System.String] $newtype = $null

        # switch to translate backend naming convention
        Switch ($Type)
        {
            "System"   { $newtype = "Server" ; break }
            "Database" { $newtype = "VaultDatabase" ; break }
            "Account"  { $newtype = "VaultAccount" ; break }
            "Secret"   { $newtype = "DataVault" ; break }
            default    { }
        }# Switch ($Type)

        # appending the WHERE 
        $query += " WHERE "

        # setting up the extra conditionals
        if ($PSBoundParameters.ContainsKey("Type")) { $extras.Add(("ObjectType = '{0}'" -f $newtype)) | Out-Null }
        if ($PSBoundParameters.ContainsKey("Name")) { $extras.Add(("Name = '{0}'"       -f $Name))    | Out-Null }
        if ($PSBoundParameters.ContainsKey("Uuid")) { $extras.Add(("ID = '{0}'"         -f $Uuid))    | Out-Null }

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
					$query
				)
			$global:CloudSuiteConnection         = $CloudSuiteConnection
			$global:CloudSuiteSessionInformation = $CloudSuiteSessionInformation

            # create a new CloudSuite Set object
			$set = New-Object CloudSuiteSet -ArgumentList ($query)

			# if the Set is not a Dynamic Set
            if ($set.SetType -ne "SqlDynamic")
            {
                # get the members of this set
                $set.GetMembers()
            }

            # determin the potential owner of the Set
            $set.determineOwner()

			return $set
	
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
			$p++; Write-Progress -Activity "Processing Sets" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
			$queries.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
			$job.PowerShell.Dispose()
		}# foreach ($job in $jobs)
    }# if ($query -ne $null)
    else
    {
        return $false
    }

	# converting back to CloudSuiteSet because multithreaded objects return an Automation object Type
  	$returned = ConvertFrom-DataToCloudSuiteSet -DataSets $queries

    #return $returned
    return $returned
}# function global:Get-CloudSuiteSet
#endregion
###########