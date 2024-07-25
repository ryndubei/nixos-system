{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
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
  };

  outputs = { nixpkgs, nixos-vfio, nixvirt, ... }@inputs:
    let
      lib = nixpkgs.lib;
      nixv = nixvirt.nixosModules.default;
      nvfio = nixos-vfio.nixosModules.default;
    in
    {
      nixosConfigurations =
        {
          nixos-desktop = lib.nixosSystem
            {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules =
                [
                  ./configuration.nix
                  ./headless.nix
                  ./virtualisation.nix
                  ./nvidia.nix
                  ./nvidia-desktop.nix
                  ./virtualisation/win10.nix
                  ./virtualisation/kvmfr.nix
                  ./hardware-configuration-desktop.nix
                  nixv
                  nvfio
                ];
            };
          nixos-laptop = lib.nixosSystem
            {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules =
                [
                  ./configuration.nix
                  ./nvidia.nix
                  ./nvidia-laptop.nix
                  ./virtualisation.nix
                  ./hardware-configuration-laptop.nix
                  nixv
                ];
            };
        };
    };
}
