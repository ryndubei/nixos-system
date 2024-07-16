#!/run/current-system/sw/bin/bash
set -x

## Unload vfio
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

modprobe nvidia_drm
modprobe nvidia_modeset

modprobe nvidia_uvm
modprobe nvidia

# Restart Display Manager
systemctl start display-manager.service