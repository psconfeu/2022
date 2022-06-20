break

#region Prerequisites

<#

      PowerShell modules

    - Az.PolicyInsights: Assigning policies and remediation tasks
    - Az.Resources: Assign permissions for managed identities
    - Az.Storage - Upload artifacts (configuration zip-files) to blob storage
    - GuestConfiguration: Authoring and publishing custom guest configurations
    - PSDesiredStateConfiguration: DSC v2/v3
    - PSDscResources: For this demo - MsiPackage resource to install applications on Windows, Service resource to manage services on Windows

#>

# Starting with PowerShell 7.2 Preview 6, DSC is released independently from PowerShell as a module in the PowerShell Gallery. To install DSC version 3 in your PowerShell environment, run the command below.
Install-Module PSDesiredStateConfiguration

#DSC v3 is removing the dependency on MOF: Initially, only support DSC Resources written as PowerShell classes. Due to using MOF-based resources for demos, we are using version 2.0.5 in this session.
Install-Module PSDesiredStateConfiguration -AllowPreRelease -Force

Get-Command -Module PSDesiredStateConfiguration

# Install the guest configuration DSC resource module from PowerShell Gallery
Install-Module -Name GuestConfiguration

<#

The PowerShell module GuestConfiguration automates the process of creating custom content including:

  - Creating a guest configuration content artifact (.zip)
  - Validating the package meets requirements
  - Installing the guest configuration agent locally for testing
  - Validating the package can be used to audit settings in a machine
  - Validating the package can be used to configure settings in a machine
  - Publishing the package to Azure storage
  - Creating a policy definition
  - Publishing the policy

#>

# Version 4.0 Generally Available 2022-06-13: https://twitter.com/jodi_boone_/status/1536489330596016128
Update-Module -Name GuestConfiguration

<#

From 3.5.4 preview to 4.0 Generally Available
Minimum version of the PowerShell engine changed from 6.2 to 5.1

Publish-GuestConfigurationPolicy replaced by New-AzPolicyDefinition (in the Az.Resources module)

Linux: Embedded PowerShell 7.2.0-preview.6 replaced by PowerShell 7.2.4
Windows: Embedded PowerShell 7.1.2 replaced by PowerShell 7.1.3?

ReleaseNotes:
New-GuestConfigurationPackage will no longer create the unzipped package folder under your provided Path or working
directory. The package will instead be created under the module's temporary directory and only the .zip file will
be generated at the provided destination Path or working directory. This fixes the issue that the the source .mof file
was getting deleted when it was under a subpath that needs to be removed to create the package.

From: https://github.com/PowerShell/GuestConfiguration
To: https://github.com/Azure/GuestConfiguration

Details:
https://github.com/MicrosoftDocs/azure-docs/commit/801b0a9cff345ef02bfc7a7432e62aba6af88edf

#>


# Get a list of commands for the imported GuestConfiguration module
Get-Command -Module GuestConfiguration

# Authenticate to Azure
Connect-AzAccount -UseDeviceAuthentication
Set-AzContext democrayon

# Create storage account for storing DSC artifacts
New-AzStorageAccount -ResourceGroupName compute-rg -Name janegilringguestconfig -SkuName 'Standard_LRS' -Location norwayeast | New-AzStorageContainer -Name guestconfiguration -Permission Blob

# Hard-coded username and password for the ArcBox nested VMs
$nestedWindowsUsername = "Administrator"
$nestedWindowsPassword = "ArcDemo123!!"
$nestedLinuxUsername = "arcdemo"
$nestedLinuxPassword = "ArcDemo123!!"

# Create Windows credential object
$secWindowsPassword = ConvertTo-SecureString $nestedWindowsPassword -AsPlainText -Force
$winCreds = New-Object System.Management.Automation.PSCredential ($nestedWindowsUsername, $secWindowsPassword)

# Create Linux credential object
$secLinuxPassword = ConvertTo-SecureString $nestedLinuxPassword -AsPlainText -Force
$linCreds = New-Object System.Management.Automation.PSCredential ($nestedLinuxUsername, $secLinuxPassword)

#endregion

#region Building our first configuration

Configuration PrintSpooler
{
    Import-DscResource -ModuleName PSDscResources

    Service 'EnsurePrintSpoolerRunning'
    {
        Name = 'spooler'
        Ensure = 'Present'
        State = 'Running'
    }
}

PrintSpooler -OutputPath "c:\demo\Guest Configuration\PrintSpooler"

cd C:\demo

# Create a package that will only audit compliance
New-GuestConfigurationPackage `
  -Name 'AuditPrintSpooler' `
  -Configuration ".\Guest Configuration\PrintSpooler\localhost.mof" `
  -Type Audit `
  -Force

# Create a package that will audit and apply the configuration (Set)
New-GuestConfigurationPackage `
-Name 'AuditAndSetPrintSpooler' `
-Configuration ".\Guest Configuration\PrintSpooler\localhost.mof" `
  -Type AuditAndSet `
  -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path 'C:\demo\AuditAndSetPrintSpooler.zip'

$Parameter = @(
  @{
      ResourceType = 'Service'
      ResourceId = 'EnsurePrintSpoolerRunning'
      ResourcePropertyName = 'Name'
      ResourcePropertyValue = 'spooler' # Override with other values as needed: AppReadiness
  }
)

Get-GuestConfigurationPackageComplianceStatus `
            -Path 'C:\demo\AuditAndSetPrintSpooler.zip' `
            -Parameter $Parameter

Stop-Service -Name spooler

$ComplianceStatus = Get-GuestConfigurationPackageComplianceStatus `
            -Path 'C:\demo\AuditAndSetPrintSpooler.zip' `
            -Parameter $Parameter

$ComplianceStatus
$ComplianceStatus.resources.Reasons
$ComplianceStatus.resources.Reasons.phrase

Open-EditorFile -Path C:\Users\arcdemo\Documents\PowerShell\Modules\cFeatureSet\cFeatureSet.psm1

<#
Implementing the "Reasons" property provides a better experience when viewing the results of a configuration assignment from the Azure Portal. If the Get method in a module doesn't include "Reasons",
 generic output is returned with details from the properties returned by the Get method.

