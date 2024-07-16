#!/run/current-system/sw/bin/bash
set -x

# Stop display manager
systemctl stop display-manager.service

# Unload all Nvidia drivers
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia_uvm
modprobe -r nvidia

## Load vfio
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci