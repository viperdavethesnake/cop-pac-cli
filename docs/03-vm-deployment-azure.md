# Azure VM Deployment

> **Status:** Documented and ready to script. Not in current scope.
> Scripts will live in `scripts/vm/azure/` when implemented.

Source: Admin Guide §2.3.2, §2.4.1

---

## Overview

Nexus is deployed as a pre-built VHD image. The Azure path is:
1. Upload `.vhd` file to Azure Blob Storage
2. Create an Azure Managed Image from the blob
3. Create a VM from that image
4. Configure networking, data disk, NSG

---

## Step 1 — Upload VHD to Azure Blob Storage

**Manual (portal):**
- Navigate to Storage Accounts → select account (e.g., `eastus`)
- Create a container or use existing
- Upload the `.vhd` file

**PowerShell (`Az.Storage`):**
```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName $rg -Name $storageAccount).Context
Set-AzStorageBlobContent `
    -Container $container `
    -File      "nexus-azure-<buildnumber>.vhd" `
    -Blob      "nexus-azure-<buildnumber>.vhd" `
    -Context   $ctx `
    -BlobType  Page
```

---

## Step 2 — Create Azure Image from Blob

**Manual (portal):**
- Compute infrastructure → Custom images → Images → + Create
- OS Type: Linux, VM Generation: Gen1, Account Type: Premium SSD

**PowerShell (`Az.Compute`):**
```powershell
$imageConfig = New-AzImageConfig -Location $location
$imageConfig = Set-AzImageOsDisk -Image $imageConfig `
    -OsType     Linux `
    -OsState    Generalized `
    -BlobUri    $blobUri `
    -StorageAccountType Premium_LRS

New-AzImage -ResourceGroupName $rg -ImageName $imageName -Image $imageConfig
```

---

## Step 3 — Create VM from Custom Image

**Minimum specs (from guide §2.2):**
- CPU: 16 cores minimum
- RAM: 64 GB minimum
- Data disk: 4 TB SSD (separate from OS disk)
- Network: 10 Gbps LAN

**PowerShell (`Az.Compute`):**
```powershell
$image = Get-AzImage -ResourceGroupName $rg -ImageName $imageName

New-AzVM `
    -ResourceGroupName $rg `
    -Location          $location `
    -Name              $vmName `
    -Image             $image.Id `
    -Size              "Standard_E16s_v5" `   # 16 vCPU / 128 GB — verify sizing
    -Credential        $adminCred `
    -OpenPorts         22, 443
```

---

## Step 4 — Add 4TB Data Disk

```powershell
$vm       = Get-AzVM -ResourceGroupName $rg -Name $vmName
$diskConf = New-AzDiskConfig -Location $location -DiskSizeGB 4096 `
                -SkuName Premium_LRS -CreateOption Empty
$disk     = New-AzDisk -ResourceGroupName $rg -DiskName "$vmName-data" -Disk $diskConf

$vm = Add-AzVMDataDisk -VM $vm -Name "$vmName-data" `
    -CreateOption Attach -ManagedDiskId $disk.Id -Lun 0
Update-AzVM -ResourceGroupName $rg -VM $vm
```

---

## Step 5 — Configure NSG (Inbound Ports)

Required inbound ports: **22, 443, 5671, 5672**

```powershell
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName

foreach ($rule in @(
    @{ Name="SSH";       Port=22;   Priority=1000 }
    @{ Name="HTTPS";     Port=443;  Priority=1010 }
    @{ Name="AMQP-TLS";  Port=5671; Priority=1020 }
    @{ Name="AMQP";      Port=5672; Priority=1030 }
)) {
    Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
        -Name $rule.Name -Protocol Tcp -Direction Inbound `
        -Priority $rule.Priority -SourceAddressPrefix * `
        -SourcePortRange * -DestinationAddressPrefix * `
        -DestinationPortRange $rule.Port -Access Allow
}
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
```

---

## After VM is Running

1. Note the VM IP address
2. Access setup wizard: `https://<vm_ip>`
3. Complete wizard: License → Storage (disk selection) → Network (LAN/WAN, static IP) → NTP → Summary
4. Then proceed with `scripts/nexus/` to configure via REST API

---

## Required PowerShell Modules

```powershell
Install-Module Az.Compute, Az.Storage, Az.Network -Scope CurrentUser
```

---

## Notes

- The Nexus VHD **must be deployed in the same LAN segment as one CloudFS node**. If deploying to Azure, the CloudFS node must also be in Azure (same region/VNet) or connected via ExpressRoute/VPN.
- Use a static IP for Nexus wherever possible — the setup wizard configures it during initial setup.
- After upgrade (`scripts/upgrade.py`), clean up old LVM snapshots with `lvremove` (see Admin Guide §2.5).
