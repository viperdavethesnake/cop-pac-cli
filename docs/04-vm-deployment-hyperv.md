# Hyper-V VM Deployment

> **Status:** Documented and ready to script. Not in current scope.
> Scripts will live in `scripts/vm/hyperv/` when implemented.

Source: Admin Guide §2.4.2

---

## Overview

Nexus ships as a `.vhdx` image inside a `.tar.gz` bundle for Hyper-V. Steps:
1. Extract `.vhdx` from the bundle
2. Create a Generation 1 VM in Hyper-V Manager
3. Attach the extracted `.vhdx` as the boot disk
4. Configure CPU, RAM, BIOS boot order, data disk

---

## Prerequisites on Hyper-V Host

- Hyper-V role enabled
- User has permission to create VMs
- An **external virtual switch** is already configured (for LAN access)
- The Hyper-V host must be **on the same LAN segment as a CloudFS node**

---

## Step 1 — Extract VHDX

The bundle is a double-compressed tar: `.tar.gz` → `.tar` → `.vhdx`

**PowerShell:**
```powershell
# Requires tar (built into Windows 10+/Server 2019+)
$bundle = "nexus-hyperv-<buildnumber>.tar.gz"
$dest   = "C:\HyperV\Nexus\"

tar -xzf $bundle -C $dest
# May need to run twice if inner .tar is not auto-extracted
$vhdx = Get-ChildItem $dest -Filter *.vhdx -Recurse | Select-Object -First 1
Write-Host "VHDX: $($vhdx.FullName)"
```

---

## Step 2 — Create VM

**Minimum specs (from guide §2.2):**
- Generation: 1 (required — guide specifies Gen1)
- RAM: 64 GB minimum
- CPU: 16 cores minimum
- Data disk: 4 TB additional SCSI disk

**PowerShell (`Hyper-V` module — Windows only):**
```powershell
$vmName     = "PanzuraNexus"
$vmPath     = "C:\HyperV\Nexus"
$switchName = "ExternalSwitch"   # must exist already
$vhdxPath   = $vhdx.FullName

New-VM `
    -Name               $vmName `
    -MemoryStartupBytes 64GB `
    -Generation         1 `
    -VHDPath            $vhdxPath `
    -SwitchName         $switchName `
    -Path               $vmPath
```

---

## Step 3 — Configure CPU and BIOS

```powershell
# Set minimum 16 processors
Set-VMProcessor -VMName $vmName -Count 16

# Set IDE as first boot device (required for Gen1)
Set-VMBios -VMName $vmName -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
```

---

## Step 4 — Add 4TB Data Disk

```powershell
$dataDiskPath = "$vmPath\$vmName-data.vhdx"

New-VHD -Path $dataDiskPath -SizeBytes 4TB -Dynamic   # or -Fixed for production
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $dataDiskPath
```

> **Note:** Use `-Fixed` for production workloads to avoid thin-provision performance issues on large scans.

---

## Step 5 — Start VM and Get IP

```powershell
Start-VM -Name $vmName

# Wait for VM to boot and get IP (may take a minute)
$vmIp = (Get-VMNetworkAdapter -VMName $vmName).IPAddresses |
    Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } |
    Select-Object -First 1

Write-Host "Nexus IP: $vmIp"
```

---

## After VM is Running

1. Access setup wizard: `https://<vm_ip>`
2. Complete wizard: License → Storage (disk selection) → Network (LAN/WAN, static IP) → NTP → Summary
3. Then proceed with `scripts/nexus/` to configure via REST API

---

## Required PowerShell Modules

The `Hyper-V` module is built into Windows Server and Windows 10/11 Pro with Hyper-V enabled.

```powershell
# Verify module is available
Get-Module -ListAvailable Hyper-V
```

> **macOS note:** Hyper-V is Windows-only. These scripts must run from a Windows host or be invoked remotely via `Invoke-Command` against a Windows Hyper-V host.

---

## Notes

- VLAN settings can be configured on the network adapter post-creation if needed: `Set-VMNetworkAdapterVlan`
- The Hyper-V host itself doesn't need to be the CloudFS node's host — it just needs LAN adjacency
- For VHDX performance on large scans, ensure the storage backing the VHDX is SSD
