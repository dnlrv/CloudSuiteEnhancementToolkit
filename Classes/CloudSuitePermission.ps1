# class for holding Permission information including converting it to
# a human readable format
class CloudSuitePermission
{
    [System.String]$Type        # the type of permission (Secret, Account, etc.)
    [System.Int64]$GrantInt     # the Int-based number for the permission mask
    [System.String]$GrantBinary # the binary string of the the permission mask
    [System.String]$GrantString # the human readable permission mask

    CloudSuitePermission ([PSCustomObject]$pp)
    {
        $this.Type = $pp.Type
        $this.GrantInt = $pp.GrantInt
        $this.GrantBinary = $pp.GrantBinary
        $this.GrantString = Convert-PermissionToString -Type $pp.Type -PermissionInt ([System.Convert]::ToInt64($pp.GrantBinary,2))
    }# CloudSuitePermission ([PSCustomObject]$pp)

    CloudSuitePermission ([System.String]$t, [System.Int64]$gi, [System.String]$gb)
    {
        $this.Type        = $t
        $this.GrantInt    = $gi
        $this.GrantBinary = $gb
        $this.GrantString = Convert-PermissionToString -Type $t -PermissionInt ([System.Convert]::ToInt64($gb,2))
    }# CloudSuitePermission ([System.String]$t, [System.Int64]$gi, [System.String]$gb)
}# class CloudSuitePermission