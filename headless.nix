{ ... }:

let
  LAPTOP_SSH_PUBKEY =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5mH6j/tcTVrddxLJprJhh/XN4jwwpCYN2xsyMqI2nIWvmtXggbNK8izG4gpRBIUP3RPKGFflAEM8wKi+O1nTwDvTyp3ciJlMSbreujsnI5Uox3Ca6Dk74/9z+F7rcmXBCJlB0KBEB1v8mhQk6Lm8kRXP0lQStFuerdCyJYEEM8pQwBYtOVM/Dqp93pnLVGgD7EKLcmxWLF4g82Jx/JjSplNT19y0j14Z0Qp9TEpVe3mx51L86G0Yn30DAMDVQO5EzZUlRSEo4KxvNJCz/fpC+hfw7EZ92Yc0gF8HjfMBaKJaqtv+TpxLZMvNwE59vFnG4FyN6jLhmxOLq9Rgx1iCmiG/f7cmykDqcy5BVkzEPdVuWdRNCzhCari4Wrq4RJsRMYSCVDMEtu+Swwi0cSJe79tNBFQKC8QR9lhMEEAwNmMB+gDykH8m6J66DHLG5qb96IYbfDPTlc5PprjlTgFezzY6xuQrmyo1Dlw18AJ/H3HhJM5n2gijjcxKddTkXoo0= vasilysterekhov@nixos-laptop";
in
{
  users.users.vasilysterekhov.openssh.authorizedKeys.keys = [ LAPTOP_SSH_PUBKEY ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
