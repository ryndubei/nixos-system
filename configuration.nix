# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let libvirtEnabled = config.virtualisation.libvirtd.enable;
in
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Note that we assume both devices have an encrypted swap partition labelled
  # "cryptswap", and a second drive mounted at /mnt/hard_drive
  boot.initrd.luks.devices."cryptswap".device = "/dev/disk/by-partlabel/cryptswap";
  fileSystems."/mnt/hard_drive".options = [ "x-gvfs-show" ];

  # Assumption: root LUKS device and cryptswap are on an SSD

  # Allow discards (TRIM) for root LUKS device
  boot.initrd.luks.devices.root.allowDiscards = true;

  # Bypass dm-crypt's workqueues on root and cryptswap: improves SSD performance
  boot.initrd.luks.devices.root.bypassWorkqueues = true;
  boot.initrd.luks.devices.cryptswap.bypassWorkqueues = true;

  # Enable SSD TRIM
  services.fstrim.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Remove certain Gnome packages
  environment.gnome.excludePackages = (with pkgs.gnome; [
    epiphany # web browser
    geary # email reader
    gnome-remote-desktop # remote desktop server
  ]) ++ [
    pkgs.gnome-connections # remote desktop GUI
  ];

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "gb";
    xkb.variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.vasilysterekhov = {
    isNormalUser = true;
    description = "Vasily Sterekhov";
    extraGroups = [ "networkmanager" "wheel" ]
      ++ (lib.optional libvirtEnabled "libvirtd");
    packages = [ ];
  };

  # Automatic upgrades
  #system.autoUpgrade = {
  #  enable = true;
  #  flake = inputs.self.outPath;
  #  operation = "boot";
  #  flags = [
  #    "--update-input"
  #    "nixpkgs"
  #    "-L" # print build logs
  #  ];
  #  dates = "12:00";
  #  randomizedDelaySec = "45min";
  #};

  # Misc services
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  services.tailscale.enable = true;
  # Opt out of sending client logs to Tailscale
  services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];

  # Add fish shell
  programs.fish.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
  ];

  # Install Git
  programs.git.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 11917 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # Enable sync, reboot and remount read-only (see https://bugs.launchpad.net/ubuntu/+source/linux/+bug/194676)
  boot.kernel.sysctl."kernel.sysrq" = 176; # NixOS default: 16 (only the sync command)
  # Documentation: https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html

  # DNS-over-TLS
  # https://docs.quad9.net/Setup_Guides/Linux_and_BSD/Ubuntu_22.04_%28Encrypted%29/
  networking.nameservers = [ "9.9.9.9" "149.112.112.112" ];

  services.resolved = {
    enable = true;
    dnssec = "false"; # "the DNSSEC option should not be enabled in systemd-resolved..."
    domains = [ "~." ];
    fallbackDns = [ "9.9.9.9" "149.112.112.112" ];
    dnsovertls = "true";
  };

  # haskell.nix and https://github.com/input-output-hk/devx
  nix.settings.trusted-public-keys = [
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
    "ghc-nix.cachix.org-1:wI8l3tirheIpjRnr2OZh6YXXNdK2fVQeOI4SVz/X8nA="
    "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
  ];
  nix.settings.substituters = lib.mkAfter [
    "https://cache.iog.io?priority=999"
    "https://cache.zw3rk.com?priority=1000"
    "https://ghc-nix.cachix.org"
    "https://haskell-language-server.cachix.org"
  ];

}

