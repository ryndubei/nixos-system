{ pkgs, ... }:

{
  services.wivrn = {
    enable = true;

    openFirewall = true;

    # CUDA required for nvenc
    package = pkgs.wivrn.override { config.cudaSupport = true; };
  };
}
