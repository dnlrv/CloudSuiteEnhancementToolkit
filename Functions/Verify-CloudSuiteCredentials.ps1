
###########
#region ### global:Verify-CloudSuiteCredentials # Verifies the password is health for the specified account
###########
function global:Verify-CloudSuiteCredentials
{
    <#
    .SYNOPSIS
    Verifies an Account object's password as known by Cloud Suite.

    .DESCRIPTION
    This function will verify if the specified account's password, as it is known by Cloud Suite is correct.
    This will cause Cloud Suite to reach out to the Account's parent object in an attempt to validate the password.
    Will return $true if it is correct, or $false if it is incorrect or cannot validate for any reason.

	This will only work for Cloud Suite Accounts, not Cloud Suite Secrets that store credential information.

    .PARAMETER Uuid
    The Uuid of the CloudSuiteAccount to validate.

    .EXAMPLE
    C:\PS> Verify-CloudSuiteCredentials -Uuid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    Verifies the password of the Cloud Suite Account with the spcified Uuid.
    #>
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the Account to check.",ParameterSetName = "Uuid")]
        [System.String]$Uuid
    )

    # verifying an active Cloud Suite connection
    Verify-CloudSuiteConnection

    $response = Invoke-CloudSuiteAPI -APICall ServerManage/CheckAccountHealth -Body (@{ ID = $Uuid } | ConvertTo-Json)

    if ($response -eq "OK")
    {
        [System.Boolean]$responseAnswer = $true
    }
    else
    {
        [System.Boolean]$responseAnswer = $false
    }
    
    return $responseAnswer
}# function global:Verify-CloudSuiteCredentials
#endregion
###########
