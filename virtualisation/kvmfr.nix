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
}
