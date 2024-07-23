{ pkgs, lib, ... }:

{
  services.xserver.videoDrivers = lib.mkBefore [ "intel" ];

  # Enable GNOME integration for hybrid graphics
  services.switcherooControl.enable = true;

  # Workaround for https://gitlab.gnome.org/GNOME/mutter/-/issues/2969
  # Wayland GNOME shell insists upon taking up 1MiB of the dGPU
  # VRAM, preventing the dGPU from powering down without killing
  # gnome-shell.
  environment.sessionVariables = {
    "__EGL_VENDOR_LIBRARY_FILENAMES" = "${pkgs.mesa_drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
    "__GLX_VENDOR_LIBRARY_NAME" = "mesa";
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
