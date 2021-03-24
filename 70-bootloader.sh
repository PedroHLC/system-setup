#!/usr/bin/env sh
set -o errexit
cd /mnt

# Kernel options
_DEFAULT='rw quiet iommu=pt btusb.enable_autosuspend=n systemd.unified_cgroup_hierarchy=1 nowatchdog'
_MAKE_LINUX_FAST_AGAIN='noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off'
_ZFS='zfs=bootfs zfs_arc_max=8589934592'

# Bootloader
cat <<EOF | tee -a ./boot/loader/entries/arch-tkg-muqss.conf > /dev/null
title	Arch Linux for frogs
linux	/vmlinuz-linux-tkg-muqss
initrd	/amd-ucode.img
initrd	/initramfs-linux-tkg-muqss.img
options	 ${_DEFAULT} ${_ZFS} ${_MAKE_LINUX_FAST_AGAIN}
EOF

cat <<EOF | tee -a ./boot/loader/entries/arch-tkg-bmq.conf > /dev/null
title	Arch Linux for frogs
linux	/vmlinuz-linux-tkg-bmq
initrd	/amd-ucode.img
initrd	/initramfs-linux-tkg-bmq.img
options	 ${_DEFAULT} ${_ZFS} ${_MAKE_LINUX_FAST_AGAIN}
EOF

cat <<EOF | tee -a ./boot/loader/entries/arch-lts.conf > /dev/null
title   Break the Glass!
linux   /vmlinuz-linux-lts
initrd  /amd-ucode.img
initrd  /initramfs-linux-lts.img
options ${_DEFAULT} ${_ZFS} ${_MAKE_LINUX_FAST_AGAIN}
EOF

cat <<EOF | tee -a ./boot/loader/loader.conf > /dev/null
timeout  4
default  arch-tkg-muqss
EOF

echo 'Finished'
