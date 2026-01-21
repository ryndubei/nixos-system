{
  # SMR drive, so discards are necessary
  boot.initrd.luks.devices.crypthdd.allowDiscards = true;

  # Only enabled for the HDD. Root does not need it because root is on BTRFS
  # with discard=async
  services.fstrim.enable = true;
}