Portal-example: StoppedAndDisabledService_FromTag

#>

# Removed after GuestConfiguration 4.x
#$ContentUri = Publish-GuestConfigurationPackage -Path 'C:\demo\AuditAndSetPrintSpooler.zip' -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

# Leveraging native commands in Az.Storage instead
$StorageAccountKey = Get-AzStorageAccountKey -Name arcboxalfm7s4r4fza2 -ResourceGroupName azure-jumpstart-arcbox-rg
$Context = New-AzStorageContext -StorageAccountName arcboxalfm7s4r4fza2 -StorageAccountKey $StorageAccountKey[0].Value

Set-AzStorageBlobContent -Container "guestconfiguration" -File 'C:\demo\AuditAndSetPrintSpooler.zip' -Blob "AuditAndSetPrintSpooler.zip" -Context $Context -Force

$contenturi = New-AzStorageBlobSASToken -Context $Context -FullUri -Container guestconfiguration -Blob "AuditAndSetPrintSpooler.zip" -Permission rwd

$PolicyId = (New-Guid).Guid

# Changed from -Policy in preview to -PolicyVersion in GA
New-GuestConfigurationPolicy `
  -PolicyId $PolicyId `
  -ContentUri $ContentUri `
  -DisplayName 'Ensure Print Spooler is running' `
  -Description 'Verifies that the Print Spooler service on Windows is running.' `
  -Path 'C:\demo\AuditAndSetPrintSpooler\Policy' `
  -Platform 'Windows' `
  -PolicyVersion 1.1.0 `
  -Mode ApplyAndAutoCorrect `
  -Verbose -OutVariable policy

Open-EditorFile -Path $Policy.Path

# Removed after GuestConfiguration 4.x
#Publish-GuestConfigurationPolicy -Path 'C:\demo\AuditAndSetPrintSpooler\Policy'

# Replaced by Az.Resources module command
New-AzPolicyDefinition -Name 'Ensure Print Spooler is running' -Policy $Policy.Path

# Do manual assignment and compliance check in the portal to understand what we are doing visually - in the next demo
# we will do this with PowerShell
Start-Process "https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyMenuBlade/~/Overview"

<#
  Validation frequency
  The guest configuration agent checks for new or changed guest assignments every 5 minutes. Once a guest assignment is received, the settings for that configuration are rechecked on a 15-minute interval. If multiple configurations are assigned, each is evaluated sequentially. Long-running configurations impact the interval for all configurations, because the next will not run until the prior configuration has finished.

  Results are sent to the guest configuration service when the audit completes. When a policy evaluation trigger occurs, the state of the machine is written to the guest configuration resource provider. This update causes Azure Policy to evaluate the Azure Resource Manager properties. An on-demand Azure Policy evaluation retrieves the latest value from the guest configuration resource provider. However, it doesn't trigger a new activity within the machine. The status is then written to Azure Resource Graph.
#>

# Guest Assignments (the relationship between a machine and an Azure Policy) can be accessed via the portal
Start-Process "https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Compute%2FvirtualMachines%2Fproviders%2FguestConfigurationAssignments"

# And Azure CLI
az guestconfig guest-configuration-hcrp-assignment list --machine-name "ArcBox-Win2k19" --resource-group "azure-jumpstart-arcbox-rg" | ConvertFrom-Json | ft name,id,lastComplianceStatusChecked,configurationSetting

# No native PowerShell cmdlet yet, but we can query the API directly to get assignments for a specific machine for example
Invoke-AzRestMethod -Method GET -Uri 'https://management.azure.com/subscriptions/b7f543e7-29f0-4e13-8b16-e8e94170be88/resourceGroups/azure-jumpstart-arcbox-rg/providers/Microsoft.HybridCompute/machines/ArcBox-Win2k19/providers/Microsoft.GuestConfiguration/guestConfigurationAssignments?api-version=2020-06-25' | Select-Object -ExpandProperty content | ConvertFrom-Json |
Select-Object -ExpandProperty value |
Format-Table name,@{n='assignmentType';e={$PSItem.properties.guestConfiguration.assignmentType}},@{n='lastComplianceStatusChecked';e={$PSItem.properties.lastComplianceStatusChecked}}#,@{n='configurationSetting';e={$PSItem.properties.guestConfiguration.configurationSetting}}

# Ran before session:
Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock { Get-Service spooler | Stop-Service } -Credential $winCreds

Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock { Get-Service spooler } -Credential $winCreds

Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock { Get-WinEvent -LogName System -MaxEvents 500 | Where-Object Message -like "*spooler*" } -Credential $winCreds | Format-List MachineName,TimeCreated,Message

<#

Stopped spooler Tuesday, June 7, 2022 12:04:13 PM


MachineName : ArcBox-Win2K22
TimeCreated : 6/7/2022 12:35:26 PM
Message     : The Print Spooler service entered the running state.

MachineName : ArcBox-Win2K22
TimeCreated : 6/7/2022 12:04:06 PM
Message     : The Print Spooler service entered the stopped state.

TimeCreated                     Id LevelDisplayName Message
-----------                     -- ---------------- -------
07.06.2022 19.16.46           7036 Information      The Print Spooler service entered the running state.
07.06.2022 18.56.59           7036 Information      The Print Spooler service entered the stopped state.
07.06.2022 17.28.35           7036 Information      The Print Spooler service entered the running state.
07.06.2022 16.53.02           7036 Information      The Print Spooler service entered the stopped state.
07.06.2022 16.01.47           7036 Information      The Print Spooler service entered the running state.
07.06.2022 14.57.26           7036 Information      The Print Spooler service entered the stopped state.

#>

#endregion

#region Client log files

<#

The guest configuration extension writes log files to the following locations:

Windows

Azure VM: C:\ProgramData\GuestConfig\gc_agent_logs\gc_agent.log
Arc-enabled server: C:\ProgramData\GuestConfig\arc_policy_logs\gc_agent.log

Linux

Azure VM: /var/lib/GuestConfig/gc_agent_logs/gc_agent.log
Arc-enabled server: /var/lib/GuestConfig/arc_policy_logs/gc_agent.log
#>

 Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
  $linesToIncludeBeforeMatch = 0
  $linesToIncludeAfterMatch = 10
  $logPath = 'C:\ProgramData\GuestConfig\arc_policy_logs\gc_worker.log'
  Select-String -Path $logPath -pattern 'DSCEngine','DSCManagedEngine' -CaseSensitive -Context $linesToIncludeBeforeMatch,$linesToIncludeAfterMatch | Select-Object -Last 80
 } -Credential $winCreds

 Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
  Get-ChildItem 'C:\ProgramData\GuestConfig\Configuration' | Format-Table fullname
 } -Credential $winCreds

 Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
  Get-ChildItem 'C:\ProgramData\GuestConfig\Configuration' -Recurse | ft fullname
 } -Credential $winCreds

#endregion

#region Install 7-Zip on Windows

Configuration Install7ZipOnWindows
{
    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        MsiPackage 7zip
        {
            ProductId = '{23170F69-40C1-2702-2107-000001000000}'
            Path = 'https://www.7-zip.org/a/7z2107-x64.msi'
            Ensure = 'Present'
        }
    }
}


Install7ZipOnWindows -OutputPath "c:\demo\Guest Configuration\Install7ZipOnWindows"

cd C:\demo

New-GuestConfigurationPackage `
 -Name 'Install7ZipOnWindows' `
 -Configuration ".\Guest Configuration\Install7ZipOnWindows\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path 'C:\demo\Install7ZipOnWindows\Install7ZipOnWindows.zip'

$ContentUri = Publish-GuestConfigurationPackage -Path 'C:\demo\Install7ZipOnWindows\Install7ZipOnWindows.zip' -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

$ContentUri

$PolicyId = (New-Guid).Guid

New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Windows]Ensure 7-Zip is installed' `
 -Description 'Installs 7-Zip if not present.' `
 -Path 'C:\demo\Install7ZipOnWindows\Policy' `
 -Platform 'Windows' `
 -Version 1.0.0 `
 -Mode ApplyAndAutoCorrect `
 -Verbose

 $Policy = Publish-GuestConfigurationPolicy -Path 'C:\demo\Install7ZipOnWindows\Policy'

  # Assign policy to resource group containing Azure Arc lab servers
 $ResourceGroup = Get-AzResourceGroup -Name 'azure-jumpstart-arcbox-rg'
 $Policy = Get-AzPolicyDefinition | Where-Object {$PSItem.Properties.DisplayName -eq '[Windows]Ensure 7-Zip is installed'}
 $PolicyParameterObject = @{'IncludeArcMachines'='True'} # <- IncludeArcMachines is important - given you want to target Arc as well as Azure VMs

 New-AzPolicyAssignment -Name '[Windows]Ensure 7-Zip is installed' -PolicyDefinition $Policy -Scope $ResourceGroup.ResourceId -PolicyParameterObject $PolicyParameterObject -IdentityType SystemAssigned -Location westeurope -DisplayName '[Windows]Ensure7-Zip is installed'

 <#

 - Grant a managed identity defined roles with PowerShell
 - Create a remediation task through Azure PowerShell

 https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources

 #>

 $assignment = Get-AzPolicyAssignment -PolicyDefinitionId $Policy.PolicyDefinitionId | Where-Object Name -eq "[Windows]Ensure 7-Zip is installed"

 $PolicyDefinition = Get-AzPolicyDefinition -Name fd41ee42-a0f8-4d22-ad49-2990084ea791
 $roleDefinitionIds =  $PolicyDefinition.Properties.policyRule.then.details.roleDefinitionIds

 if ($roleDefinitionIds.Count -gt 0)
 {
     $roleDefinitionIds | ForEach-Object {
         $roleDefId = $_.Split("/") | Select-Object -Last 1
         New-AzRoleAssignment -Scope $resourceGroup.ResourceId -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId
     }
 }


 $job = Start-AzPolicyRemediation -AsJob -Name ($assignment.PolicyAssignmentId -split '/')[-1] -PolicyAssignmentId $assignment.PolicyAssignmentId -ResourceGroupName $ResourceGroup.ResourceGroupName
 $job | Wait-Job | Receive-Job

 # Tip: Start a remediation that will discover non-compliant resources before remediating by adding:
 # -ResourceDiscoveryMode ReEvaluateCompliance

Get-AzPolicyRemediation -ResourceGroupName 'azure-jumpstart-arcbox-rg'

# assignmentType will now change to ApplyAndAutoCorrect
az rest --method GET --uri 'https://management.azure.com/subscriptions/b7f543e7-29f0-4e13-8b16-e8e94170be88/resourceGroups/azure-jumpstart-arcbox-rg/providers/Microsoft.HybridCompute/machines/ArcBox-Win2k19/providers/Microsoft.GuestConfiguration/guestConfigurationAssignments/Install7ZipOnWindows?api-version=2020-06-25' | ConvertFrom-Json |
Format-Table name,@{n='assignmentType';e={$PSItem.properties.guestConfiguration.assignmentType}},@{n='lastComplianceStatusChecked';e={$PSItem.properties.lastComplianceStatusChecked}},@{n='configurationSetting';e={$PSItem.properties.guestConfiguration.configurationSetting}}

 Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
   Get-ChildItem 'C:\ProgramData\GuestConfig\Configuration' | ft fullname
  } -Credential $winCreds

<# The module should be downloaded within 20 minutes after assigning the policy

        FullName
        --------
        C:\ProgramData\GuestConfig\Configuration\AuditAndSetPrintSpooler
        C:\ProgramData\GuestConfig\Configuration\AuditSecureProtocol
        C:\ProgramData\GuestConfig\Configuration\AzureWindowsBaseline
        C:\ProgramData\GuestConfig\Configuration\Install7ZipOnWindows
        C:\ProgramData\GuestConfig\Configuration\InstallPowerShell7OnWindows
        C:\ProgramData\GuestConfig\Configuration\WindowsDefenderExploitGuard
        C:\ProgramData\GuestConfig\Configuration\WindowsLogAnalyticsAgentInstalled

#>

  Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
    Get-Item "C:\Program Files\7-Zip"
  } -Credential $winCreds | Format-Table fullname,lastwritetime,pscomputername

  <# The application should be installed within 20 minutes after creating the remediation task

        FullName               LastWriteTime        PSComputerName
        --------               -------------        --------------
        C:\Program Files\7-Zip 6/8/2022 12:13:29 PM ArcBox-Win2K19
        C:\Program Files\7-Zip 6/8/2022 12:28:13 PM ArcBox-Win2K22

  #>

#endregion

#region Install PowerShell 7 on Windows

 Configuration InstallPowerShell7OnWindows
 {
     Import-DscResource -ModuleName 'PSDscResources'

     Node localhost
     {
         MsiPackage PS7
         {
             ProductId = '{6C1F709B-BD77-453C-A47D-45A86833051D}'
             Path = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/PowerShell-7.2.4-win-x64.msi'
             Ensure = 'Present'
         }
     }
 }


 InstallPowerShell7OnWindows -OutputPath "c:\demo\Guest Configuration\InstallPowerShell7OnWindows"

cd C:\demo

New-GuestConfigurationPackage `
  -Name 'InstallPowerShell7OnWindows' `
  -Configuration ".\Guest Configuration\InstallPowerShell7OnWindows\localhost.mof" `
  -Type AuditAndSet `
  -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path 'C:\demo\InstallPowerShell7OnWindows\InstallPowerShell7OnWindows.zip'

$ContentUri = Publish-GuestConfigurationPackage -Path 'C:\demo\InstallPowerShell7OnWindows\InstallPowerShell7OnWindows.zip' -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

$ContentUri

$PolicyId = (New-Guid).Guid

New-GuestConfigurationPolicy `
  -PolicyId $PolicyId `
  -ContentUri $ContentUri `
  -DisplayName '[Windows]Ensure PowerShell 7 is installed' `
  -Description 'Installs PowerShell 7 if not present.' `
  -Path 'C:\demo\InstallPowerShell7OnWindows\Policy' `
  -Platform 'Windows' `
  -Version 1.0.0 `
  -Mode ApplyAndAutoCorrect `
  -Verbose

  $Policy = Publish-GuestConfigurationPolicy -Path 'C:\demo\InstallPowerShell7OnWindows\Policy'

  $ResourceGroup = Get-AzResourceGroup -Name 'azure-jumpstart-arcbox-rg'
  $Policy = Get-AzPolicyDefinition | Where-Object {$PSItem.Properties.DisplayName -eq '[Windows]Ensure PowerShell 7 is installed'}
  $PolicyParameterObject = @{'IncludeArcMachines'='True'}
  New-AzPolicyAssignment -Name '[Windows]Ensure PowerShell 7 is installed' -PolicyDefinition $Policy -Scope $ResourceGroup.ResourceId -PolicyParameterObject $PolicyParameterObject -IdentityType SystemAssigned -Location westeurope -DisplayName '[Windows]Ensure PowerShell 7 is installed'

  # C:\ProgramData\GuestConfig\Configuration\InstallPowerShell7OnWindows showed up within minutes
  Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
    Get-ChildItem 'C:\ProgramData\GuestConfig\Configuration' | ft fullname
   } -Credential $winCreds

   # pwsh.exe was installed after 20 minutes
   Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
    Get-Command pwsh
    Start-Process -FilePath pwsh.exe -ArgumentList '-Command $PSVersionTable' -NoNewWindow
   } -Credential $winCreds

