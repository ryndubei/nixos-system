{ lib, ... }:

{
  services.xserver.videoDrivers = lib.mkBefore [ "modesetting" ];

  # Enable GNOME integration for hybrid graphics
  services.switcherooControl.enable = true;

  specialisation.unload-nvidia.configuration = {
    system.nixos.tags = [ "unload-nvidia" ];

    # Keep nvidia driver unloaded at boot:
    # necessary for dual-GPU passthrough with gnome (gdm?)
    boot.blacklistedKernelModules =
      [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];
  };

  hardware.nvidia = {
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    prime = {
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };
}
