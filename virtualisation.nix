{ pkgs, ... }:

{
  # set kernel params for virtualisation
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "vfio-pci"
  ];

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
  };
  programs.virt-manager.enable = true;

  # Use NixVirt
  virtualisation.libvirt.enable = true;

  # Enable the default network
  virtualisation.libvirt.connections."qemu:///system".networks = [
    {
      definition = virtualisation/default_network.xml;
      active = true;
    }
    {
      definition = virtualisation/no_net.xml;
      active = true;
    }
  ];

  # Daemon for sharing files between host and guest
  virtualisation.libvirtd.qemu.vhostUserPackages = [
    # pkgs.virtiofsd 🙅
    # https://gitlab.com/virtio-fs/virtiofsd/-/issues/96
    # "same guest with same win drivers worked with the C implementation, but it's failing now with the rust one"
    (pkgs.callPackage pkgs/virtiofsd.nix { })
  ];
}