#endregion

#region Embedded PowerShell versions

Configuration TestPSVersionWindows {
  [CmdletBinding()]

  Import-DscResource -ModuleName 'JanDemoDscResources'

  Node localhost
  {
      PSVersionToFile demo
      {
          Ensure = 'Present'
          Path = 'C:\Windows\Temp\PSVersion.txt'
      }
  }
}

$ConfigurationName = 'TestPSVersionWindows'

TestPSVersionWindows -OutputPath "c:\demo\$ConfigurationName"

cd C:\demo

New-GuestConfigurationPackage `
 -Name $ConfigurationName `
 -Configuration "c:\demo\$ConfigurationName\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path "C:\demo\$ConfigurationName.zip"

$ComplianceStatus = Get-GuestConfigurationPackageComplianceStatus -Path "C:\demo\$ConfigurationName.zip"
$ComplianceStatus.resources.reasons

$StorageAccountKey = Get-AzStorageAccountKey -Name arcboxalfm7s4r4fza2 -ResourceGroupName azure-jumpstart-arcbox-rg
$Context = New-AzStorageContext -StorageAccountName arcboxalfm7s4r4fza2 -StorageAccountKey $StorageAccountKey[0].Value

Set-AzStorageBlobContent -Container "guestconfiguration" -File "C:\demo\$ConfigurationName.zip" -Blob "$ConfigurationName.zip" -Context $Context -Force

