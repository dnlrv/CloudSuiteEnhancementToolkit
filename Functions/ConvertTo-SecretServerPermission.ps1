
###########
#region ### global:ConvertTo-SecretServerPermissions # Converts RowAce data into Secret Server equivalent
###########
function global:ConvertTo-SecretServerPermission
{
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "Type")]
        [ValidateSet("Self","Set","Folder")]
        $Type,

        [Parameter(Mandatory = $true, HelpMessage = "Name")]
        $Name,

        [Parameter(Mandatory = $true, HelpMessage = "The JSON roles to prepare.")]
        $RowAce
    )

    if ($RowAce.CloudSuitePermission.GrantString -match "(Grant|Owner)")
    {
        $perms = "Owner"
    }
    elseif ($RowAce.CloudSuitePermission.GrantString -match '(Checkout|Retrieve|Naked)')
    {
        $perms = "View"
    }
    elseif ($RowAce.CloudSuitePermission.GrantString -like "*Edit*")
    {
        $perms = "Edit"
    }
    else
    {
        $perms = "List"
    }

    $permission = New-Object MigratedPermission -ArgumentList ($Type,$Name,$RowAce.PrincipalType,$RowAce.PrincipalName,$RowAce.isInherited,$perms,$RowAce.CloudSuitePermission.GrantString)

    return $permission
}# function global:ConvertTo-SecretServerPermissions
#endregion
###########