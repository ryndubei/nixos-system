{ lib, ... }:

{
  hardware.nvidia.prime = {
    #offload = {
    #  enable = true;
    #  enableOffloadCmd = true;
    #};
    sync.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Disable the open source kernel module (old GPU)
  hardware.nvidia.open = false;

  specialisation = {
    travel.configuration = {
      system.nixos.tags = [ "no-dgpu" ];

      services.xserver.videoDrivers =
        lib.mkForce [ "modesetting" "fbdev" ]; # the default value

      hardware.nvidia.modesetting.enable = lib.mkForce false;
      hardware.nvidia.nvidiaSettings = lib.mkForce false;
      hardware.nvidia.prime.sync.enable = lib.mkForce false;

      # Completely disable dGPU
      boot.extraModprobeConfig = ''
        blacklist nouveau
        options nouveau modeset=0
      '';

      services.udev.extraRules = ''
        # Remove NVIDIA USB xHCI Host Controller devices, if present
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
        # Remove NVIDIA USB Type-C UCSI devices, if present
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
        # Remove NVIDIA Audio devices, if present
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
        # Remove NVIDIA VGA/3D controller devices
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
      '';
      boot.blacklistedKernelModules =
        [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
    };
  };
}