$contenturi = New-AzStorageBlobSASToken -Context $Context -FullUri -Container guestconfiguration -Blob "$ConfigurationName.zip" -Permission rwd

$PolicyId = (New-Guid).Guid

New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Windows]Get PowerShell version' `
 -Description 'Returns PowerShell version used by Guest Configuration' `
 -Path "C:\demo\$ConfigurationName\Policy" `
 -Platform 'Windows' `
 -PolicyVersion 1.1.0 `
 -Mode ApplyAndAutoCorrect `
 -Verbose -OutVariable Policy

 New-AzPolicyDefinition -Name 'Ensure Print Spooler is running' -Policy $Policy.Path -OutVariable PolicyDefinition

  # Assign policy to resource group containing Azure Arc lab servers
 $ResourceGroup = Get-AzResourceGroup -Name 'azure-jumpstart-arcbox-rg'
 $PolicyParameterObject = @{'IncludeArcMachines'='true'} # <- IncludeArcMachines is important - given you want to target Arc as well as Azure VMs

 New-AzPolicyAssignment -Name '[Windows]TestPSVersion' -PolicyDefinition $PolicyDefinition[0] -Scope $ResourceGroup.ResourceId -PolicyParameterObject $PolicyParameterObject -IdentityType SystemAssigned -Location westeurope -DisplayName '[Windows]TestPSVersion'


 <#

 - Grant a managed identity defined roles with PowerShell
 - Create a remediation task through Azure PowerShell

 https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources

 #>

 $assignment = Get-AzPolicyAssignment -PolicyDefinitionId $Policy.PolicyDefinitionId | Where-Object Name -eq "[Windows]Get PowerShell version"

 # Guest Configuration Resource Contributor
 $PolicyDefinition = Get-AzPolicyDefinition -Name fd41ee42-a0f8-4d22-ad49-2990084ea791
 $roleDefinitionIds =  $PolicyDefinition.Properties.policyRule.then.details.roleDefinitionIds

 if ($roleDefinitionIds.Count -gt 0)
 {
     $roleDefinitionIds | ForEach-Object {
         $roleDefId = $_.Split("/") | Select-Object -Last 1
         New-AzRoleAssignment -Scope $resourceGroup.ResourceId -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId
     }
 }


 $job = Start-AzPolicyRemediation -AsJob -Name ($assignment.PolicyAssignmentId -split '/')[-1] -PolicyAssignmentId $assignment.PolicyAssignmentId -ResourceGroupName $ResourceGroup.ResourceGroupName
 $job | Wait-Job | Receive-Job

 # Tip: Start a remediation that will discover non-compliant resources before remediating by adding:
 # -ResourceDiscoveryMode ReEvaluateCompliance


  Invoke-Command -VMName ArcBox-Win2K22 -ScriptBlock {
    Get-ChildItem 'C:\ProgramData\GuestConfig\Configuration' | ft fullname
   } -Credential $winCreds


   Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
    Get-Content 'C:\Windows\Temp\PSVersion.txt'
   } -Credential $winCreds

   <#
   7.1.2 from path C:\Program Files\AzureConnectedMachineAgent\GCArcService\GC\..\GC\gc_worker.exe
   #>

 Configuration TestPSVersionLinux {
  [CmdletBinding()]

  Import-DscResource -ModuleName 'JanDemoDscResources'

  Node localhost
  {
      PSVersionToFile demo
      {
          Ensure = 'Present'
          Path = '/tmp/PSVersion.txt'
      }
  }
}

TestPSVersionLinux -OutputPath "c:\demo\Guest Configuration\TestPSVersionLinux"

cd C:\demo

New-GuestConfigurationPackage `
 -Name 'TestPSVersionLinux' `
 -Configuration "c:\demo\Guest Configuration\TestPSVersionLinux\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path '/tmp/TestPSVersionLinux.zip'

$StorageAccountKey = Get-AzStorageAccountKey -Name arcboxalfm7s4r4fza2 -ResourceGroupName azure-jumpstart-arcbox-rg
$Context = New-AzStorageContext -StorageAccountName arcboxalfm7s4r4fza2 -StorageAccountKey $StorageAccountKey[0].Value

Set-AzStorageBlobContent -Container "guestconfiguration" -File 'C:\demo\TestPSVersionLinux.zip' -Blob "TestPSVersionLinux.zip" -Context $Context

$contenturi = New-AzStorageBlobSASToken -Context $Context -FullUri -Container guestconfiguration -Blob "TestPSVersionLinux.zip" -Permission rwd


 $PolicyId = (New-Guid).Guid

 New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Linux]Get PowerShell version' `
 -Description 'Returns PowerShell version used by Guest Configuration' `
 -Path 'C:\demo\TestPSVersionLinux\Policy' `
 -Platform 'Linux' `
 -PolicyVersion 1.1.0 `
 -Mode ApplyAndAutoCorrect `
 -Verbose -OutVariable policy

 New-AzPolicyDefinition -Name '[Linux]Get PowerShell version' -Policy $Policy.Path -OutVariable PolicyDefinition

  # Assign policy to resource group containing Azure Arc lab servers
 $ResourceGroup = Get-AzResourceGroup -Name 'azure-jumpstart-arcbox-rg'
 $PolicyParameterObject = @{'IncludeArcMachines'='true'} # <- IncludeArcMachines is important - given you want to target Arc as well as Azure VMs

 New-AzPolicyAssignment -Name '[Linux]TestPSVersion' -PolicyDefinition $PolicyDefinition[0] -Scope $ResourceGroup.ResourceId -PolicyParameterObject $PolicyParameterObject -IdentityType SystemAssigned -Location westeurope -DisplayName '[Linux]TestPSVersion'  -OutVariable Assignment


 <#

 - Grant a managed identity defined roles with PowerShell
 - Create a remediation task through Azure PowerShell

 https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources

 #>

 $assignment
 $assignment.Identity.PrincipalId


 $PolicyDefinition = Get-AzPolicyDefinition -Name fd41ee42-a0f8-4d22-ad49-2990084ea791
 $roleDefinitionIds =  $PolicyDefinition.Properties.policyRule.then.details.roleDefinitionIds

 # 2022-06-17 Returns Contributor, which is likely not needed as the portal suggests Guest Configuration Resource Contributor



 if ($roleDefinitionIds.Count -gt 0)
 {
     $roleDefinitionIds | ForEach-Object {
         #$roleDefId = $_.Split("/") | Select-Object -Last 1
         $roleDefId = (Get-AzRoleDefinition -Name "Guest Configuration Resource Contributor").Id
         New-AzRoleAssignment -Scope $resourceGroup.ResourceId -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId
     }
 }


 $job = Start-AzPolicyRemediation -AsJob -Name ($assignment.PolicyAssignmentId -split '/')[-1] -PolicyAssignmentId $assignment.PolicyAssignmentId -ResourceGroupName $ResourceGroup.ResourceGroupName -ResourceDiscoveryMode ReEvaluateCompliance
 $job | Wait-Job | Receive-Job

 $UbuntuVmIp = Get-VM -Name ArcBox-Ubuntu | Select-Object -ExpandProperty NetworkAdapters | Select-Object -ExpandProperty IPAddresses | Select-Object -Index 0
 $ubuntuSession = New-SSHSession -ComputerName $UbuntuVmIp -Credential $linCreds -Force -WarningAction SilentlyContinue

 $Command = "sudo cat /tmp/PSVersion.txt"
 $(Invoke-SSHCommand -SSHSession $ubuntuSession -Command $Command -Timeout 600 -WarningAction SilentlyContinue).Output

<#
7.2.1 from path /opt/GC_Service/GC/gc_worker
#>

 Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
  gc 'C:\Windows\Temp\PSVersion.txt'
 } -Credential $winCreds

#endregion

#region Create user on Linux

# Collection of Posix tools wrappers
Install-Module -Name nxtools -AllowPrerelease

Get-DscResource -Module nxtools | ft name

Configuration EnsureUserOnLinux
{
    Import-DscResource -ModuleName 'nxtools'

    Node localhost
    {
        nxUser jan {
         UserName = 'jan'
         FullName = 'Jan Egil Ring'
         Password = 'SuperSecure123'
        }
    }
}

EnsureUserOnLinux -OutputPath "c:\demo\Guest Configuration\EnsureUserOnLinux"

# More info about the module
Start-Process 'https://github.com/SynEdgy/nxtools/'

New-GuestConfigurationPackage `
  -Name 'EnsureUserOnLinux' `
  -Configuration ".\Guest Configuration\EnsureUserOnLinux\localhost.mof" `
  -Type AuditAndSet `
  -Force

# Test applying the configuration to Linux machine
sudo pwsh -command 'Start-GuestConfigurationPackageRemediation -Path ./EnsureUserOnLinux.zip'

# After testing, publish
  $ContentUri = Publish-GuestConfigurationPackage -Path 'C:\demo\EnsureUserOnLinux\EnsureUserOnLinux.zip' -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

  $ContentUri

  $PolicyId = (New-Guid).Guid

  New-GuestConfigurationPolicy `
    -PolicyId $PolicyId `
    -ContentUri $ContentUri `
    -DisplayName '[Linux]Ensure user is present' `
    -Description 'Creates user jan if not present.' `
    -Path 'C:\demo\EnsureUserOnLinux\Policy' `
    -Platform 'Linux' `
    -Version 1.0.0 `
    -Mode ApplyAndAutoCorrect `
    -Verbose

    $Policy = Publish-GuestConfigurationPolicy -Path 'C:\demo\EnsureUserOnLinux\Policy'

    $ResourceGroup = Get-AzResourceGroup -Name 'azure-jumpstart-arcbox-rg'
    $Policy = Get-AzPolicyDefinition | Where-Object {$PSItem.Properties.DisplayName -eq '[Linux]Ensure user is present'}
    $PolicyParameterObject = @{'IncludeArcMachines'='True'}
    New-AzPolicyAssignment -Name '[Linux]Ensure user is present' -PolicyDefinition $Policy -Scope $ResourceGroup.ResourceId -PolicyParameterObject $PolicyParameterObject -IdentityType SystemAssigned -Location westeurope -DisplayName '[Linux]Ensure user is present'

    $UbuntuVmIp = Get-VM -Name ArcBox-Ubuntu | Select-Object -ExpandProperty NetworkAdapters | Select-Object -ExpandProperty IPAddresses | Select-Object -Index 0

    $ubuntuSession = New-SSHSession -ComputerName $UbuntuVmIp -Credential $linCreds -Force -WarningAction SilentlyContinue

    $Command = "sudo ls /var/lib/GuestConfig/Configuration"
    $(Invoke-SSHCommand -SSHSession $ubuntuSession -Command $Command -Timeout 600 -WarningAction SilentlyContinue).Output

    $Command = "sudo ls /var/lib/GuestConfig/Configuration/EnsureUserOnLinux"
    $(Invoke-SSHCommand -SSHSession $ubuntuSession -Command $Command -Timeout 600 -WarningAction SilentlyContinue).Output

    $Command = "sudo cat /etc/passwd"
    $(Invoke-SSHCommand -SSHSession $ubuntuSession -Command $Command -Timeout 600 -WarningAction SilentlyContinue).Output

    /var/lib/GuestConfig/arc_policy_logs/gc_agent.log

