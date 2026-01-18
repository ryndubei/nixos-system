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
    "/snapshots" = mkSubvol "@snapshots";
    "/mnt/cryptroot" = mkSubvol "/";
  };

  services.btrbk.instances."btrbk" = {
    onCalendar = "hourly";
    settings = {
      volume."/mnt/cryptroot" = {
        snapshot_preserve = "7d"; # keep daily snapshots for the last 7 days
        snapshot_preserve_min = "1d"; # keep hourly snapshots for 1 day
        subvolume = {
          "@" = { };
          "@home" = { };
          "@srv" = { };
        };
        snapshot_dir = "@snapshots/btrbk";
      };
    };
  };

  services.beesd.filesystems.root = {
    spec = "/dev/mapper/cryptroot";
    hashTableSizeMB = 512;
    workDir = "@beeshome";
    extraOptions = [ "--loadavg-target" "2.0" ];
    verbosity = "crit";
  };

  services.udisks2.settings."mount_options.conf" = {
    defaults = {
      # Defaults for automounted btrfs filesystems
      btrfs_defaults = [ "compress-force=zstd:5" "noatime" ];
    };
  };
}
