{ lib, config, ... }:

let cfg = config.custom.dns-over-tls;
in {
  options.custom.dns-over-tls = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = ''
      Enable DNS-over-TLS using Mullvad nameservers.
    '';
  };

  config = lib.mkIf cfg {

    # https://mullvad.net/en/help/dns-over-https-and-dns-over-tls
    networking.nameservers = [ "194.242.2.2#dns.mullvad.net" ];

    services.resolved = {
      enable = true;
      domains = [ "~." ];
      dnsovertls = "true";
    };

    # Never use NetworkManager-provided DNS
    networking.networkmanager.dns = lib.mkForce "none";
    networking.networkmanager.settings.main.systemd-resolved = false;
  };
}