#endregion

#region Example 1: Targeting guest configuration policies using tags

 <#
 The Tag parameter of New-GuestConfigurationPolicy supports an array of hashtables containing individual tag entires. The tags are added to the If section of the policy definition and can't be modified by a policy assignment.

"if": {
  "allOf" : [
    {
      "allOf": [
        {
          "field": "tags.Role",
          "equals": "Web"
        }
      ]
    },
    {
      // Original guest configuration content
    }
  ]
}

 #>

 # Can also be configured so that tag values becomes input parameters to the DSC configuration: tags.FeatureName

 Configuration WindowsFeatureSet_InstallFromTag
 {
     Import-DscResource -ModuleName 'cFeatureSet'

     cFeatureSet WindowsFeatureSet
     {
         FeatureName = 'placeholder'
         Ensure = 'Present'
     }
 }

$ConfigurationName = 'WindowsFeatureSet_InstallFromTag'

WindowsFeatureSet_InstallFromTag -OutputPath "c:\demo\$ConfigurationName"

cd C:\demo

New-GuestConfigurationPackage `
 -Name $ConfigurationName `
 -Configuration "c:\demo\$ConfigurationName\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
$Parameters = @{
  ResourcePropertyValue = 'Telnet-Client'  # This is where we are replacing the placeholder
  ResourceType = 'cFeatureSet'
  ResourceId = 'WindowsFeatureSet'
  ResourcePropertyName = 'FeatureName'
}

