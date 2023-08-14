###########
#region ### global:Get-CloudSuiteCollectionRowAce # Gets RowAces for the specified platform Collection object
###########
function global:Get-CloudSuiteCollectionRowAce
{
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The type of object to search.")]
        [System.String]$Type,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the object to search.", ParameterSetName = "Name")]
        [System.String]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "The Uuid of the object to search.",ParameterSetName = "Uuid")]
        [System.String]$Uuid
    )

    # if the Name parameter was used
    if ($PSBoundParameters.ContainsKey("Name"))
    {
        $collectiontype = ""
        Switch -Regex ($Type)
        {
            "Secret|DataVault" { $collectiontype = "Set"; break }
        }

        # getting the uuid of the object
        $uuid = Get-CloudSuiteObjectUuid -Type $collectiontype -Name $Name
    }

    # setting the table variable
    [System.String]$table = ""

    Switch ($Type)
    {
        "Secret"    { $table = "DataVault"   ; break }
        "Set"       { $table = "Collections" ; break }
        default     { $table = $Type         ; break }
    }

    # preparing the JSONBody
    $JSONBody = @{ RowKey = $uuid ; Table = $table } | ConvertTo-Json

    # getting the RowAce information
    $CollectionAces = Invoke-CloudSuiteAPI -APICall "Acl/GetCollectionAces" -Body $JSONBody

    # setting a new ArrayList for the return
    $CollectionAceObjects = New-Object System.Collections.ArrayList

    # for each rowace retrieved
    foreach ($collectionace in $CollectionAces)
    {
        # ignore any global root entries
        if ($collectionace.Type -eq "GlobalRoot" -or $rowace.PrincipalName -eq "Technical Support Access")
        {
            continue
        }

        Try
        {
            # creating the cloudsuitepermission object
            $cloudsuitepermission = [CloudSuitePermission]::new($Type, $collectionace.Grant, $collectionace.GrantStr)

            # creating the PlatformRowAce object
            $obj = [PermissionRowAce]::new($collectionace.PrincipalType, $collectionace.Principal, `
            $collectionace.PrincipalName, $collectionace.Inherited, $cloudsuitepermission)
        }# Try
        Catch
        {
            # setting our custom Exception object and stuff for further review
            $LastRowAceError = [CloudSuiteRowAceException]::new("A CloudSuiteRowAce error has occured. Check `$LastRowAceError for more information")
            $LastRowAceError.RowAce = $collectionace
            $LastRowAceError.CloudSuitePermission = $cloudsuitepermission
            $LastRowAceError.ErrorMessage = $_.Exception.Message
            $global:LastRowAceError = $LastRowAceError
            Throw $_.Exception
        }# Catch

        $CollectionAceObjects.Add($obj) | Out-Null
    }# foreach ($collectionace in $CollectionAces)

    # returning the RowAceObjects
    return $CollectionAceObjects
}# function global:Get-CloudSuiteCollectionRowAce
#endregion
###########