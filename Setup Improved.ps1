Install-Module -Name Az -Repository PSGallery -Force
Update-Module -Name Az -Force
Connect-AzAccount

Install-Module -Name PSReadline
Install-Module -Name Az.Tools.Predictor
Enable-AzPredictor -AllSession

New-AzResourceGroup -Name "ADLab" -Location "East US"

# --- Create & setup networking on the "client" ---

[string]$userName = 'ADLabLocalAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

New-AzVM -ResourceGroupName "ADLab" -Name "MemberServer" -Location "East US" -Image Win2019Datacenter -Size "Standard_B1s" -VirtualNetworkName "ADLabVN" -SubnetName "ADLabSubnet" -Credential $credObject

#Create a public IP
New-AzPublicIpAddress -Name "ADLabPIP" -ResourceGroupName "ADLab" -AllocationMethod Static -Location "East US"
$PIP = Get-AzPublicIpAddress -Name ADLabPIP
$vnet = Get-AzVirtualNetwork -Name "ADLabVN" -ResourceGroupName "ADLab"
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "ADLabSubnet" -VirtualNetwork $vnet
$VM = Get-AzVm -Name "MemberServer" -ResourceGroupName "ADLab"
$NIC = Get-AzNetworkInterface -ResourceGroupName "ADLab" -Name "MemberServer"
$NIC | Set-AzNetworkInterfaceIpConfig -Name "MemberServer" -PublicIPAddress $PIP -Subnet $subnet
$NIC | Set-AzNetworkInterface

Update-AzVm -ResourceGroupName "ADLab" -VM $VM

#Set the client's DNS (Check the DC VM's private IP, 192.168.1.5 was mine)
$PublicNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name MemberServer
$PublicNIC.DnsSettings.DnsServers.Add("192.168.1.5")
$PublicNIC.DnsSettings.DnsServers.Add("192.168.1.7")
$PublicNIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $PublicNIC


# --- Create & setup networking on the DC ---

[string]$userName = 'ADLabAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject2 = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#Create DC1
New-AzVM -ResourceGroupName "ADLab" -Name "DC1" -Location "East US" -Image Win2019Datacenter -Size "Standard_B2s" -VirtualNetworkName "ADLabVN"-SubnetName "ADLabSubnet" -Credential $credObject2

#All ports that a DC uses in the NSG
$RGname="ADLab"
$rulename="Allow_DC_Ports"
$nsgname="DC1"

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange (53, 88, 123, 389, 445, 464, 636, 3268, 3269, '49152-65535') 

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup

#Set the DC1 NIC to a static IP (Check your VM's private IP after it's created & set the private IP to that)
$PrivateDCIP = (Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC1).IpConfigurations.PrivateIpAddress
$DCNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC1
$DCNIC.IpConfigurations[0].PrivateIpAddress = $PrivateDCIP
$DCNIC.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$DCNIC.DnsSettings.DnsServers.Add("127.0.0.1")
$DCNIC.DnsSettings.DnsServers.Add("192.168.1.7")
$DCNIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $DCNIC

# --- Create & setup networking on DC2

[string]$userName = 'ADLabAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject3 = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#Create DC2
New-AzVM -ResourceGroupName "ADLab" -Name "DC2" -Location "East US" -Image Win2019Datacenter -Size "Standard_DS1_v2" -VirtualNetworkName "ADLabVN"-SubnetName "ADLabSubnet" -Credential $credObject3

#All ports that a DC uses in the NSG
$RGname="ADLab"
$rulename="Allow_DC_Ports"
$nsgname="DC2"

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange (53, 88, 123, 389, 445, 464, 636, 3268, 3269, '49152-65535') 

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup

#Set the DC2 NIC to a static IP (Check your VM's private IP after it's created & set the private IP to that)
$PrivateDCIP = (Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2).IpConfigurations.PrivateIpAddress
$DCNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2
$DCNIC.IpConfigurations[0].PrivateIpAddress = $PrivateDCIP
$DCNIC.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$DCNIC.DnsSettings.DnsServers.Add("127.0.0.1")
$DCNIC.DnsSettings.DnsServers.Add("192.168.1.5")
$DCNIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $DCNIC

# --- Start the VMs ---

Start-AzVM -ResourceGroupName ADLab -Name MemberServer
Start-AzVM -ResourceGroupName ADLab -Name DC1
Start-AzVM -ResourceGroupName ADLab -Name DC2

#Run Config the DC
#Run New Forest
#Run Config DC2.ps1
#Run Config the Client
#Lasly, comment out the 'Join-ADDomain', add 'Get-WindowsFeature | Where-Object {$_.Name -like "RSAT"} | Install-WindowsFeature', and run 'Config the Client.ps1' again

#Lastly, RDP into the client
#username = ADLab\ADLabAdmin
#password = MySuperSecurePassword00!!
mstsc /v: $PIP.IpAddress 

#Knock out whatever AD lab tasks you want, ideally using PowerShell_ISE instead of the GUI :P
#Don't forget to shutdown both VMs whenever you're done labbing!
#If you're extra paranoid, pull your public IP from your home RTR and set it the only allowed IP in the MemberServer's NSG rule for RDP access.
#I only left my VMs running for a few minutes at a time just to verify this setup worked.