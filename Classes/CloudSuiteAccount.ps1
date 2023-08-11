# class to hold Accounts
class CloudSuiteAccount
{
    [System.String]$AccountType
    [System.String]$ComputerClass
    [System.String]$SourceName
    [System.String]$SourceType
    [System.String]$SourceID
    [System.String]$Username
    [System.String]$ID
    [System.Boolean]$isManaged
    [System.String]$Healthy
    [System.DateTime]$LastChange
    [System.DateTime]$LastHealthCheck
    [System.String]$Password
    [System.String]$Description
    [PSCustomObject[]]$PermissionRowAces           # The RowAces (Permissions) of this Account
    [System.Boolean]$WorkflowEnabled
    [PSCustomObject[]]$WorkflowApprovers # the workflow approvers for this Account
    [PSCustomObject]$Vault
    [System.String]$SSName
    [System.String]$CheckOutID

    CloudSuiteAccount() {}

    CloudSuiteAccount($account, [System.String]$t)
    {
       
        $this.AccountType = $t
        $this.ComputerClass = $account.ComputerClass
        $this.SourceName = $account.Name

        # the tenant holds the source object's ID in different columns
        Switch ($this.AccountType)
        {
            "Database" { $this.SourceID = $account.DatabaseID; $this.SourceType = "DatabaseId"; break }
            "Domain"   { $this.SourceID = $account.DomainID; $this.SourceType = "DomainId"; break }
            "Local"    { $this.SourceID = $account.Host; $this.SourceType = "Host"; break }
            "Cloud"    { $this.SourceID = $account.CloudProviderID; $this.SourceType = "CloudProviderId"; break }
        }

        # accounting for null
        if ($account.LastHealthCheck -ne $null)
        {
            $this.LastHealthCheck = $account.LastHealthCheck
        }

        # accounting for null
        if ($account.LastChange -ne $null)
        {
            $this.LastChange = $account.LastChange
        }

        $this.Username = $account.User
        $this.ID = $account.ID
        $this.isManaged = $account.IsManaged
        $this.Healthy = $account.Healthy
        $this.Description = $account.Description
        $this.SSName = ("{0}\{1}" -f $this.SourceName, $this.Username)

        # Populate the Vault property if Account is imported from a Vault
        if ($account.VaultId -ne $null)
        {
            $this.Vault = (Get-CloudSuiteVault -Uuid $account.VaultId)
        } # if ($null -ne $account.VaultId)
        else
        {
            $this.Vault = $null
        }
        
        # getting the RowAces for this Set
        $this.PermissionRowAces = Get-CloudSuiteRowAce -Type $this.AccountType -Uuid $this.ID

        # getting the WorkflowApprovers for this secret
        $this.WorkflowEnabled = $account.WorkflowEnabled
        
        # getting the WorkflowApprovers for this Account
        if ($this.WorkflowEnabled)
        {
            $this.WorkflowApprovers = Prepare-WorkflowApprovers -Approvers ($account.WorkflowApproversList | ConvertFrom-Json)
        }

    }# CloudSuiteAccount($account)

    [System.Boolean] CheckOutPassword()
    {
        # if checkout is successful
        if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
        {   
            # set these checkout fields
            $this.Password = $checkout.Password
            $this.CheckOutID = $checkout.COID
        }# if ($checkout = Invoke-CloudSuiteAPI -APICall ServerManage/CheckoutPassword -Body (@{ID = $this.ID} | ConvertTo-Json))
        else
        {
            return $false
        }
        return $true
    }# [System.Boolean] CheckOutPassword()

    [System.Boolean] CheckInPassword()
    {
        # if CheckOutID isn't null
        if ($this.CheckOutID -ne $null)
        {
            # if checkin is successful
            if ($checkin = Invoke-CloudSuiteAPI -APICall ServerManage/CheckinPassword -Body (@{ID = $this.CheckOutID} | ConvertTo-Json))
            {
                $this.Password   = $null
                $this.CheckOutID = $null
            }
            else
            {
                return $false
            }
        }# if ($this.CheckOutID -ne $null)
        else
        {
            return $false
        }
        return $true 
    }# [System.Boolean] CheckInPassword()

    [System.Boolean] UnmanageAccount()
    {
        # if the account was successfully unmanaged
        if ($manageaccount = Invoke-CloudSuiteAPI ServerManage/UpdateAccount -Body (@{ID=$this.ID;User=$this.Username;$this.SourceType=$this.SourceID;IsManaged=$false}|ConvertTo-Json))
        {
            $this.isManaged = $false
            return $true
        }
        return $false
    }# [System.Boolean] UnmanageAccount()

    [System.Boolean] ManageAccount()
    {
        # if the account was successfully managed
        if ($manageaccount = Invoke-CloudSuiteAPI ServerManage/UpdateAccount -Body (@{ID=$this.ID;User=$this.Username;$this.SourceType=$this.SourceID;IsManaged=$true}|ConvertTo-Json))
        {
            $this.isManaged = $true
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()

    [System.Boolean] VerifyPassword()
    {
        Write-Debug ("Starting Password Health Check for {0}" -f $this.Username)
        $result = Invoke-CloudSuiteAPI -APICall ServerManage/CheckAccountHealth -Body (@{"ID"=$this.ID} | ConvertTo-Json)
        $this.Healthy = $result
        Write-Debug ("Password Health: {0}" -f $result)

        # if the VerifyCredentials comes back okay, return true
        if ($result -eq "OK")
        {
            return $true
        }
        else
        {
            return $false
        }
    }# VerifyPassword()

    [System.Boolean] UpdatePassword()
    {
        # if the account was successfully managed
        if ($updatepassword = Invoke-CloudSuiteAPI ServerManage/UpdatePassword -Body (@{ID=$this.ID;Password=$this.Password}|ConvertTo-Json))
        {
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()

    [System.Boolean] UpdatePassword($password)
    {
        # if the account was successfully managed
        if ($updatepassword = Invoke-CloudSuiteAPI ServerManage/UpdatePassword -Body (@{ID=$this.ID;Password=$password}|ConvertTo-Json))
        {
            return $true
        }
        return $false
    }# [System.Boolean] ManageAccount()
}# class