# class to hold Workflow Approvers
class CloudSuiteWorkflowApprover
{
    [System.Boolean]$isBackUp
    [System.String]$NoManagerAction
    [System.String]$DisplayName
    [System.String]$ObjectType
    [System.String]$DistinguishedName
    [System.String]$DirectoryServiceUuid
    [System.String]$SystemName
    [System.String]$ServiceInstance
    [System.String]$PType
    [System.Boolean]$Locked
    [System.String]$InternalName
    [System.String]$StatusEnum
    [System.String]$ServiceInstanceLocalized
    [System.String]$ServiceType
    [System.String]$Type
    [System.String]$Name
    [System.String]$Email
    [System.String]$Status
    [System.Boolean]$Enabled
    [System.String]$Principal
    [System.String]$Guid
    [System.String]$BackupApprover
    [System.Boolean]$OptionsSelector # extra fields for default sysadmin role
    [System.String]$RoleType
    [System.String]$_ID
    [System.Boolean]$ReadOnly
    [System.String]$Description

    CloudSuiteWorkflowApprover($approver, $isBackup)
    {
        # setting if this is a backup (Requestor's Manager option)
        $this.isBackUp = $isBackup

        # adding the rest of the properties
		# we don't loop into each property automatically in case
		# the product adds new fields that we haven't accounted for
		$this.NoManagerAction          = $approver.NoManagerAction
		$this.DisplayName              = $approver.DisplayName
		$this.ObjectType               = $approver.ObjectType
		$this.DistinguishedName        = $approver.DistinguishedName
		$this.DirectoryServiceUuid     = $approver.DirectoryServiceUuid
		$this.SystemName               = $approver.SystemName
		$this.ServiceInstance          = $approver.ServiceInstance
		$this.PType                    = $approver.PType
		$this.Locked                   = $approver.Locked
		$this.InternalName             = $approver.InternalName
		$this.StatusEnum               = $approver.StatusEnum
		$this.ServiceInstanceLocalized = $approver.ServiceInstanceLocalized
		$this.ServiceType              = $approver.ServiceType
		$this.Type                     = $approver.Type
		$this.Name                     = $approver.Name
		$this.Email                    = $approver.Email
		$this.Status                   = $approver.Status
		$this.Enabled                  = $approver.Enabled
		$this.Principal                = $approver.Principal
		$this.Guid                     = $approver.Guid
		$this.BackupApprover           = $approver.BackupApprover
		$this.OptionsSelector          = $approver.OptionsSelector
		$this.RoleType                 = $approver.RoleType
		$this._ID                      = $approver._ID
		$this.ReadOnly                 = $approver.ReadOnly
		$this.Description              = $approver.Description
    }# CloudSuiteWorkflowApprover($approver, $isBackup)
}# class CloudSuiteWorkflowApprover