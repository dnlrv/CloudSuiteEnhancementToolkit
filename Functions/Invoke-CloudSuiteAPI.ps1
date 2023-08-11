###########
#region ### global:Invoke-CloudSuiteAPI # Invokes RestAPI using either the interactive session or the bearer token
###########
function global:Invoke-CloudSuiteAPI
{
    <#
    .SYNOPSIS
    This function will provide an easy way to interact with any RestAPI endpoint in a Cloud Suite tenant.

    .DESCRIPTION
    This function will provide an easy way to interact with any RestAPI endpoint in a Cloud Suite tenant. This function requires an existing, valid $CloudSuiteConnection
    to exist. At a minimum, the APICall parameter is required. 

    .PARAMETER APICall
    Specify the RestAPI endpoint to target. For example "Security/whoami" or "ServerManage/UpdateResource".

    .PARAMETER Body
    Specify the JSON body payload for the RestAPI endpoint.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs as PSCustomObject with the requested data if the RestAPI call was successful.

    .EXAMPLE
    C:\PS> Invoke-CloudSuiteAPI -APICall Security/whoami
    This will attempt to reach the Security/whoami RestAPI endpoint to the currently connected PAS tenant. If there is a valid connection, basic 
    information about the connected user will be returned as output.

    .EXAMPLE
    C:\PS> Invoke-CloudSuiteAPI -APICall UserMgmt/ChangeUserAttributes -Body ( @{CmaRedirectedUserUuid=$normalid;ID=$adminid} | ConvertTo-Json)
    This will attempt to set MFA redirection on a user recognized by the PAS tenant. The body in this example is a PowerShell HastTable converted into a JSON block.
    The $normalid variable contains the UUID of the user to redirect to, and the $adminid is the UUID of the user who needs the redirect.

    .EXAMPLE
    C:\US> Invoke-CloudSuiteAPI -APICall Collection/GetMembers -Body '{"ID":"aaaaaaaa-0000-0000-0000-eeeeeeeeeeee"}'
    This will attempt to get the members of a Set via that Set's UUID. In this example, the JSON Body payload is already in JSON format.
    #>
    param
    (
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Specify the API call to make.")]
        [System.String]$APICall,

        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify the JSON Body payload.")]
        [System.String]$Body
    )

    # verifying an active Cloud Suite connection
    Verify-CloudSuiteConnection

    # setting the url based on our CloudSuiteConnection information
    $uri = ("https://{0}/{1}" -f $global:CloudSuiteConnection.PodFqdn, $APICall)

    # Try
    Try
    {
        Write-Debug ("Uri=[{0}]" -f $uri)
        Write-Debug ("Body=[{0}]" -f $Body)

        # making the call using our a Splat version of our connection
        $Response = Invoke-RestMethod -Method Post -Uri $uri -Body $Body @global:CloudSuiteSessionInformation

        # if the response was successful
        if ($Response.Success)
        {
            # return the results
            return $Response.Result
        }
        else
        {
            # otherwise throw what went wrong
            Throw $Response.Message
        }
    }# Try
    Catch
    {
        $LastError = [CloudSuiteAPIException]::new("A CloudSuiteAPI error has occured. Check `$LastError for more information")
        $LastError.APICall = $APICall
        $LastError.Payload = $Body
        $LastError.Response = $Response
        $LastError.ErrorMessage = $_.Exception.Message
        $global:LastError = $LastError
        Throw $_.Exception
    }
}# function global:Invoke-CloudSuiteAPI 
#endregion
###########