# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, programsdb, ... }:

let libvirtEnabled = config.virtualisation.libvirtd.enable;
in {
  # Symlink this directory into /run/current-system
  system.extraSystemBuilderCmds = ''
    ln -s ${./.} $out/nixos-config
  '';

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Allows 'nixos-enter'ing into aarch64-linux
  boot.binfmt.preferStaticEmulators = true;

  # Nix features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/mnt/hard_drive".options = [ "x-gvfs-show" ];

  # Assumption: root LUKS device is on an SSD

  # Allow discards (TRIM) for root LUKS device
  boot.initrd.luks.devices.cryptroot.allowDiscards = true;

  # Bypass dm-crypt's workqueues on root: improves SSD performance
  boot.initrd.luks.devices.cryptroot.bypassWorkqueues = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Use mac address randomisation for wifi
  networking.networkmanager.wifi.macAddress = "random";

  # Location service
  # https://github.com/NixOS/nixpkgs/issues/321121
  services.geoclue2.geoProviderUrl = "https://api.beacondb.net/v1/geolocate";

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

  # Enable Gnome's experimental VRR support
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['variable-refresh-rate']
  '';

  # Remove certain Gnome packages
  environment.gnome.excludePackages = (with pkgs; [
    gnome-remote-desktop # remote desktop server
    gnome-connections # remote desktop GUI
  ]);

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

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  # mullvad-exclude is unused and therefore disabled
  services.mullvad-vpn.enableExcludeWrapper = false;
  # mullvad requires resolved to be enabled to work
  services.resolved.enable = true;

  services.tailscale.enable = true;
  # Opt out of sending client logs to Tailscale
  services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];
  # Tailscale breaks wait-online
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.tailscaled.after = [ "NetworkManager-wait-online.service" ];

  # Add fish shell
  programs.fish.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Firejail, a sandboxing tool
  programs.firejail.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ man-pages man-pages-posix wget ];

  # Enable extra manpages
  documentation.dev.enable = true;

  # Install Git
  programs.git.enable = true;

  # Allow running executables not built for NixOS
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs;
    [
      (runCommandNoCCLocal "steam-run-lib" { } ''
        mkdir $out
        ln -s ${steam-run-free.fhsenv}/usr/lib64 $out/lib
        ln -s ${steam-run-free.fhsenv}/usr/include $out/include
      '')
    ];

  # Make command-not-found work with flakes
  # https://blog.nobbz.dev/2023-02-27-nixos-flakes-command-not-found/
  environment.etc."programs.sqlite".source = programsdb;
  programs.command-not-found.dbPath = "/etc/programs.sqlite";

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
  # networking.firewall.allowedTCPPorts = [ ... ];
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
  boot.kernel.sysctl."kernel.sysrq" =
    176; # NixOS default: 16 (only the sync command)
  # Documentation: https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html

  # Reduce swappiness to 10
  boot.kernel.sysctl."vm.swappiness" = 10;

  custom.dns-over-tls = true;

  # Chromium instance that ignores custom DNS settings for logging into captive portals
  programs.captive-browser = {
    enable = true;
    # must specify particular interface if true
    bindInterface = false;
  };

  # Incrementally optimise the store when a new path is added
  nix.settings.auto-optimise-store = true;

  # haskell.nix and https://github.com/input-output-hk/devx
  nix.settings.trusted-public-keys = [
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
    "ghc-nix.cachix.org-1:wI8l3tirheIpjRnr2OZh6YXXNdK2fVQeOI4SVz/X8nA="
    "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
    "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

    # SSH substituter cache key
    "nixos-desktop-1:uw4gx1dFkH4eaoqQjCFhBdw4dOCUD7pDOhxMgnsv8jc="

    "nixos-laptop-1:gAV7/Xv0mLFFegg7g4XtSag3JNbRe6KUWm6fnlEfhn4="
  ];
  nix.settings.trusted-substituters = [
    "https://ros.cachix.org"
    "https://cache.iog.io"
    "https://cache.zw3rk.com"
    "https://ghc-nix.cachix.org"
    "https://haskell-language-server.cachix.org"
    "https://nix-community.cachix.org"

    # SSH substituter
    "ssh://nix-ssh@nixos-desktop?ssh-key=/home/vasilysterekhov/.ssh/local_cache_client"
  ];

  # Sign all derivations using the local cache key
  nix.settings.extra-secret-key-files = [ "/etc/nix/key.private" ];

  systemd.services.nix-generate-cache-key = {
    description = "Generate local Nix cache key, if not present";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "!/etc/nix/key.private";
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        "${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${config.networking.hostName}-1 /etc/nix/key.private /etc/nix/key.public";
    };
  };

  # Keep build dependencies
  nix.settings.keep-outputs = true;
}

