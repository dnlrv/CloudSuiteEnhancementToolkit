# class to hold migrated permissions
class MigratedPermission
{
    [System.String]$PermissionType
    [System.String]$PermissionName
    [System.String]$PrincipalType
    [System.String]$PrincipalName
    [System.Boolean]$isInherited
    [System.String]$Permissions
    [System.String]$OriginalPermissions

    MigratedPermission([PSCustomObject]$p)
    {
        $this.PermissionType      = $p.PermissionType
        $this.PermissionName      = $p.PermissionName
        $this.PrincipalType       = $p.PrincipalType
        $this.PrincipalName       = $p.PrincipalName
        $this.isInherited         = $p.isInherited
        $this.Permissions         = $p.Permissions
        $this.OriginalPermissions = $p.OriginalPermissions
    }# MigratedPermission([PSCustomObject]$p)

    MigratedPermission([System.String]$pt, [System.String]$pn, [System.String]$prt, [System.String]$prn, `
               [System.String]$ii, [System.String[]]$p, [System.String[]]$op)
    {
        $this.PermissionType      = $pt
        $this.PermissionName      = $pn
        $this.PrincipalType       = $prt
        $this.PrincipalName       = $prn
        $this.isInherited         = $ii
        $this.Permissions         = $p
        $this.OriginalPermissions = $op
    }# MigratedPermission([System.String]$pt, [System.String]$pn, [System.String]$prt, [System.String]$prn, `
}# class MigratedPermission