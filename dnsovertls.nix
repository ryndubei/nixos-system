{ lib, ... }:

# DNS-over-TLS using Mullvad nameserver
{

  # https://mullvad.net/en/help/dns-over-https-and-dns-over-tls
  networking.nameservers = [ "194.242.2.2#dns.mullvad.net" ];

  services.resolved = {
    enable = true;
    domains = [ "~." ];
    dnsovertls = "true";
    dnssec = "true";
    fallbackDns = [ "194.242.2.2#dns.mullvad.net" ];
  };

  # Never use NetworkManager-provided DNS
  networking.networkmanager.dns = lib.mkForce "none";
  networking.networkmanager.settings.main.systemd-resolved = false;
}
