###########
#region ### global:Get-CloudSuiteVault # Gets a CloudSuite Vault object
###########
function global:Get-CloudSuiteVault
{
    <#
    .SYNOPSIS
    Gets a Vault object from a connected Cloud Suite tenant.

    .DESCRIPTION
    Gets a Vault object from a connected Cloud Suite tenant. This returns a CloudSuiteVault class object containing properties about
    the Vault object. By default, Get-CloudSuiteVault without any parameters will get all Vault objects in the Cloud Suite. 

    .PARAMETER Type
    Gets only Vaults of this type. Currently only "SecretServer" is supported.

    .PARAMETER VaultName
    Gets only Vaults with this name.

    .PARAMETER Uuid
    Gets only Vaults with this UUID.

    .PARAMETER Limit
    Limits the number of potential Vault objects returned.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteVault class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteVault
    Gets all Vault objects from a connected Cloud Suite tenant.

    .EXAMPLE
    C:\PS> Get-CloudSuiteVault -Limit 10
    Gets 10 Vault objects from a connected Cloud Suite tenant.

    .EXAMPLE
    C:\PS> Get-CloudSuiteVault -Name "Company SecretServer"
    Gets all Vault objects with the Name "Company SecretServer".

    .EXAMPLE
    C:\PS> Get-CloudSuiteVault -Type "SecretServer"
    Get all Secret Server Vault objects from a connected Cloud Suite tenant.

    .EXAMPLE
    C:\PS> Get-CloudSuiteVault -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Get all Vault objects with the specified UUID.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The type of Vault to search.", ParameterSetName = "Type")]
        [ValidateSet("SecretServer")]
        [System.String]$Type,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Vault to search.", ParameterSetName = "Name")]
        [Parameter(Mandatory = $false, HelpMessage = "The name of the Vault to search.", ParameterSetName = "Type")]
        [System.String]$VaultName,

        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the Vault to search.",ParameterSetName = "Uuid")]
        [Parameter(Mandatory = $false, HelpMessage = "The name of the Vault to search.", ParameterSetName = "Type")]
        [System.String]$Uuid,

        [Parameter(Mandatory = $false, HelpMessage = "A limit on number of objects to query.")]
        [System.Int32]$Limit
    )

    # verifying an active CloudSuite connection
    Verify-CloudSuiteConnection

    # setting the base query
    $query = "SELECT ID, Type as VaultType, Name as VaultName, Url, UserName, SyncInterval, LastSync FROM Vault"

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
            Switch ($Type) # Only one type for now, but more may show up in the future
            {
                "SecretServer" { $extras.Add(("Type = '{0}'" -f $Type)) | Out-Null ; break }
            }
        }# if ($PSBoundParameters.ContainsKey("Type"))
        
        if ($PSBoundParameters.ContainsKey("VaultName"))  { $extras.Add(("Name = '{0}'" -f $VaultName)) | Out-Null }
        if ($PSBoundParameters.ContainsKey("Uuid"))       { $extras.Add(("ID = '{0}'"   -f $Uuid))       | Out-Null }

        # join them together with " AND " and append it to the query
        $query += ($extras -join " AND ")
    }# if ($PSCmdlet.ParameterSetName -ne "All")

    # if Limit was used, append it to the query
    if ($PSBoundParameters.ContainsKey("Limit")) { $query += (" LIMIT {0}" -f $Limit) }

    Write-Verbose ("SQLQuery: [{0}]" -f $query)

    # making the query
    $sqlquery = Query-RedRock -SQLQuery $query

    # ArrayList to hold objects
    $queries = New-Object System.Collections.ArrayList

    # if the query isn't null
    if ($sqlquery -ne $null)
    {
        foreach ($q in $sqlquery)
        {
            Write-Verbose ("Working with Vault [{0}]" -f $q.VaultName )

            # create a new CloudSuite Vault object
            $vault = New-Object CloudSuiteVault -ArgumentList $q

            $queries.Add($vault) | Out-Null
        }# foreach ($q in $query)
    }# if ($query -ne $null)
    else
    {
        return $false
    }
    
    #return $queries
    return $queries
}# function global:Get-CloudSuiteVault
#endregion
###########