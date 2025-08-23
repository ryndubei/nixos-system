let
  subvolumeOptions = [
    "compress-force=zstd:5"
    "noatime"
    "user_subvol_rm_allowed" # safe: users can already delete their own subvolumes with rm
  ];
  mkSubvol = name: {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=${name}" ] ++ subvolumeOptions;
  };
in {
  services.btrfs.autoScrub.enable = true;

  fileSystems."/".options = subvolumeOptions;

  fileSystems = {
    "/home" = mkSubvol "@home";
    "/srv" = mkSubvol "@srv";
    "/nix" = mkSubvol "@nix";
    "/tmp" = mkSubvol "@tmp";
    "/var/tmp" = mkSubvol "@var_tmp";
  };
}
