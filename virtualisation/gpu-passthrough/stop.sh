#!/run/current-system/sw/bin/bash
set -x

# Attach GPU devices to host
virsh nodedev-reattach $VIRSH_GPU_VIDEO
virsh nodedev-reattach $VIRSH_GPU_AUDIO

## Unload vfio
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

modprobe nvidia_drm
modprobe nvidia_modeset

modprobe nvidia_uvm
modprobe nvidia

# Restart Display Manager
systemctl start display-manager.service