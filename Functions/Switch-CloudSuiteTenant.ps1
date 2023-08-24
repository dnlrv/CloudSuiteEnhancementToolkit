###########
#region ### global:Switch-CloudSuiteTenant # Changes the CloudSuiteConnection information to another connected tenant.
###########
function global:Switch-CloudSuiteTenant
{
    <#
    .SYNOPSIS
    This function will change the currently connected Cloud Suite tenant to another connected Cloud Suite tenant.

    .DESCRIPTION
	This function will change the current Cloud Suite connection information to another connected Cloud Suite connection.
	This function is only needed if you are working with two or more Cloud Suite tenants. For example, if you are working on 
	mydev.my.centrify.net and also on myprod.my.centrify.net, this function can help you switch connections between the 
	two without having to reauthenticate to each one during the switch. Each connection must still initially be 
	completed once via the Connect-CloudSuiteTenant function.

    .PARAMETER Url
    Specify the tenant's URL to switch to. For example, mycompany.my.centrify.net

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This script only returns $true on a successful switch, or $false if the specified Url was not found in the list of 
	connected Cloud Suite tenants.

    .EXAMPLE
    C:\PS> Switch-CloudSuiteTenant -Url mycompany.my.centrify.net
    This will switch your existing $CloudSuiteConnection and $CloudSuiteSessionInformation variables to the specified tenant. In this
    example, the login for mycopanyprod.my.centrify.net must have already been completed via the Connect-CloudSuiteTenant cmdlet.
    #>
    param
    (
		[Parameter(Position = 0, Mandatory = $true, HelpMessage = "The Url to switch to for authentication.")]
		[System.String]$Url
    )

    # if the $CloudSuiteConnections contains the Url in it's list
    if ($thisconnection = $global:CloudSuiteConnections | Where-Object {$_.Url -eq $Url})
    {
        # change the CloudSuiteConnection and CloudSuiteSessionInformation to the requested tenant
        $global:CloudSuiteSessionInformation = $thisconnection.CloudSuiteSessionInformation
        $global:CloudSuiteConnection = $thisconnection.CloudSuiteConnection
        return $true
    }# if ($thisconnection = $global:CloudSuiteConnections | Where-Object {$_.Url -eq $Url})
    else
    {
        return $false
    }
}# function global:Switch-CloudSuiteTenant
#endregion
###########
