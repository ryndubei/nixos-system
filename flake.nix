{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixos-vfio.url = "github:j-brn/nixos-vfio";
  };

  outputs = { nixpkgs, nixos-vfio, ...}:
    let lib = nixpkgs.lib;
        vfio = nixos-vfio.nixosModules.vfio;
    in 
    {
      nixosConfigurations = 
      {
        nixos-desktop = lib.nixosSystem 
        {
          system = "x86_64-linux";
          modules = 
          [
            ./configuration.nix
            ./virtualisation.nix
            vfio
          ];
        };
        nixos-laptop = lib.nixosSystem 
        {
          system = "x86_64-linux";
          modules = 
          [
            ./configuration.nix
            ./nvidia-laptop.nix
          ];
        };
      };
    };
}