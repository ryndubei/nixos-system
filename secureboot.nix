{ pkgs, lib, ... }:

# See https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
{
  environment.systemPackages = [
    # `sbctl create-keys` to create and place the keys in /var/lib/sbctl
    #
    # `sbctl enroll-keys` to enroll the keys _after_ enabling Secure Boot in BIOS
    #   and entering secure boot setup mode.
    #   - with --microsoft to enroll Microsoft OEM certificates
    #       - With this option make sure the dbx is nonempty and up-to-date
    #   - or with --tpm-eventlog to enroll OptionROMs checksum seen at last boot
    #       ^ See https://github.com/Foxboron/sbctl/wiki/FAQ#option-rom
    pkgs.sbctl
  ];

  # Lanzaboote replaces the systemd-boot module.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
