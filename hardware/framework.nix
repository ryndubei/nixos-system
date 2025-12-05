{
  # unnecessary: already have cros_charge-control
  hardware.framework.enableKmod = false;
  # https://community.frame.work/t/gnome-48-preserve-battery-health/67918/4
  # important: "we swear not to use any other means to change the battery limits"
  # (Battery Extender off, BIOS charge limit off)
  boot.extraModprobeConfig = ''
    options cros_charge_control probe_with_fwk_charge_control=Y
  '';
}
