#Store a password for DSRM
[string]$DSRMPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$SecureStringPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

[string]$userName = 'ADLabAdmin@ADLab.local'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Get-WindowsFeature | Where-Object {$_.Name -like "*RSAT*"} | Install-WindowsFeature -IncludeAllSubFeature

Install-WindowsFeature AD-Domain-Services

Add-Computer -DomainName ADLab.local -Credential $credObject -restart -force

Install-ADDSDomainController -DomainName “ADLab.local” -InstallDns -Credential $credObject -SafeModeAdministratorPassword $SecureStringPassword -Confirm -Force

#Run commands & PS1s on Azure VMs
#Start-AzVM -ResourceGroupName "ADLab" -Name "DC2"
#Set-Location ".\CompTIA studying\Lab Domain Projects\00 Ideas\Setup AD lab in Azure"
#Invoke-AzVMRunCommand -VMName "DC2" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\Config DC2.ps1"
