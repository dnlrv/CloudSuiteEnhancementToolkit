# class for holding Secret information
class CloudSuiteSecret
{
    [System.String]$Name                 # the name of the Secret
    [System.String]$Type                 # the type of Secret
    [System.String]$ParentPath           # the Path of the Secret
    [System.String]$Description          # the description 
    [System.String]$ID                   # the ID of the Secret
    [System.String]$FolderId             # the FolderID of the Secret
    [System.DateTime]$whenCreated        # when the Secret was created
    [System.DateTime]$whenModified       # when the Secret was last modified
    [System.DateTime]$lastRetrieved      # when the Secret was last retrieved
    [System.String]$SecretText           # (Text Secrets) The contents of the Text Secret
    [System.String]$SecretFileName       # (File Secrets) The file name of the Secret
    [System.String]$SecretFileSize       # (File Secrets) The file size of the Secret
    [System.String]$SecretFilePath       # (File Secrets) The download FilePath for this Secret
    [PSCustomObject[]]$RowAces           # The RowAces (Permissions) of this Secret
    [System.Boolean]$WorkflowEnabled     # is Workflow enabled
    [PSCustomObject[]]$WorkflowApprovers # the Workflow Approvers for this Secret
	[System.Collections.ArrayList]$SecretEvents = @{} 

    CloudSuiteSecret () {}

    CloudSuiteSecret ($secretinfo)
    {
        $this.Name            = $secretinfo.SecretName
        $this.Type            = $secretinfo.Type
        $this.ParentPath      = $secretinfo.ParentPath
        $this.Description     = $secretinfo.Description
        $this.ID              = $secretinfo.ID
        $this.FolderId        = $secretinfo.FolderId
        $this.WorkflowEnabled = $secretinfo.WorkflowEnabled

        if ($secretinfo.whenCreated -ne $null)
        {
            $this.whenCreated = $secretinfo.whenCreated
        }
        
        # if the secret has been updated
        if ($secretinfo.WhenContentsReplaced -ne $null)
        {
            # also update the whenModified property
            $this.whenModified = $secretinfo.WhenContentsReplaced
        }

        # getting when the secret was last accessed
        $lastquery = Query-RedRock -SQLQuery ('SELECT DataVault.ID, DataVault.SecretName, Event.WhenOccurred FROM DataVault JOIN Event ON DataVault.ID = Event.DataVaultItemID WHERE (Event.EventType IN ("Cloud.Server.DataVault.DataVaultDownload") OR Event.EventType IN ("Cloud.Server.DataVault.DataVaultViewSecret"))  AND Event.WhenOccurred < Datefunc("now") AND DataVault.ID = "{0}" ORDER BY WhenOccurred DESC LIMIT 1'	-f $this.ID)

        if ($lastquery -ne $null)
        {
            $this.lastRetrieved = $lastquery.whenOccurred
        }

        # if the ParentPath is blank (root folder)
        if ([System.String]::IsNullOrEmpty($this.ParentPath))
        {
            $this.ParentPath = "."
        }

        # if this is a File secret, fill in the relevant file parts
        if ($this.Type -eq "File")
        {
            $this.SecretFileName = $secretinfo.SecretFileName
            $this.SecretFileSize = $secretinfo.SecretFileSize
        }

        # getting the RowAces for this secret
        $this.RowAces = Get-CloudSuiteRowAce -Type Secret -Uuid $this.ID

        # if Workflow is enabled
        if ($this.WorkflowEnabled)
        {
            # get the WorkflowApprovers for this secret
            $this.WorkflowApprovers = Get-CloudSuiteSecretWorkflowApprovers -Uuid $this.ID
        }
    }# CloudSuiteSecret ($secretinfo)

    # method to retrieve secret content
    RetrieveSecret()
    {
        Switch ($this.Type)
        {
            "Text" # Text secrets will add the Secret Contets to the SecretText property
            {
                $this.SecretText = Invoke-CloudSuiteAPI -APICall ServerManage/RetrieveSecretContents -Body (@{ ID = $this.ID } | ConvertTo-Json) `
                    | Select-Object -ExpandProperty SecretText
                break
            }
            "File" # File secrets will prepare the FileDownloadUrl for the Export
            {
                $this.SecretFilePath = Invoke-CloudSuiteAPI -APICall ServerManage/RequestSecretDownloadUrl -Body (@{ secretID = $this.ID } | ConvertTo-Json) `
                    | Select-Object -ExpandProperty Location
                break
            }
        }# Switch ($this.Type)
    }# RetrieveSecret()

    # method to export secret content to files
    ExportSecret()
    {
        # if the directory doesn't exist and it is not the Root PAS directory
        if ((-Not (Test-Path -Path $this.ParentPath)) -and $this.ParentPath -ne ".")
        {
            # create directory
            New-Item -Path $this.ParentPath -ItemType Directory | Out-Null
        }

        Switch ($this.Type)
        {
            "Text" # Text secrets will be created as a .txt file
            {
                # if the File does not already exists
                if (-Not (Test-Path -Path ("{0}\{1}" -f $this.ParentPath, $this.Name)))
                {
                    # create it
                    $this.SecretText | Out-File -FilePath ("{0}\{1}.txt" -f $this.ParentPath, $this.Name)
                }
                
                break
            }# "Text" # Text secrets will be created as a .txt file
            "File" # File secrets will be created as their current file name
            {
                $filename      = $this.SecretFileName.Split(".")[0]
                $fileextension = $this.SecretFileName.Split(".")[1]

                # if the file already exists
                if ((Test-Path -Path ("{0}\{1}" -f $this.ParentPath, $this.SecretFileName)))
                {
                    # append the filename 
                    $fullfilename = ("{0}_{1}.{2}" -f $filename, (-join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object{[char]$_})).ToUpper(), $fileextension)
                }
                else
                {
                    $fullfilename = $this.SecretFileName
                }

                # create the file
                Invoke-RestMethod -Method Get -Uri $this.SecretFilePath -OutFile ("{0}\{1}" -f $this.ParentPath, $fullfilename) @global:SessionInformation
                break
            }# "File" # File secrets will be created as their current file name
        }# Switch ($this.Type)
    }# ExportSecret()

	getSecretEvents()
	{
		$this.SecretEvents.Clear()

		$events = Query-RedRock -SQLQuery ("SELECT EventType,EventMessage AS Message,NormalizedUser AS User,whenOccurred FROM Event Where EventType LIKE 'Cloud.Server.DataVault%' AND DataVaultItemID = '{0}' AND whenOccurred > Datefunc('now',-365)" -f $this.ID)

		if ($events.Count -gt 0)
		{
			foreach ($event in $events)
			{
				$obj = New-Object CloudSuiteSecretEvent

				$obj.EventType    = $event.EventType
				$obj.Message      = $event.Message
				$obj.User         = $event.user
				$obj.whenOccurred = $event.whenOccurred
				
				$this.SecretEvents.Add($obj) | Out-Null
			}# foreach ($event in $events)
		}# if ($events.Count -gt 0)
	}# getSecretEvents()
}# class CloudSuiteSecret