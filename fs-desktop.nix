{
  # Assumption: cryptswap LUKS device is on an SSD
  boot.initrd.luks.devices."cryptswap".device =
    "/dev/disk/by-partlabel/cryptswap";

  # Bypass dm-crypt's workqueues on cryptswap: improves SSD performance
  boot.initrd.luks.devices.cryptswap.bypassWorkqueues = true;
}
