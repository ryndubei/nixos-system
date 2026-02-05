{
  # SMR HDD, so fstrim is necessary
  services.fstrim.enable = true;

  environment.etc.crypttab.text = ''
    crypthdd UUID=a2ae70d7-145c-455e-964a-43e6802080c6 /etc/secrets/keyfiles/smr_hdd_ext4_keyfile.key discard,nofail
  '';

  fileSystems."/mnt/hard_drive" = {
    device = "/dev/mapper/crypthdd";
    fsType = "ext4";
    options = [ "x-gvfs-show" "nofail" ];
  };
}
