{ pkgs, ... }: {
  # latest version where nvidia packages compile (2026-03-27)
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelModules = [ "ntsync" ];
}