Start-GuestConfigurationPackageRemediation -Path "C:\demo\$ConfigurationName.zip" -Verbose -Parameter $Parameters

Get-GuestConfigurationPackageComplianceStatus -Path "C:\demo\$ConfigurationName.zip" -Verbose -Parameter $Parameters

# Pro tip: Kitchen can be used to test Guest Configurations on many different OS`es on ephemeral cloud VMs simultaneously, here is an example from Gael Colas using the azurerm driver:
Start-Process 'https://gist.github.com/gaelcolas/266b06ab29aa3ecab2628787a77eae7f'

# Pro tip 2: Check out the dsc channel on PowerShell Discord to discuss all things DSC ang Guest Configuration
Start-Process 'https://discord.com/invite/powershell'

$ConfigurationName = 'WindowsFeatureSet_InstallFromTag'
$ComplianceStatus = Get-GuestConfigurationPackageComplianceStatus -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip"
$ComplianceStatus.resources.reasons

$ContentUri = Publish-GuestConfigurationPackage -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip" -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

$ContentUri

$PolicyId = (New-Guid).Guid

$PolicyParameterInfo = @(
  @{
    Name = 'WindowsFeatureName'                                    # Policy parameter name (mandatory)  <--
    DisplayName = 'Windows Feature Name'                           # Policy parameter display name (mandatory)
    Description = 'Name of the windows feature to be installed.'   # Policy parameter description (optional)
    ResourceType = 'cFeatureSet'                                   # DSC configuration resource type (mandatory)
    ResourceId = 'WindowsFeatureSet'                               # DSC configuration resource id (mandatory)
    ResourcePropertyName = 'FeatureName'                           # DSC configuration resource property name (mandatory)
  }
)

