[string]$userName = 'ADLabAdmin@ADLab.local'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Add-Computer -DomainName ADLab.local -Credential $credObject -restart -force

#Run commands & PS1s on Azure VMs
#Start-AzVM -ResourceGroupName "ADLab" -Name "MemberServer"
#Set-Location ".\CompTIA studying\Lab Domain Projects\00 Ideas\Setup AD lab in Azure"
#Invoke-AzVMRunCommand -VMName "MemberServer" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\Config the Client.ps1"
