# class to hold Role Members
class CloudSuiteRoleMember
{
    [System.String]$Guid
    [System.String]$Name
    [System.String]$Type

    CloudSuiteRoleMember($roleMember)
    {
        $this.Guid = $roleMember.Guid
        $this.Name = $roleMember.Name
        $this.Type = $roleMember.Type
    }# CloudSuiteRoleMember($roleMember)
}# class CloudSuiteRoleMember