{ pkgs, ... }:

{
  # Run (and therefore also natively compile) aarch64-linux binaries,
  # needed to build for Raspberry Pi
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Allows 'nixos-enter'ing into aarch64-linux
  boot.binfmt.preferStaticEmulators = true;

  environment.systemPackages = with pkgs; [ man-pages man-pages-posix wget ];

  # Enable extra manpages
  documentation.dev.enable = true;
}
