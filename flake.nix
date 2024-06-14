{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixos-vfio = {
      url = "github:j-brn/nixos-vfio";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-vfio, ...}@inputs:
    let lib = nixpkgs.lib;
        vfio = nixos-vfio.nixosModules.vfio;
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
            ./hardware-configuration-desktop.nix
            vfio
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