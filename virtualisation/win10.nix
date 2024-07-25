{ inputs, pkgs, lib, config, ... }:
let
  # - Hardware information for the VM

  # CPU topology to use in the VM - leave at least one core for the host
  topology = {
    sockets = 1;
    dies = 1;
    cores = 6;
    threads = 2;
  };

  # CPUs to pin: see `lscpu -e` - in this case CPUs 0 and 8 belong to core
  # 0, so we leave them for the host
  # We assume that cpus-guest ∩ cpus-host = ∅ and cpus-guest ∪ cpus-host = all CPUs
  cpus-guest = [ 2 3 4 5 6 7 10 11 12 13 14 15 ];
  # List of lists to account for hyperthreading
  cpus-host = [ [ 0 8 ] [ 1 9 ] ];

  # suppose the IOMMU address is AA:BB.C
  # then domain = 0, bus = AA, slot = BB, function = C
  gpu-video = { domain = 0; bus = 1; slot = 0; function = 0; };
  gpu-audio = { domain = 0; bus = 1; slot = 0; function = 1; };
  nvme-ssd = { domain = 0; bus = 2; slot = 0; function = 0; };
  wifi-controller = { domain = 0; bus = 4; slot = 0; function = 0; };

  usb-cam-mic = mkUsbPassthrough { vendorId = 3141; productId = 25451; port = 4; };

  # - Helper functions

  # Function to generate a UUID from a name
  # (is it wasteful that this gets recorded in the nix store?)
  mkUuid = name: builtins.readFile (pkgs.runCommandNoCC "uuid-of-${name}" { allowSubstitutes = false; } ''
    echo -n $(${pkgs.libuuid}/bin/uuidgen --name ${name} --namespace @oid --md5) > $out 
  '');

  # (path to script) -> name -> deriv. of script with shebangs patched
  patchShebangs = script-path: name:
    let script-text = builtins.readFile script-path;
    in (pkgs.writeScript name script-text).overrideAttrs
      (old: {
        buildCommand = ''
          ${old.buildCommand}
          patchShebangs $out
        '';
      });

  # Formats input as a PCI device entry of devices.hostdev
  mkPciPassthrough = { source-address, bus-index, rom-file ? null }:
    {
      mode = "subsystem";
      type = "pci";
      managed = true;
      source.address = source-address;
      rom.file = rom-file;
      address = { type = "pci"; domain = 0; bus = bus-index; slot = 0; function = 0; };
    };

  # Formats input as a USB device entry of devices.hostdev
  mkUsbPassthrough = { vendorId, productId, port }:
    {
      mode = "subsystem";
      type = "usb";
      managed = true;
      source = {
        vendor = { id = vendorId; };
        product = { id = productId; };
        startupPolicy = "optional";
      };
      address = { type = "usb"; bus = 0; port = port; };
    };

  # If `set.attr` does not exist, returns `default`, otherwise returns `set.attr`
  getAttrDefault = default: attr: set: if builtins.hasAttr attr set then set.${attr} else default;
