{ pkgs, ... }:

{
  # Fix internal microphone not working when using headphones
  # (black mic overridden to internal mic)
  hardware.firmware = [
    (pkgs.writeTextDir "/lib/firmware/hda-jack-retask.fw"
      (builtins.readFile ./hda-jack-retask.fw))
  ];
}
