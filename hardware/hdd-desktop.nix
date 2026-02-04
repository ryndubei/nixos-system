{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "bcachefs" ];

  # https://wiki.nixos.org/wiki/Bcachefs
  systemd.services."bcachefs-mount" = {
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      MOUNT_POINT = "/mnt/hard_drive";
      FS_UUID = "e254ac8f-25ca-434b-bef2-039becdaff41";
    };
    script = ''
      #!${pkgs.runtimeShell} -e

      ${pkgs.keyutils}/bin/keyctl link @u @s

      # Check if the drive is already mounted
      if ${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_POINT"; then
        echo "Drive already mounted at $MOUNT_POINT. Skipping..."
        exit 0
      fi

      # Wait for the device to become available
      while [ ! -b "/dev/disk/by-uuid/$FS_UUID" ]; do
        echo "Waiting for $FS_UUID to become available..."
        sleep 5
      done

      # Mount the device
      ${pkgs.bcachefs-tools}/bin/bcachefs mount -o x-gvfs-show -f /etc/secrets/keyfiles/smr_hdd_keyfile.key UUID="$FS_UUID" "$MOUNT_POINT"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
