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
            ripgrep
            sd
            killall
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
    { definition = virtualisation/default_network.xml; active = true; }
  ];
}
