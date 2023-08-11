# class for configured Vaults
class CloudSuiteVault
{
    [System.String]$VaultType
    [System.String]$VaultName
    [System.String]$ID
    [System.String]$Url
    [System.String]$Username
    [System.Int32]$SyncInterval
    [System.DateTime]$LastSync

    CloudSuiteVault () {}

    CloudSuiteVault($vault)
    {
        $this.VaultType = $vault.VaultType
        $this.VaultName = $vault.VaultName
        $this.ID = $vault.ID

        if ($vault.LastSync -ne $null)
        {
            $this.LastSync = $vault.LastSync
        }

        $this.SyncInterval = $vault.SyncInterval
        $this.Username = $vault.Username
        $this.Url = $vault.Url
    }# CloudSuiteVault($vault)
}# class CloudSuiteVault
