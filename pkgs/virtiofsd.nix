# https://gitlab.com/virtio-fs/virtiofsd/-/issues/96
# https://github.com/virtio-win/kvm-guest-drivers-windows/issues/911#issuecomment-3041077857
{ pkgs }:

let
  vhost-src = pkgs.applyPatches {
    src = pkgs.fetchFromGitHub {
      owner = "rust-vmm";
      repo = "vhost";
      rev = "875f679ca8a38e38161d106f08568b1618beb953";
      hash = "sha256-f2ieH1rETvdKywP5GFX79Td6vbfZ7EdTrYuu/fnVMZc=";
    };
    patches = [ ./vhost.patch ];
    name = "vhost";
  };
  vm-memory-src = pkgs.applyPatches {
    src = pkgs.fetchFromGitHub {
      owner = "rust-vmm";
      repo = "vm-memory";
      rev = "36238bc74e9806d9e2efe5eb8d6b0643a1add5e4";
      hash = "sha256-H1OYuvbgMHfBAyIPFPnIYOVO8xh1sihsVPFXemDw1Oc=";
    };
    patches = [ ./vm-memory.patch ];
    name = "vm-memory-0.16.2";
  };
  virtio-queue = pkgs.applyPatches {
    src = pkgs.fetchFromGitHub {
      owner = "rust-vmm";
      repo = "vm-virtio";
      rev = "6724256082041b7c65e48fcbd6ae60e99ceda773";
      hash = "sha256-h1OCAiNwW1lL9/URLP8AeXnBLb8KgOXroolzPLU3jf4=";
    };
    patches = [ ./vm-virtio-queue.patch ];
    name = "vm-virtio-virtio-queue-v0.14.0";
  };
in
pkgs.virtiofsd.overrideAttrs (orig: {
  patches = orig.patches ++ [ ./virtiofsd.patch ];
  srcs = [
    orig.src
    vhost-src
    vm-memory-src
    virtio-queue
  ];
  sourceRoot = ".";
  # 'source' is the directory where 'orig.src' is unpacked to by default
  postUnpack = ''
    mv -t . source/*
    rm -r source
  '';
})
