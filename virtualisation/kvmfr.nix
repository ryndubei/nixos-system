{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ looking-glass-client ];

  virtualisation.kvmfr = {
    enable = true;
    devices = [
      {
        # must use size directly instead of resolution:
        # https://github.com/j-brn/nixos-vfio/issues/85
        # https://looking-glass.io/docs/B7/install_libvirt/#determining-memory
        # (2 ^) . ceiling . logBase 2 $ (3840 * 2160 * 4 * 2 / (1024 * 1024)) + 10
        size = 128; # MiB
        permissions = {
          user = "qemu-libvirtd";
          group = "libvirtd";
          mode = "0660";
        };
      }
    ];
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
