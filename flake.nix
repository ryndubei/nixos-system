{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixos-vfio = {
      # TODO: as below
      url = "github:ryndubei/nixos-vfio/patch-1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvirt = {
      # TODO: make PR for the changes in my fork
      url = "github:ryndubei/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fps.url = "github:wamserma/flake-programs-sqlite";
    fps.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, nixos-vfio, nixvirt, nix-flatpak, lanzaboote, fps, ... }@inputs:
    let
      lib = nixpkgs.lib;
      nixv = nixvirt.nixosModules.default;
      nvfio = nixos-vfio.nixosModules.default;
      nflatpak = nix-flatpak.nixosModules.nix-flatpak;
      lzbt = lanzaboote.nixosModules.lanzaboote;
      getProgramsdb = system: fps.packages.${system}.programs-sqlite;
    in {
      nixosConfigurations = {
        nixos-desktop = lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            programsdb = getProgramsdb system;
          };
          modules = [
            { networking.hostName = "nixos-desktop"; }
            ./configuration.nix
            ./headless.nix
            ./virtualisation.nix
            ./nvidia.nix
            ./nvidia-desktop.nix
            ./options/dnsovertls.nix
            ./virtualisation/win10.nix
            ./virtualisation/kvmfr.nix
            ./hardware-configuration-desktop.nix
            ./flatpak.nix
            nixv
            nvfio
            nflatpak
            lzbt
            ./secureboot.nix
            ./wifi-desktop.nix
            {
              networking.firewall.allowedTCPPorts = [
                22565 # mince
              ];
              networking.firewall.allowedUDPPorts = [
                23253 # bg3
              ];
            }
          ];
        };
        nixos-laptop = lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            programsdb = getProgramsdb system;
          };
          modules = [
            {
              networking.hostName = "nixos-laptop";
              # Don't advertise hostname to LAN
              services.avahi.hostName = "";
            }
            ./configuration.nix
            ./nvidia.nix
            ./nvidia-laptop.nix
            ./options/dnsovertls.nix
            ./virtualisation.nix
            ./hardware-configuration-laptop.nix
            ./flatpak.nix
            nixv
            nflatpak
            lzbt
            ./secureboot.nix
          ];
        };
      };
    };
}
