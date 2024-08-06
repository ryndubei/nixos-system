{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    looking-glass-client
  ];

  virtualisation.kvmfr = {
    enable = true;
    devices = [{
      resolution.width = 1920;
      resolution.height = 1080;
      permissions = {
        user = "qemu-libvirtd";
        group = "libvirtd";
        mode = "0660";
      };
    }];
  };
  # assuming we only need nix-vfio for kvmfr
  virtualisation.libvirtd.deviceACL = [
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
}
