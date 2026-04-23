{ ... }:

let
  LAPTOP_SSH_PUBKEY =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGU+qW7fRnt2I5WYXsAv1/CsuCgvhSNYZXc3O/I4HcSA vasilysterekhov@nixos-laptop";
  LAPTOP_SSH_CACHE_PUBKEY =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDWgOSX8Iukre6eI1s/tGmCk3CYCLshn2/J03XBz8Ts vasilysterekhov@nixos-laptop";
in {
  users.users.vasilysterekhov.openssh.authorizedKeys.keys =
    [ LAPTOP_SSH_PUBKEY ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Serve the Nix store over SSH
  nix.sshServe.enable = true;
  nix.sshServe.keys = [ LAPTOP_SSH_CACHE_PUBKEY ];
}
