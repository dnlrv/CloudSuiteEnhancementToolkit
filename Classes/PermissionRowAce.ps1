# class for holding RowAce information
class PermissionRowAce
{
    [System.String]$PrincipalType         # the principal type
    [System.String]$PrincipalUuid         # the uuid of the prinicpal
    [System.String]$PrincipalName         # the name of the principal
    [System.Boolean]$isInherited          # determines if this permission is inherited
	[System.String]$InheritedFrom         # if inherited, displays where this permission is inheriting from
    [PSCustomObject]$CloudSuitePermission # the CloudSuitepermission object

    PermissionRowAce([PSCustomObject]$pra)
    {
        $this.PrincipalType        = $pra.PrincipalType
        $this.PrincipalUuid        = $pra.PrincipalUuid
        $this.PrincipalName        = $pra.PrincipalName
        $this.isInherited          = $pra.isInherited
		$this.InheritedFrom        = $pra.InheritedFrom
		$this.CloudSuitePermission = New-Object CloudSuitePermission -ArgumentList $pra.CloudSuitePermission
   }# CloudSuiteRowAce([PSCustomObject]$pra)

   PermissionRowAce([System.String]$pt, [System.String]$puuid, [System.String]$pn, `
                   [System.Boolean]$ii, [System.String]$if, [PSCustomObject]$pp)
    {
        $this.PrincipalType        = $pt
        $this.PrincipalUuid        = $puuid
        $this.PrincipalName        = $pn
        $this.isInherited          = $ii
		$this.InheritedFrom        = $if
        $this.CloudSuitePermission = $pp
    }# CloudSuiteRowAce([System.String]$pt, [System.String]$puuid, [System.String]$pn, `
}# class CloudSuiteRowAce