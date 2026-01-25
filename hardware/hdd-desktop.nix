{
  # Currently, if a disk is entered in boot.initrd.luks and missing,
  # we will fail to boot. So they are in crypttab instead.
  environment.etc.crypttab.text = ''
    # SMR drive, so discards are necessary
    crypthdd UUID=3c0aae60-e015-4c03-a736-0d66f66ebc7b /etc/secrets/keyfiles/smr_hdd_keyfile.key discard,nofail
  '';

  fileSystems."/mnt/hard_drive" = {
    device = "/dev/mapper/crypthdd";
    fsType = "ext4";
    options = [ "x-gvfs-show" "nofail" ];
  };

  boot.initrd.kernelModules =
    [ "dm-cache" "dm-cache-smq" "dm-cache-mq" "dm-cache-cleaner" ];
  boot.kernelModules = [
    "dm-cache"
    "dm-cache-smq"
    "dm-cache-mq"
    "dm-cache-cleaner"
    "dm-persistent-data"
    "dm-bio-prison"
    "dm-clone"
    "dm-crypt"
    "dm-writecache"
    "dm-mirror"
    "dm-snapshot"
  ];

  # Only enabled for the HDD. Root does not need it because root
  # is on BTRFS with discard=async
  services.fstrim.enable = true;

  services.lvm.boot.thin.enable = true;
}
