{ pkgs, ... }:

{
  # set kernel params for virtualisation
  boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];
  boot.kernelModules = [ "kvm-intel" "vfio-pci" ];

  # Add packages to use in qemu hooks
  systemd.services.libvirtd = {
    path =
      let
        env = pkgs.buildEnv {
          name = "qemu-hook-env";
          paths = with pkgs; [
            bash
            libvirt
            kmod
            systemd
          ];
        };
      in
      [ env ];
  };

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.swtpm.enable = true;
    qemu.runAsRoot = false;
    deviceACL = [
      "/dev/null"
      "/dev/full"
      "/dev/zero"
      "/dev/random"
      "/dev/urandom"
      "/dev/ptmx"
      "/dev/kvm"
      "/dev/kqemu"
      "/dev/rtc"
      "/dev/hpet"
      "/dev/sev"
    ];
  };
  programs.virt-manager.enable = true;

  # Use NixVirt
  virtualisation.libvirt.enable = true;

  # Enable the default network
  virtualisation.libvirt.connections."qemu:///system".networks = [
    { definition = virtualisation/default_network.xml; active = true; }
  ];
}
