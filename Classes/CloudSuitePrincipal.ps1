# class to hold SearchPrincipals
class CloudSuitePrincipal
{
    [System.String]$Name
    [System.String]$ID

    CloudSuitePrincipal($n,$i)
    {
        $this.Name = $n
        $this.ID = $i
    }
}# class CloudSuitePrincipal
