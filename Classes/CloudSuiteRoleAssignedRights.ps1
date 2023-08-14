# class to hold Role Assigned Administrative Rights
class CloudSuiteRoleAssignedRights
{
    [System.String]$Description
    [System.String]$Path

    CloudSuiteRoleAssignedRights($assignedRights)
    {
        $this.Description = $assignedRights.Description
        $this.Path = $assignedRights.Path
    }# CloudSuiteRoleAssignedRights($assignedRights)
}# class CloudSuiteRoleAssignedRights