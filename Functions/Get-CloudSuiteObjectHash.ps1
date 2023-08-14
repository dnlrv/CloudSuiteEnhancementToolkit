###########
#region ### global:Get-CloudSuiteObjectHash # Gets an MD5 hash on a CloudSuite object
###########
function global:Get-CloudSuiteObjectHash
{
    <#
    .SYNOPSIS
    Gets the MD5 hash of a CloudSuite object.

    .DESCRIPTION
    Gets an MD5 hash of a CloudSuite object. This function converts an object to compressed JSON format then gets
	an MD5 hash from that JSON string. This is used to check if the data within an object has changed in any way,
	since the result string will produce a different MD5 hash.

    .PARAMETER CloudSuiteObject
    The CloudSuite object to convert.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs a CloudSuiteAccount class object.

    .EXAMPLE
    C:\PS> Get-CloudSuiteObjectHash -CloudSuiteObject $mySet
    Converts and compresses the $mySet variable into a JSON string, and returns the MD5 hash of that string.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The CloudSuite Object to get the MD5 hash.")]
        [PSCustomObject]$CloudSuiteObject
    )

    # convert the platformobject to JSON string
    $JsonString = $CloudSuiteObject | ConvertTo-Json -Depth 100 -Compress

    # convert to md5 hash
    $md5  = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($JsonString)))

    # change to lowercase and remove hyphens
    $hash = $hash.ToLower() -replace '-', ''

    return $hash
}# function global:Get-CloudSuiteObjectHash
#endregion
###########