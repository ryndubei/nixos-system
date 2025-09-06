{ ... }:

{
  # Enable antenna aggregation for TX
  boot.extraModprobeConfig = ''
    options iwlwifi 11n_disable=8
  '';
}
