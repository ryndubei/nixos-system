{ lib, ... }:

{
  # Enable antenna aggregation for TX
  boot.extraModprobeConfig = ''
    options iwlwifi 11n_disable=8
  '';

  networking.wlanInterfaces = {
    "wlan-station0" = {
      device = "wlp5s0";
      # station also requires a manually set MAC address to work
      # (fails to connect with mac inherited from wlp4s0)
      mac = "02:00:00:00:00:00";
    };
    "wlan-ap0" = {
      device = "wlp5s0";
      mac = "02:00:00:00:00:01";
    };
  };

  networking.wireless.interfaces = [ "wlan-station0" ];

  networking.networkmanager.unmanaged = [ "wlan-ap0" ];

  networking.bridges.br0 = {
    interfaces = [ ];
  };
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = "192.168.123.1";
      prefixLength = 24;
    }
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      bind-interfaces = true;
      dhcp-range = [ "192.168.123.10,192.168.123.254,24h" ];
    };
  };

  networking.firewall.allowedUDPPorts = [
    53
    67
  ]; # DNS & DHCP

  # Enable hostapd
  services.hostapd.enable = true;
  # Disable autostart of hostapd.service
  systemd.services.hostapd.wantedBy = lib.mkForce [ ];
  services.hostapd.radios.wlan-ap0 = {
    band = "5g";
    # must match the channel of the wifi network connected to by wlan-station0
    channel = 149;
    countryCode = "GB";
    noScan = true;
    networks.wlan-ap0 = {
      ssid = "lan025";
      authentication.saePasswords = [
        {
          password = "12345678";
          mac = "ff:ff:ff:ff:ff:ff";
        }
      ];
    };
    settings = {
      # channel + 6 for 80 MHz
      vht_oper_centr_freq_seg0_idx = 155;
      bridge = "br0";
    };
    wifi4 = {
      enable = true;
      capabilities = [
        "HT40+"
        "SMPS_OFF"
        "SHORT-GI-20"
        "SHORT-GI-40"
        "LDPC"
        "TX-STBC"
        "RX-STBC1"
        "DSSS_CCK-40"
        "MAX-AMSDU-7935"
        "MAX-A-MPDU-LEN-EXP3"
      ];
    };
    wifi5 = {
      enable = true;
      require = true;
      operatingChannelWidth = "80";
      capabilities = [
        "MAX-MPDU-11454"
        "VHT160"
        "RXLDPC"
        "SHORT-GI-80"
        "SHORT-GI-160"
        "TX-STBC-2BY1"
        "RX-STBC-1"
        "SU-BEAMFORMEE"
        "MU-BEAMFORMEE"
        "MAX-A-MPDU-LEN-EXP3"
      ];
    };
    wifi6.enable = false;
  };
}
