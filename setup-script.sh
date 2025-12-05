#!/bin/bash

# Variables
resourceGroup="finalproject1209"
location="eastasia"
osType="Ubuntu2204"
vmssName="udacity-vmss"
adminName="udacityadmin"
storageAccount="udacitydiag$RANDOM"
bePoolName="$vmssName-bepool"
lbName="$vmssName-lb"
lbRule="$lbName-network-rule"
nsgName="$vmssName-nsg"
vnetName="$vmssName-vnet"
subnetName="$vnetName-subnet"
probeName="tcpProbe"
vmSize="Standard_B1s"
storageType="Standard_LRS"

# Create resource group. 
# This command will not work for the Cloud Lab users. 
# Cloud Lab users can comment this command and 
# use the existing Resource group name, such as, resourceGroup="cloud-demo-153430" 
echo "STEP 0 - Creating resource group $resourceGroup..."

az group create \
--name $resourceGroup \
--location $location \
--verbose

echo "Resource group created: $resourceGroup"

# Create Storage account
echo "STEP 1 - Creating storage account $storageAccount"

az storage account create \
--name $storageAccount \
--resource-group $resourceGroup \
--location $location \
--sku Standard_LRS

echo "Storage account created: $storageAccount"

# Create Network Security Group
echo "STEP 2 - Creating network security group $nsgName"

az network nsg create \
--resource-group $resourceGroup \
--name $nsgName \
--verbose

echo "Network security group created: $nsgName"

# Create VM Scale Set
echo "STEP 3 - Creating VM scale set $vmssName"

az vmss create \
  --resource-group $resourceGroup \
  --name $vmssName \
  --image $osType \
  --vm-sku $vmSize \
  --orchestration-mode Uniform \
  --instance-count 2 \
  --admin-username $adminName \
  --generate-ssh-keys \
  --custom-data cloud-init.txt \
  --upgrade-policy-mode automatic \
  --lb "" \
  --public-ip-address "" \
  --verbose

echo "VM scale set created: $vmssName"

# Get the VMSS VNet and Subnet names (auto-created by the command above)
vnetNameAuto="${vmssName}VNET"
subnetNameAuto="${vmssName}Subnet"

# Create Load Balancer
echo "STEP 3.1 - Creating load balancer $lbName"

az network lb create \
  --resource-group $resourceGroup \
  --name $lbName \
  --sku Standard \
  --backend-pool-name $bePoolName \
  --frontend-ip-name loadBalancerFrontEnd \
  --public-ip-address "${lbName}-pip" \
  --verbose

echo "Load balancer created: $lbName"

# Add VMSS to Load Balancer Backend Pool
echo "STEP 3.2 - Adding VMSS to load balancer backend pool"

az vmss update \
  --resource-group $resourceGroup \
  --name $vmssName \
  --add virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].loadBalancerBackendAddressPools "{\"id\": \"/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/Microsoft.Network/loadBalancers/$lbName/backendAddressPools/$bePoolName\"}" \
  --verbose

echo "VMSS added to load balancer backend pool"

# Associate NSG with VMSS subnet
echo "STEP 4 - Associating NSG: $nsgName with subnet: $subnetNameAuto"

az network vnet subnet update \
--resource-group $resourceGroup \
--name $subnetNameAuto \
--vnet-name $vnetNameAuto \
--network-security-group $nsgName \
--verbose

echo "NSG: $nsgName associated with subnet: $subnetNameAuto"

# Create Health Probe
echo "STEP 5 - Creating health probe $probeName"

az network lb probe create \
  --resource-group $resourceGroup \
  --lb-name $lbName \
  --name $probeName \
  --protocol tcp \
  --port 80 \
  --interval 5 \
  --threshold 2 \
  --verbose

echo "Health probe created: $probeName"

# Create Network Load Balancer Rule
echo "STEP 6 - Creating network load balancer rule $lbRule"

az network lb rule create \
  --resource-group $resourceGroup \
  --name $lbRule \
  --lb-name $lbName \
  --probe-name $probeName \
  --backend-pool-name $bePoolName \
  --backend-port 80 \
  --frontend-ip-name loadBalancerFrontEnd \
  --frontend-port 80 \
  --protocol tcp \
  --verbose

echo "Network load balancer rule created: $lbRule"

# Add port 80 to inbound rule NSG
echo "STEP 7 - Adding port 80 to NSG $nsgName"

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_80 \
--destination-port-ranges 80 \
--direction Inbound \
--priority 100 \
--verbose

echo "Port 80 added to NSG: $nsgName"

# Add port 22 to inbound rule NSG
echo "STEP 8 - Adding port 22 to NSG $nsgName"

az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Port_22 \
--destination-port-ranges 22 \
--direction Inbound \
--priority 110 \
--verbose

echo "Port 22 added to NSG: $nsgName"

echo "VMSS script completed!"
