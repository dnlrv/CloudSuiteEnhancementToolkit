###########
#region ### global:Get-CloudSuiteSecret # Gets a CloudSuiteSecret object from the tenant
###########
function global:Get-CloudSuiteSecret
{
    <#
    .SYNOPSIS
    Gets a Secret object from the Delinea Cloud Suite.

    .DESCRIPTION
    Gets a Secret object from the Delinea Cloud Suite. This returns a CloudSuiteSecret class object containing properties about
    the Secret object, and methods to potentially retreive the Secret contents as well. By default, Get-CloudSuiteSecret without
    any parameters will get all Secret objects in the Cloud Suite. 
    
    The additional methods are the following:

    .RetrieveSecret()
      - For Text Secrets, this will retreive the contents of the Text Secret and store it in the SecretText property.
      - For File Secrets, this will prepare the File Download URL to be used with the .ExportSecret() method.

    .ExportSecret()
      - For Text Secrets, this will export the contents of the SecretText property as a text file into the ParentPath directory.
      - For File Secrets, this will download the file from the CloudSuite into the ParentPath directory.

    If the directory or file does not exist during ExportSecret(), the directory and file will be created. If the file
    already exists, then the file will be renamed and appended with a random 8 character string to avoid file name conflicts.
    
    If this function gets all Secrets from the Cloud Suite Tenant, then everything will also be saved into the global
    $CloudSuiteSecretBank variable. This makes it easier to reference these objects without having to make additional 
    API calls.

    .PARAMETER Name
    Get a Cloud Suite Secret by it's Secret Name.

    .PARAMETER Uuid
    Get a Cloud Suite Secret by it's UUID.

    .PARAMETER Type
    Get a Cloud Suite Secret by it's Type, either File or Text.

    .PARAMETER Limit
    Limits the number of potential Secret objects returned.

	.PARAMETER Skip
    Used with the -Limit parameter, skips the number of records before returning results.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteSecret class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSecret
    Gets all Secret objects from the Delinea Cloud Suite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSecret -Limit 10
    Gets 10 Secret objects from the Delinea Cloud Suite.

	.EXAMPLE
    C:\PS> Get-CloudSuiteSecret -Limit 10 -Skip 10
    Get the next 10 Secret objects in the tenant, skipping the first 10.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSecret -Name "License Keys"
    Gets all Secret objects with the Secret Name "License Keys".

    .EXAMPLE
    C:\PS> Get-CloudSuiteSecret -Type File
    Gets all File Secret objects.

    .EXAMPLE
    C:\PS> Get-CloudSuiteSecret -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Get a Secret object with the specified UUID.

    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the secret to search.",ParameterSetName = "Name")]
        [System.String]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the secret to search.",ParameterSetName = "Uuid")]
        [System.String]$Uuid,

        [Parameter(Mandatory = $true, HelpMessage = "The type of the secret to search.",ParameterSetName = "Type")]
        [ValidateSet("Text","File")]
        [System.String]$Type,

        [Parameter(Mandatory = $false, HelpMessage = "Limits the number of results.")]
        [System.Int32]$Limit,

		[Parameter(Mandatory = $false, HelpMessage = "Skip these number of records first, used with Limit.")]
        [System.Int32]$Skip
    )

    # verifying an active Cloud Suite connection
    Verify-CloudSuiteConnection

    # base query
    $query = "SELECT * FROM DataVault"

    # if the All set was not used
    if ($PSCmdlet.ParameterSetName -ne "All")
    {
        # arraylist for extra options
        $extras = New-Object System.Collections.ArrayList

        # appending the WHERE 
        $query += " WHERE "

        # setting up the extra conditionals
        if ($PSBoundParameters.ContainsKey("Name")) { $extras.Add(("SecretName = '{0}'" -f $Name)) | Out-Null }
        if ($PSBoundParameters.ContainsKey("Uuid")) { $extras.Add(("ID = '{0}'"         -f $Uuid)) | Out-Null }
        if ($PSBoundParameters.ContainsKey("Type")) { $extras.ADD(("Type = '{0}'"       -f $Type)) | Out-Null }

        # join them together with " AND " and append it to the query
        $query += ($extras -join " AND ")
    }# if ($PSCmdlet.ParameterSetName -ne "All")

	# if Limit was used, append it to the query
	if ($PSBoundParameters.ContainsKey("Limit")) 
	{ 
		$query += (" LIMIT {0}" -f $Limit) 

		# if Offset was used, append it to the query
		if ($PSBoundParameters.ContainsKey("Skip"))
		{
			$query += (" OFFSET {0}" -f $Skip) 
		}
	}# if ($PSBoundParameters.ContainsKey("Limit")) 

    Write-Verbose ("SQLQuery: [{0}]" -f $query)

    # make the query
    $basesqlquery = Query-RedRock -SqlQuery $query

    # new ArrayList to hold multiple entries
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
			$g++; Write-Progress -Activity "Getting Secrets" -Status ("{0} out of {1} Complete" -f $g,$basesqlquery.Count) -PercentComplete ($g/($basesqlquery | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
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

				# create a new CloudSuiteSecret object
				$secret = New-Object CloudSuiteSecret -ArgumentList ($query)

				return $secret
		
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
			$p++; Write-Progress -Activity "Processing Secrets" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
			$queries.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
			$job.PowerShell.Dispose()
		}# foreach ($job in $jobs)
	}# if ($query -ne $null)
	else
	{
		return $false
	}

	# converting back to CloudSuiteSecret because multithreaded objects return an Automation object Type
	$returned = ConvertFrom-DataToCloudSuiteSecret -DataSecrets $queries  

    # if the All parameter set was used
    if ($PSCmdlet.ParameterSetName -eq "All")
    {
        $global:CloudSuiteSecretBank = $returned
    }
	
	return $returned
}# global:Get-CloudSuiteSecret
#endregion
###########