{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
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
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fps.url = "github:wamserma/flake-programs-sqlite";
    fps.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixos-vfio, nixvirt, nix-flatpak, lanzaboote, fps
    , nixos-hardware, ... }@inputs:
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
            ./debug.nix
            ./configuration.nix
            ./headless.nix
            ./virtualisation.nix
            ./hardware/nvidia.nix
            ./hardware/nvidia-desktop.nix
            ./virtualisation/win10.nix
            ./virtualisation/kvmfr.nix
            ./hardware/generated/hardware-configuration-desktop.nix
            ./btrfs.nix
            ./flatpak.nix
            ./hardware/hdd-desktop.nix
            nixv
            nvfio
            nflatpak
            lzbt
            ./secureboot.nix
            ./hardware/wifi-desktop.nix
            ./wivrn.nix
            ({ pkgs, ... }: { boot.kernelPackages = pkgs.linuxPackages_6_18; })
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
            { networking.hostName = "nixos-laptop"; }
            ./debug.nix
            ./configuration.nix
            ./virtualisation.nix
            ./hardware/generated/hardware-configuration-laptop.nix
            ./btrfs.nix
            ./flatpak.nix
            nixv
            nflatpak
            lzbt
            ./secureboot.nix
            nixos-hardware.nixosModules.framework-13-7040-amd
          ];
        };
      };
    };
}