New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Windows]Install Windows Features from VM tag FeatureName' `
 -Description 'Install Windows Features based on VM tag value' `
 -Path "C:\demo\$ConfigurationName\Policy" `
 -Platform 'Windows' `
 -Version 1.0.0 `
 -Mode ApplyAndAutoCorrect `
 -Parameter $PolicyParameterInfo `
 -Tag @{FeatureName = "placeholder" } `
 -Verbose

Open-EditorFile -Path "C:\demo\$ConfigurationName\Policy"

$policyDefinition = Get-Content -Path "C:\demo\$ConfigurationName\Policy\DeployIfNotExists.json" | ConvertFrom-Json
$policyDefinition.properties.policyRule.if.allOf[0].allOf = @([PSCustomObject]@{
  field = 'tags.FeatureName'
  exists = 'true'
})

$policyDefinition.properties.policyRule.then.details.deployment.properties.parameters.WindowsFeatureName.value = "[field('tags.FeatureName')]"

# Todo: Automate the following changes
# Line 25: Remove parameter FeatureSet
# Line 242: "equals": "[base64(concat('[WindowsFeatureSet]WindowsFeatureSet;Name', '=', field('tags.FeatureName')))]"
# Line 277: "value": "[field('tags.FeatureName')]"

$policyDefinition | ConvertTo-Json -Depth 50 | Out-File "C:\demo\$ConfigurationName\Policy\DeployIfNotExists.json" -Force

$Policy = Publish-GuestConfigurationPolicy -Path "C:\demo\$ConfigurationName\Policy"

# Assign policy to resource group containing Azure Arc lab servers using the Azure portal

  Start-Process https://portal.azure.com

<# Note
"Error: Failed to Run Consistency for 'WindowsFeatureSet_InstallFromTag' Error : PowerShell DSC resource MSFT_WindowsFeature  failed to execute Test-TargetResource functionality with error message: System.InvalidOperationException: Installing roles and features using PowerShell Desired State Configuration is supported only on Server SKU's. It is not supported on Client SKU."
Changed to DSC resource cFeatureSet as workaround for this demo.
#>

  Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
    #dir C:\ProgramData\GuestConfig\Configuration | select fullname
    #Get-WindowsFeature Web-Server
    Get-WinEvent -LogName Microsoft-Windows-ServerManager-DeploymentProvider/Operational | Where-Object Id -eq 204 | Select-Object TimeCreated,Message
   } -Credential $winCreds

 #endregion

#region Example 2: Targeting guest configuration policies using tags

Configuration StoppedAndDisabledService_FromTag
{
  Import-DscResource -ModuleName PSDscResources

  Service 'StoppedAndDisabled'
  {
      Name = 'placeholder'
      Ensure = 'Present'
      State = 'Stopped'
      StartupType = 'Disabled'
  }
}


$ConfigurationName = 'StoppedAndDisabledService_FromTag'

StoppedAndDisabledService_FromTag -OutputPath "c:\demo\$ConfigurationName"

cd C:\demo

New-GuestConfigurationPackage `
 -Name $ConfigurationName `
 -Configuration "c:\demo\$ConfigurationName\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip" -Verbose

$ComplianceStatus = Get-GuestConfigurationPackageComplianceStatus -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip"
$ComplianceStatus.resources.reasons

$ContentUri = Publish-GuestConfigurationPackage -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip" -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

$ContentUri

$PolicyId = (New-Guid).Guid

$PolicyParameterInfo = @(
  @{
    Name = 'ServiceName'                                           # Policy parameter name (mandatory)
    DisplayName = 'Service Name'                                   # Policy parameter display name (mandatory)
    Description = 'Name of the service.'                           # Policy parameter description (optional)
    ResourceType = 'Service'                                       # DSC configuration resource type (mandatory)
    ResourceId = 'StoppedAndDisabled'                              # DSC configuration resource id (mandatory)
    ResourcePropertyName = 'Name'                                  # DSC configuration resource property name (mandatory)
  }
)

New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Windows]Manage services from VM tag StoppedAndDisabledServices' `
 -Description 'Manage services from VM tag StoppedAndDisabledServices' `
 -Path "C:\demo\$ConfigurationName\Policy" `
 -Platform 'Windows' `
 -Version 1.0.0 `
 -Mode ApplyAndAutoCorrect `
 -Parameter $PolicyParameterInfo `
 -Tag @{ServiceName = "placeholder" } `
 -Verbose

Open-EditorFile -Path "C:\demo\$ConfigurationName\Policy"

$policyDefinition = Get-Content -Path "C:\demo\$ConfigurationName\Policy\DeployIfNotExists.json" | ConvertFrom-Json
$policyDefinition.properties.policyRule.if.allOf[0].allOf = @([PSCustomObject]@{
  field = 'tags.StoppedAndDisabledServices'
  exists = 'true'
})

$policyDefinition.properties.policyRule.then.details.deployment.properties.parameters.ServiceName.value = "[field('tags.StoppedAndDisabledServices')]"

# Todo: Automate the following changes
# Line 25: Remove parameter FeatureSet
# Linje 242: "equals": "[base64(concat('[Service]StoppedAndDisabled;Name', '=', field('tags.StoppedAndDisabledServices')))]"

$policyDefinition | ConvertTo-Json -Depth 50 | Out-File "C:\demo\$ConfigurationName\Policy\DeployIfNotExists.json" -Force

$Policy = Publish-GuestConfigurationPolicy -Path "C:\demo\$ConfigurationName\Policy"

# Assign policy to resource group containing Azure Arc lab servers using the Azure portal

  Start-Process https://portal.azure.com

  Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
    #dir C:\ProgramData\GuestConfig\Configuration | select fullname
    Get-CimInstance win32_service -Filter "name='spooler'"
    } -Credential $winCreds

 #endregion

#region Custom configuration with user-provided parameters (at Azure Policy assignment time)

 Configuration WindowsFeatureSet_Install
 {
     [CmdletBinding()]
     param ()

     Import-DscResource -ModuleName 'cFeatureSet'

     cFeatureSet WindowsFeatureSet
     {
         FeatureName = 'placeholder'
         Ensure = 'Present'
     }
 }

$ConfigurationName = 'WindowsFeatureSet_Install'

WindowsFeatureSet_Install -OutputPath "c:\demo\$ConfigurationName"

cd C:\demo

New-GuestConfigurationPackage `
 -Name $ConfigurationName `
 -Configuration "c:\demo\$ConfigurationName\localhost.mof" `
 -Type AuditAndSet `
 -Force

# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip"

$ComplianceStatus = Get-GuestConfigurationPackageComplianceStatus -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip"
$ComplianceStatus.resources.reasons

$ContentUri = Publish-GuestConfigurationPackage -Path "C:\demo\$ConfigurationName\$ConfigurationName.zip" -ResourceGroupName azure-jumpstart-arcbox-rg -StorageAccountName arcboxalfm7s4r4fza2 | % ContentUri

$ContentUri

$PolicyId = (New-Guid).Guid

$PolicyParameterInfo = @(
  @{
    Name = 'WindowsFeatureName'                                    # Policy parameter name (mandatory)
    DisplayName = 'Windows Feature Name'                           # Policy parameter display name (mandatory)
    Description = 'Name of the windows feature to be installed.'   # Policy parameter description (optional)
    ResourceType = 'cFeatureSet'                                   # DSC configuration resource type (mandatory)
    ResourceId = 'WindowsFeatureSet'                               # DSC configuration resource id (mandatory)
    ResourcePropertyName = 'FeatureName'                           # DSC configuration resource property name (mandatory)
    DefaultValue = 'Windows-Server-Backup'                         # Policy parameter default value (optional)
    AllowedValues = (Get-WindowsFeature).Name                      # Policy parameter allowed values (optional)
  }
)

New-GuestConfigurationPolicy `
 -PolicyId $PolicyId `
 -ContentUri $ContentUri `
 -DisplayName '[Windows]Install Windows Features' `
 -Description 'Install user selected Windows Features' `
 -Path "C:\demo\$ConfigurationName\Policy" `
 -Platform 'Windows' `
 -Version 1.0.0 `
 -Mode ApplyAndAutoCorrect `
 -Parameter $PolicyParameterInfo `
 -Verbose

 $Policy = Publish-GuestConfigurationPolicy -Path "C:\demo\$ConfigurationName\Policy"

# Assign policy to resource group containing Azure Arc lab servers using the Azure portal in order to show the parameter list

  Start-Process https://portal.azure.com

  Invoke-Command -VMName ArcBox-Win2K19,ArcBox-Win2K22 -ScriptBlock {
    #dir C:\ProgramData\GuestConfig\Configuration | select fullname
    Get-WindowsFeature RSAT-AD-PowerShell
   } -Credential $winCreds

#endregion

#region Alerting and monitoring

# Query on various levels against Resource Manager
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'" -PolicyDefinitionName  '[Windows]Ensure PowerShell 7 is installed'
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'" -PolicyAssignmentName '[Windows]Install Windows Feature RSAT-AD-PowerShell'
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'" -ResourceGroupName azure-jumpstart-arcbox-rg
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'" -SubscriptionId b7f543e7-29f0-4e13-8b16-e8e94170be88

# Specific defintions/configurations
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'"
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines'" -PolicyDefinitionName "Ensure Print Spooler is running"

# Filter for non-compliance
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines' and ComplianceState eq 'NonCompliant'" | Format-Table PolicyAssignmentName,ResourceId,Timestamp
Get-AzPolicyState -filter "ResourceType eq 'Microsoft.HybridCompute/machines' and ComplianceState eq 'NonCompliant'" | Format-Table PolicyAssignmentName,@{n="Machine";e={$_.ResourceId.Split("/") | Select-Object -Last 1}},Timestamp

# Same using the CLI
az policy state list --filter "ResourceType eq 'Microsoft.HybridCompute/machines'"

<#

Ideas for alerting
- Azure Automation/Azure Functions - scheduled/cron-based
- Azure Logic Apps - query Azure Resource Manager directly or leverage Azure Automation/Azure Functions
- Dashboards (Azure Worksbooks, Universal Dashboard, Grafana)
- Azure Monitor
   - https://blog.tyang.org/2021/12/06/monitoring-azure-policy-compliance-states-2021-edition/

#>

# Query against Resource Graph
Start-Process "https://portal.azure.com/#view/HubsExtension/ArgQueryBlade"

# Install the Resource Graph module from PowerShell Gallery
Install-Module -Name Az.ResourceGraph

Search-AzGraph  -Query 'guestconfigurationresources | where type == "microsoft.guestconfiguration/guestconfigurationassignments" | where properties["complianceStatus"] == "NonCompliant" | project name,id'

<#

Ideas for alerting - same as above in addition to:

- Azure Logic Apps - query Azure Resource Graph and alert via e-mail, Teams or any channel desird
  - https://www.blueboxes.co.uk/how-to-create-azure-resource-graph-explorer-scheduled-reports-and-email-alerts

#>

#endregion

#region Migration from Azure Automation

Start-Process "https://docs.microsoft.com/en-us/azure/governance/policy/how-to/guest-configuration-azure-automation-migration"

# Changes to behavior in PowerShell Desired State Configuration for guest configuration
Start-Process "https://docs.microsoft.com/en-us/azure/governance/policy/concepts/guest-configuration-custom"

# Quickstart: Convert Group Policy into DSC
Start-Process "https://docs.microsoft.com/en-us/powershell/dsc/quickstarts/gpo-quickstart?view=dsc-1.1"

#endregion