# https://gitlab.com/virtio-fs/virtiofsd/-/issues/96
# https://github.com/virtio-win/kvm-guest-drivers-windows/issues/911#issuecomment-3041077857
{ pkgs }:

let
  vhost-src = pkgs.applyPatches {
    src = fetchGit {
      url = "https://github.com/rust-vmm/vhost.git";
      rev = "875f679ca8a38e38161d106f08568b1618beb953";
    };
    patches = [ ./vhost.patch ];
    name = "vhost";
  };
  vm-memory-src = pkgs.applyPatches {
    src = fetchGit {
      url = "https://github.com/rust-vmm/vm-memory.git";
      rev = "36238bc74e9806d9e2efe5eb8d6b0643a1add5e4";
    };
    patches = [ ./vm-memory.patch ];
    name = "vm-memory-0.16.2";
  };
  virtio-queue = pkgs.applyPatches {
    src = fetchGit {
      url = "https://github.com/rust-vmm/vm-virtio.git";
      rev = "6724256082041b7c65e48fcbd6ae60e99ceda773";
    };
    patches = [ ./vm-virtio-queue.patch ];
    name = "vm-virtio-virtio-queue-v0.14.0";
  };
in pkgs.virtiofsd.overrideAttrs (orig: {
  patches = orig.patches ++ [ ./virtiofsd.patch ];
  srcs = [ orig.src vhost-src vm-memory-src virtio-queue ];
  sourceRoot = ".";
  # 'source' is the directory where 'orig.src' is unpacked to by default
  postUnpack = ''
    mv -t . source/*
    rm -r source
  '';
})