in
{
  virtualisation.libvirt.connections."qemu:///system".domains =
    let
      win10-base = (inputs.nixvirt.lib.domain.templates.windows
        rec {
          name = "win10-nogpu";
          uuid = mkUuid name;
          memory = { count = 12; unit = "GiB"; };
          # note: supports only qcow2 here, hence adding disk manually
          # also note: does not actually default to null
          storage_vol = null;
          virtio_net = true;
          virtio_video = false;
          virtio_drive = true;
          nvram_path = "/var/lib/libvirt/qemu/nvram/win10-nogpu_VARS.nvram";
        });

      final-edit = old-xml: (old-xml // {
        vcpu = {
          placement = "static";
          count = topology.sockets * topology.dies * topology.cores * topology.threads;
        };

        # Device information for calming down EAC
        sysinfo = {
          type = "smbios";
          bios.entry = [
            { name = "vendor"; value = "American Megatrends International, LLC."; }
            { name = "version"; value = "F31o"; }
            { name = "date"; value = "09/09/2021"; }
          ];
          system.entry = [
            { name = "manufacturer"; value = "Micro-Star International Co., Ltd."; }
            { name = "product"; value = "MS-7D19"; }
            { name = "version"; value = "1.0"; }
            { name = "serial"; value = "Default string"; }
            { name = "uuid"; value = old-xml.uuid; }
            { name = "sku"; value = "Default string"; }
            { name = "family"; value = "Default string"; }
          ];
        };
        os = old-xml.os // { smbios.mode = "sysinfo"; };
        features = old-xml.features // {
          hyperv = old-xml.features.hyperv // {
            mode = "passthrough";
            vendor_id = {
              # This and
              state = true;
              value = "0123756792CD";
            };
          };
          # this are necessary to bypass code 43 on NVIDIA GPUs
          # and also to bypass EAC
          kvm.hidden.state = true;
        };

        cpu = old-xml.cpu // { inherit topology; };

        devices = old-xml.devices // {
          disk =
            let hasIoThreads = (old-xml ? iothreads.count) && (old-xml.iothreads.count > 0);
            in [
              {
                type = "file";
                device = "disk";
                driver = {
                  name = "qemu";
                  type = "raw";
                  # native is more CPU efficient
                  io = "native";
                  # native is incompatible with host-side caching
                  cache = "none";
                  # enable TRIM
                  discard = "unmap";
                  # assign IO thread 1 to this disk (IO threads must be assigned
                  # to a disk to do anything)
                  iothread = if hasIoThreads then 1 else null;
                  # number of threads inside guest kernel for IO
                  queues = if hasIoThreads then 4 else null;
                };
                # using virtio-blk
                target = { dev = "vda"; bus = "virtio"; };
                # Path to win10 image:
                # virtio drivers must be already installed
                source.file = "/var/lib/libvirt/images/win10.img";
              }
            ];
          hostdev = (getAttrDefault [ ] "hostdev" old-xml.devices) ++ map mkPciPassthrough
            [
              { source-address = nvme-ssd; bus-index = 8; }
            ];
        };
      });

      add-gpu = old-xml: (old-xml // rec {
        # Make the VM distinct
        name = "win10";
        uuid = mkUuid name;
        os = old-xml.os // {
          nvram = old-xml.os.nvram // {
            path = "/var/lib/libvirt/qemu/nvram/win10_VARS.fd";
          };
        };

        cputune =
          let
            # First physical cpu core on the iothread, last on emulator.
            # Any extra cores are left for the host.
            cpus-iothread = builtins.head cpus-host;
            cpus-emu = lib.lists.last cpus-host;
          in
          {
            # Assign isolated CPU cores to the VM
            vcpupin = lib.lists.imap0 (i: a: { vcpu = i; cpuset = toString a; }) cpus-guest;
            # Pin remaining cores to emulator and IO threads
            emulatorpin.cpuset = builtins.concatStringsSep "," (map toString cpus-emu);
            iothreadpin = { iothread = 1; cpuset = builtins.concatStringsSep "," (map toString cpus-iothread); };
          };
        iothreads.count = 1;

        # Pass through GPU devices and USB mouse and keyboard
        devices = old-xml.devices // {
          hostdev = (map mkPciPassthrough
            [
              # A patched ROM is necessary for some NVIDIA cards.
              # See https://github.com/QaidVoid/Complete-Single-GPU-Passthrough?tab=readme-ov-file#vbios-patching
              { source-address = gpu-video; bus-index = 6; rom-file = gpu-passthrough/as21_patched.rom; }
              { source-address = gpu-audio; bus-index = 7; rom-file = gpu-passthrough/as21_patched.rom; }

              # Passing wifi-controller through here as we normally do not want
              # to pass it through when running win10-nogpu
              { source-address = wifi-controller; bus-index = 1; }
            ]) ++ [ usb-cam-mic ];

          input = [
            { type = "keyboard"; bus = "virtio"; }
          ];

          # For connecting via looking-glass
          graphics = {
            type = "spice";
            port = 5900;
            autoport = false;
            listen.type = "address";
            image.compression = false;
            gl.enable = false;
          };

          # Remove unnecessary devices
          channel = builtins.filter (x: x.type != "spiceport") old-xml.devices.channel;
          video.model.type = "none";
          redirdev = null;
          interface = null; # since we are already passing through the network card
        };

        # Use /dev/kvmfr0 as shared memory for looking-glass
        qemu-commandline.arg =
          let
            size-in-bytes = (builtins.head config.virtualisation.kvmfr.devices).size * 1024 * 1024;
          in
          [
            { value = "-device"; }
            { value = ''{"driver":"ivshmem-plain","id":"shmem0","memdev":"looking-glass"}''; }
            { value = "-object"; }
            { value = ''{"qom-type":"memory-backend-file","id":"looking-glass","mem-path":"/dev/kvmfr0","size":${toString size-in-bytes},"share":true}''; }
          ];
      });
    in
    [
      { definition = inputs.nixvirt.lib.domain.writeXML (final-edit win10-base); }
      { definition = inputs.nixvirt.lib.domain.writeXML (final-edit (add-gpu win10-base)); }
    ];
  virtualisation.libvirtd.scopedHooks.qemu =
    let
      host-reserved-cpus = builtins.concatStringsSep "," (map toString (builtins.concatLists cpus-host));
      all-cpus = builtins.concatStringsSep "," (map toString ((builtins.concatLists cpus-host) ++ cpus-guest));
    in
    {
      start = {
        enable = true;
        scope = {
          objects = [ "win10" ];
          operations = [ "prepare" ];
        };
        source = patchShebangs gpu-passthrough/start.sh "start.sh";
        script = null;
      };
      stop = {
        enable = true;
        scope = {
          objects = [ "win10" ];
          operations = [ "release" ];
        };
        source = patchShebangs gpu-passthrough/stop.sh "stop.sh";
        script = null;
      };
      # Isolate host to cpu
      isol-cpus-start = {
        enable = true;
        scope = {
          objects = [ "win10" ];
          operations = [ "started" ];
        };
        script =
          ''
            set -x
            systemctl set-property --runtime -- system.slice AllowedCPUs=${host-reserved-cpus}
            systemctl set-property --runtime -- user.slice AllowedCPUs=${host-reserved-cpus}
            systemctl set-property --runtime -- init.scope AllowedCPUs=${host-reserved-cpus}
          '';
      };
      # Return cpus to host
      isol-cpus-end = {
        enable = true;
        scope = {
          objects = [ "win10" ];
          operations = [ "release" ];
        };
        script =
          ''
            set -x
            systemctl set-property --runtime -- system.slice AllowedCPUs=${all-cpus}
            systemctl set-property --runtime -- user.slice AllowedCPUs=${all-cpus}
            systemctl set-property --runtime -- init.scope AllowedCPUs=${all-cpus}
          '';
      };
    };
}
