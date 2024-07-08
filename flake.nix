{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixos-vfio = {
      url = "github:j-brn/nixos-vfio";
      # It is a flake, but we only want one internal module
      # without any configuration modifications.
      flake = false;
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
      scopedHooks = "${nixos-vfio}/modules/libvirtd/scopedHooks.nix";
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
                  ./virtualisation.nix
                  ./virtualisation/win10.nix
                  ./hardware-configuration-desktop.nix
                  nixv
                  scopedHooks
                ];
            };
          nixos-laptop = lib.nixosSystem
            {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules =
                [
                  ./configuration.nix
                  ./nvidia-laptop.nix
                  ./hardware-configuration-laptop.nix
                ];
            };
        };
    };
}
