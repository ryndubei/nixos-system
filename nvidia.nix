{ config, ... }:

{
  # See https://nixos.wiki/wiki/Nvidia

  # Enable OpenGL
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Ensure the NVIDIA flatpak runtime is installed system-wide if Flatpak is enabled
  services.flatpak.packages =
    let nvidiaVersion = builtins.replaceStrings [ "." ] [ "-" ] config.hardware.nvidia.package.version;
    in
    [
      "org.freedesktop.Platform.GL.nvidia-${nvidiaVersion}"
      "org.freedesktop.Platform.GL32.nvidia-${nvidiaVersion}"
    ];
}

