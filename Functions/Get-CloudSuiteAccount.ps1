###########
#region ### global:Get-CloudSuiteAccount # Gets a CloudSuite Account object
###########
function global:Get-CloudSuiteAccount
{
    <#
    .SYNOPSIS
    Gets an Account object from a connected Cloud Suite tenant.

    .DESCRIPTION
    Gets an Account object from a connected Cloud Suite tenant. This returns a CloudSuiteAccount class object containing properties about
    the Account object. By default, Get-CloudSuiteAccount without any parameters will get all Account objects in the Cloud Suite. 
    In addition, the CloudSuiteAccount class also contains methods to help interact with that Account.

    The additional methods are the following:

    .CheckInPassword()
      - Checks in a password that has been checked out by the CheckOutPassword() method.
    
    .CheckOutPassword()
      - Checks out the password to this Account.
    
    .ManageAccount()
      - Sets this Account to be managed by the Cloud Suite.

    .UnmanageAccount()
      - Sets this Account to be un-managed by the Cloud Suite.

    .UpdatePassword([System.String]$newpassword)
      - Updates the password to this Account.
    
    .VerifyPassword()
      - Verifies if this password on this Account is correct.

    .PARAMETER Type
    Gets only Accounts of this type. Currently only "Local","Domain","Database", or "Cloud" is supported.

    .PARAMETER SourceName
    Gets only Accounts with the name of the Parent object that hosts this account. For local accounts, this would
    be the hostname of the system the account exists on. For domain accounts, this is the name of the domain.

    .PARAMETER UserName
    Gets only Accounts with this as the username.

    .PARAMETER Uuid
    Gets only Accounts with this UUID.

    .PARAMETER Limit
    Limits the number of potential Account objects returned.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteAccount class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount
    Gets all Account objects from the Delinea CloudSuite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount -Limit 10
    Gets 10 Account objects from the Delinea CloudSuite.

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount -Type Domain
    Get all domain-based Accounts.

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount -Username "root"
    Gets all Account objects with the username, "root".

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount -SourceName "LINUXSERVER01.DOMAIN.COM"
    Get all Account objects who's source (parent) object is LINUXSERVER01.DOMAIN.COM.

    .EXAMPLE
    C:\PS> Get-CloudSuiteAccount -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Get an Account object with the specified UUID.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $false, HelpMessage = "The type of Account to search.", ParameterSetName = "Type")]
        [ValidateSet("Local","Domain","Database","Cloud")]
        [System.String]$Type,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the Source of the Account to search.", ParameterSetName = "Source")]
        [System.String]$SourceName,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the Account to search.", ParameterSetName = "UserName")]
        [System.String]$UserName,

        [Parameter(Mandatory = $false, HelpMessage = "The Uuid of the Account to search.",ParameterSetName = "Uuid")]
        [System.String]$Uuid,

        [Parameter(Mandatory = $false, HelpMessage = "A limit on number of objects to query.")]
        [System.Int32]$Limit
    )

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

    # setting the base query
    $query = "Select * FROM VaultAccount"

    # arraylist for extra options
    $extras = New-Object System.Collections.ArrayList

    # if the All set was not used
    if ($PSCmdlet.ParameterSetName -ne "All")
    {
        # appending the WHERE 
        $query += " WHERE "

        # setting up the extra conditionals
        if ($PSBoundParameters.ContainsKey("Type"))
        {
            Switch ($Type)
            {
                "Cloud"    { $extras.Add("CloudProviderID IS NOT NULL") | Out-Null ; break }
                "Domain"   { $extras.Add("DomainID IS NOT NULL") | Out-Null ; break }
                "Database" { $extras.Add("DatabaseID IS NOT NULL") | Out-Null ; break }
                "Local"    { $extras.Add("Host IS NOT NULL") | Out-Null ; break }
            }
        }# if ($PSBoundParameters.ContainsKey("Type"))
        
        if ($PSBoundParameters.ContainsKey("SourceName")) { $extras.Add(("Name = '{0}'" -f $SourceName)) | Out-Null }
        if ($PSBoundParameters.ContainsKey("UserName"))   { $extras.Add(("User = '{0}'" -f $UserName))   | Out-Null }
        if ($PSBoundParameters.ContainsKey("Uuid"))       { $extras.Add(("ID = '{0}'"   -f $Uuid))       | Out-Null }

        # join them together with " AND " and append it to the query
        $query += ($extras -join " AND ")
    }# if ($PSCmdlet.ParameterSetName -ne "All")

    # if Limit was used, append it to the query
    if ($PSBoundParameters.ContainsKey("Limit")) { $query += (" LIMIT {0}" -f $Limit) }

    Write-Verbose ("SQLQuery: [{0}]" -f $query)

    # making the query for the IDs
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
			$g++; Write-Progress -Activity "Getting Accounts" -Status ("{0} out of {1} Complete" -f $g,$basesqlquery.Count) -PercentComplete ($g/($basesqlquery | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
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

			# minor placeholder to hold account type in case of all call
            [System.String]$accounttype = $null

            if ($query.CloudProviderID -ne $null) { $accounttype = "Cloud"    }
            if ($query.DomainID -ne $null)        { $accounttype = "Domain"   }
            if ($query.DatabaseID -ne $null)      { $accounttype = "Database" }
            if ($query.Host -ne $null)            { $accounttype = "Local"    }

            # create a new CloudSuite Account object
			$account = New-Object CloudSuiteAccount -ArgumentList ($query, $accounttype)

			return $account
	
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
			$p++; Write-Progress -Activity "Processing Accounts" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
			$queries.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
			$job.PowerShell.Dispose()
		}# foreach ($job in $jobs)
    }# if ($query -ne $null)
    else
    {
        return $false
    }

	# converting back to CloudSuiteAccount because multithreaded objects return an Automation object Type
  	$returned = ConvertFrom-DataToCloudSuiteAccount -DataAccounts $queries  
    
    #return $returned
    return $returned
}# function global:Get-CloudSuiteAccount
#endregion
###########