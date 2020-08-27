#!/usr/bin/env sh
set -o errexit
cd /mnt

# Kernel options
_DEFAULT='rw quiet iommu=pt'
_MAKE_LINUX_FAST_AGAIN='noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off'
_NVIDIA_FIX='module_blacklist=nvidiafb nvidia-drm.modes'
_ZFS='zfs=bootfs zfs.zfs_arc_max=536870912'
_PASSTHROUGH='intel_iommu=on,igfx_off kvm.ignore_msrs=1 module_blacklist=nvidiafb,nvidia_drm,nvidia_modeset,nvidia,nouveau vfio-pci.ids=10de:1347'

# Bootloader
cat <<EOF | sudo tee -a ./boot/loader/entries/arch-tkg.conf > /dev/null
title	Arch Linux for frogs
linux	/vmlinuz-linux-tkg-pds-broadwell
initrd	/intel-ucode.img
initrd	/initramfs-linux-tkg-pds-broadwell.img
options	 ${_DEFAULT} ${_ZFS} ${_NVIDIA_FIX} ${_MAKE_LINUX_FAST_AGAIN}
EOF

cat <<EOF | sudo tee -a ./boot/loader/entries/arch-tkg-vfio.conf > /dev/null
title	Arch Linux for frogs with VFIO Passthrough
linux	/vmlinuz-linux-tkg-pds-broadwell
initrd	/intel-ucode.img
initrd	/initramfs-linux-tkg-pds-broadwell.img
options	${_DEFAULT} ${_ZFS} ${_PASSTHROUGH}
EOF

cat <<EOF | sudo tee -a ./boot/loader/entries/arch-lts.conf > /dev/null
title   Break the Glass!
linux   /vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /initramfs-linux-lts.img
options ${_DEFAULT} ${_ZFS} ${_NVIDIA_FIX} ${_MAKE_LINUX_FAST_AGAIN}
EOF

cat <<EOF | sudo tee -a ./boot/loader/loader.conf > /dev/null
timeout  4
default  arch-tkg
EOF

echo 'Finished'