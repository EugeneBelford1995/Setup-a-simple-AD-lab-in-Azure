#Store a password for DSRM
[string]$DSRMPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$SecureStringPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

# Create New Forest, add Domain Controller
$DomainName = "ADLab.local"
$NetBIOSName = "ADLab"
Install-ADDSForest -CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName $DomainName `
-DomainNetbiosName $NetBIOSName `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true `
-SafeModeAdministratorPassword $SecureStringPassword

#Run commands & PS1s on Azure VMs
#Start-AzVM -ResourceGroupName "ADLab" -Name "DC1"
#Set-Location ".\CompTIA studying\Lab Domain Projects\00 Ideas\Setup AD lab in Azure"
#Invoke-AzVMRunCommand -VMName "DC1" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\New Forest.ps1"
