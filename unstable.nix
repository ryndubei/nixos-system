# Overlay providing nixpkgs-unstable
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (k: p: {
      unstable = assert p ? unstable == false;
        import inputs.nixpkgs-unstable { inherit (p) system; };
    })
  ];
}
