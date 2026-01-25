{
  # Currently, if a disk is entered in boot.initrd.luks and missing,
  # we will fail to boot. So they are in crypttab instead.
  environment.etc.crypttab.text = ''
    # SMR drive, so discards are necessary
    crypthdd UUID=aeff52a8-1998-4bc7-bb81-ed93b6eaa652 /etc/secrets/keyfiles/smr_hdd_keyfile.key discard,nofail
  '';

  fileSystems."/mnt/hard_drive" = {
    device = "/dev/mapper/crypthdd";
    fsType = "ext4";
    options = [ "x-gvfs-show" "nofail" ];
  };

  boot.initrd.kernelModules = [ "dm-cache-default" ];

  # Only enabled for the HDD. Root does not need it because root
  # is on BTRFS with discard=async
  services.fstrim.enable = true;

  # cache_check warning
  services.lvm.boot.thin.enable = true;
}
