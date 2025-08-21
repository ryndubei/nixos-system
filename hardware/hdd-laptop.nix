{
  # it's an SMR drive, so supports TRIM
  boot.initrd.luks.devices.crypthdd.allowDiscards = true;

  # SATA rev 3.1, so we have queued TRIM, meaning sync discard shouldn't
  # impact performance
  fileSystems."/mnt/hard_drive".options = [ "discard" ];
}
