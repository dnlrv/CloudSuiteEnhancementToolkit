# class to hold Roles
class CloudSuiteRole
{
    [System.String]$ID
    [System.String]$Name
    [System.String]$RoleType
    [System.Boolean]$ReadOnly
    [System.String]$Description
    [System.String]$DirectoryServiceUuid
    [System.Collections.ArrayList]$Members = @{} # Members of the role
    [System.Collections.ArrayList]$AssignedRights = @{} # Assigned administrative rights of the role

	CloudSuiteRole() {}

    CloudSuiteRole($role)
    {
        $this.ID = $role.ID
        $this.Name = $role.Name
        $this.RoleType = $role.RoleType
        $this.ReadOnly = $role.ReadOnly
        $this.Description = $role.Description
        $this.DirectoryServiceUuid = $role.DirectoryServiceUuid
        $this.getRoleMembers()
        $this.getRoleAssignedRights()
    }# CloudSuiteRole($role)

    getRoleMembers()
    {
        # get the Role Members
        $rm = ((Invoke-CloudSuiteAPI -APICall ("SaasManage/GetRoleMembers?name={0}" -f $this.ID)).Results.Row)
        
        # if there are more than 0 members
        if ($rm.Count -gt 0)
        {
            foreach ($r in $rm)
            {
				$this.Members.Add(((New-Object CloudSuiteRoleMember -ArgumentList ($r)))) | Out-Null
            }
        }
    }# getRoleMembers()

    getRoleAssignedRights()
    {
        # get the role's assigned administrative rights
        $ar = ((Invoke-CloudSuiteAPI -APICall ("core/GetAssignedAdministrativeRights?role={0}" -f $this.ID)).Results.Row)
        
        # if there are more than 0 assigned rights
        if ($ar.Count -gt 0)
        {
            foreach ($a in $ar)
            {
				$this.AssignedRights.Add(((New-Object CloudSuiteRoleAssignedRights -ArgumentList ($a)))) | Out-Null
            }
        }
    }# getRoleAssignedRights()
}# class CloudSuiteRole