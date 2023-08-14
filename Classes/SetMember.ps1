# class to hold SetMembers
class SetMember
{
    [System.String]$Name
    [System.String]$Type
    [System.String]$Uuid

    SetMember([System.String]$n, [System.String]$t, [System.String]$u)
    {
        $this.Name = $n
        $this.Type = $t
        $this.Uuid = $u
    }
}# class SetMember