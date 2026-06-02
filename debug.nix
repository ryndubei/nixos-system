{ pkgs, ... }:

{
  # Run (and therefore also natively compile) aarch64-linux binaries,
  # needed to build for Raspberry Pi
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Allows 'nixos-enter'ing into aarch64-linux
  boot.binfmt.preferStaticEmulators = true;

  environment.systemPackages = with pkgs; [
    compsize
    btdu
    lsof
    man-pages
    man-pages-posix
    wget
    wavemon
    wirelesstools
    iw
  ];

  # Enable extra manpages
  documentation.dev.enable = true;
}
