{
  virtualisation = {
    cores = 2;
    memorySize = 1024;
    qemu.options = [
      "-nographic"
      "-vga none -enable-kvm"
      "-device virtio-gpu-pci,xres=720,yres=1440"
      "-serial pty"
    ];
  };
}
