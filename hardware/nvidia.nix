{ config, lib, ... }:

{
  # See https://nixos.wiki/wiki/Nvidia

  # Enable OpenGL
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Load nvidia and intel modesetting drivers
  services.xserver.videoDrivers = lib.mkBefore [
    "modesetting"
    "nvidia"
  ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Driver version
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    open = true;

    prime = {
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };

  # Ensure the NVIDIA flatpak runtime is installed system-wide if Flatpak is enabled
  services.flatpak.packages =
    let
      nvidiaVersion = builtins.replaceStrings [ "." ] [ "-" ] config.hardware.nvidia.package.version;
    in
    [
      "org.freedesktop.Platform.GL.nvidia-${nvidiaVersion}"
      "org.freedesktop.Platform.GL32.nvidia-${nvidiaVersion}"
    ];

  # Enable GNOME integration for hybrid graphics
  services.switcherooControl.enable = true;

  specialisation.unload-nvidia.configuration = {
    system.nixos.tags = [ "unload-nvidia" ];

    # Keep nvidia driver unloaded at boot:
    # necessary for dual-GPU passthrough with gnome (gdm?)
    boot.blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];
  };

  # Specialisation for using nvidia without prime offload
  specialisation.nvidia-only.configuration = {
    system.nixos.tags = [ "nvidia-only" ];

    services.switcherooControl.enable = lib.mkForce false;

    hardware.nvidia = {
      powerManagement.finegrained = lib.mkForce false;
      prime.offload.enable = lib.mkForce false;
      prime.offload.enableOffloadCmd = lib.mkForce false;
    };
  };
}
