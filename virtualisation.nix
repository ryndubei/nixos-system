{ config, pkgs, ... }:

{
  # set kernel params for virtualisation
  boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];
  boot.kernelModules = [ "kvm-intel" "vfio-pci" ];

  users.users.vasilysterekhov.extraGroups = [ "libvirtd" ];

  systemd.services.libvirtd = { 
    path = let 
             env = pkgs.buildEnv {
               name = "qemu-hook-env";
               paths = with pkgs; [
                 bash
                 libvirt
                 kmod
                 systemd
                 ripgrep
                 sd
               ];
             };
            in [ env ];
    # note that you must place as21_patched.rom into /etc/nixos
    preStart =
    ''
      mkdir -p /var/lib/libvirt/vgabios
      ln -sf /etc/nixos/as21_patched.rom /var/lib/libvirt/vgabios/as21_patched.rom
    '';
  };  

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.runAsRoot = true;
    qemu.ovmf.enable = true;
  };
  programs.virt-manager.enable = true;
  
  virtualisation.libvirtd.scopedHooks.qemu = {

    start = {
      enable = true;

      scope = {
        objects = [ "win10" ];
        operations = [ "prepare" ];
        subOperations = [ "begin" ];
      };

      script = ''
        set -x
        
        # Stop display manager
        systemctl stop display-manager
        # rc-service xdm stop
            
        # Unbind VTconsoles: might not be needed
        echo 0 > /sys/class/vtconsole/vtcon0/bind
        echo 0 > /sys/class/vtconsole/vtcon1/bind
        
        # Unbind framebuffer
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
        
        # Unload NVIDIA kernel modules
        modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia
        
        # Unload AMD kernel module
        # modprobe -r amdgpu
        
        # Detach GPU devices from host
        # Use your GPU and HDMI Audio PCI host device
        virsh nodedev-detach pci_0000_01_00_0
        virsh nodedev-detach pci_0000_01_00_1
        
        # Load vfio module
        modprobe vfio-pci
      '';
    };

    # using this as an exit hook instead because 'stop' causes a black screen
    rebootHost = {
      enable = true;

      scope = {
        objects = [ "win10" ];
        operations = [ "release" ];
        subOperations = [ "end" ];
      };

      script = ''
        reboot
      '';
    };

    #stop = {
    #  enable = true;

    #  scope = {
    #    objects = [ "win10" ];
    #    operations = [ "release" ];
    #    subOperations = [ "end" ];
    #  };

    #  script = ''
    #    set -x
    #    
    #    # Unload vfio module
    #    modprobe -r vfio-pci
    #    
    #    # Attach GPU devices to host
    #    # Use your GPU and HDMI Audio PCI host device
    #    virsh nodedev-reattach pci_0000_01_00_0
    #    virsh nodedev-reattach pci_0000_01_00_1

    #    # Load NVIDIA kernel modules
    #    modprobe nvidia_drm
    #    modprobe nvidia_modeset
    #    modprobe nvidia_uvm
    #    modprobe nvidia
    #    
    #    # Rebind framebuffer to host
    #    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

    #    # Load AMD kernel module
    #    # modprobe amdgpu
    #        
    #    # Bind VTconsoles: might not be needed
    #    echo 1 > /sys/class/vtconsole/vtcon0/bind
    #    echo 1 > /sys/class/vtconsole/vtcon1/bind
    #    
    #    # Restart Display Manager
    #    systemctl start display-manager
    #    # rc-service xdm start
    #  '';
    #};
  };
}

