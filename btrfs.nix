{
  services.btrfs.autoScrub.enable = true;

  # TODO: flat subvolume structure
  fileSystems."/".options = [
    "compress-force=zstd:5"
    "noatime"
    "user_subvol_rm_allowed" # safe: users can already delete their own subvolumes with rm
  ];
}
