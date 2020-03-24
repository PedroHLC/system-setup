#!/usr/bin/env sh
set -o errexit
cd /mnt

# Bootloader
cat <<EOF | sudo tee -a ./boot/loader/entries/arch-tkg.conf > /dev/null
title	Arch Linux for frogs
linux	/vmlinuz-linux-tkg-pds-broadwell
initrd	/initramfs-linux-tkg-pds-broadwell.img
options	zfs=bootfs zfs.zfs_arc_max=536870912 rw quiet iommu=pt module_blacklist=nvidiafb nvidia-drm.modes noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off
EOF

cat <<EOF | sudo tee -a ./boot/loader/entries/arch-tkg-vfio.conf > /dev/null
title	Arch Linux for frogs with VFIO Passthrough
linux	/vmlinuz-linux-tkg-pds-broadwell
initrd	/initramfs-linux-tkg-pds-broadwell.img
options	zfs=bootfs zfs.zfs_arc_max=536870912 rw intel_iommu=on,igfx_off kvm.ignore_msrs=1 iommu=pt module_blacklist=nvidiafb,nvidia_drm,nvidia_modeset,nvidia,nouveau vfio-pci.ids=10de:1347
EOF

cat <<EOF | sudo tee -a ./boot/loader/loader.conf > /dev/null
timeout  4
default  arch-tkg
EOF

echo 'Finished'