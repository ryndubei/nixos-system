#!/run/current-system/sw/bin/bash
set -exo pipefail

# Ensure that nvidia drivers are unloaded, or nonzero exit if they are not
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia_uvm
modprobe -r nvidia

## Load vfio
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci