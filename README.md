# Nix configurations

This flake manages three NixOS hosts and one standalone Home Manager profile.

| Host | Role | Hardware and storage |
| --- | --- | --- |
| [`desktop`](nixos-configurations/desktop/default.nix) | Former workstation, now connected to the living-room TV full time. Jovian starts a Steam session under Gamescope for a SteamOS-like setup. Sway is also available. | Ryzen 9 5900X, Radeon RX 6800 with 16 GB VRAM, 64 GB RAM, two 2 TB drives in a striped ZFS pool. |
| [`xbox`](nixos-configurations/xbox/default.nix) | Current workstation with Sway. | GenMachine mini PC, Ryzen 9 5900H with integrated Radeon Renoir graphics, 64 GB RAM, single 1 TB ZFS drive. |
| [`vps-lab`](nixos-configurations/vps-lab/default.nix) | Headless Oracle Cloud Infrastructure VPS. | Ampere A1 (Neoverse-N1), 6 vCPUs, 24 GB RAM, 200 GB ext4 disk. |
| [`foreign`](home-configurations/foreign/default.nix) | Work MacBook with system-wide Nix and standalone Home Manager. macOS system configuration stays outside this flake. | Apple M3 Pro. |

All three NixOS hosts import [`core.nix`](nixos-modules/core.nix) and the shared [Home Manager profile](home-configurations/pedrohlc/default.nix). The two full-seat hosts, `desktop` and `xbox`, also import [`seat.nix`](nixos-modules/seat.nix) for Sway, ZFS-based Impermanence. Each host's `specs.nix` feeds the shared [Home Manager utilities](home-configurations/pedrohlc/utils/default.nix), where `hasLinuxSeat` gates Linux desktop settings.

## Safe fallback

Full-seat hosts have a `safe` boot entry. It uses the LTS kernel and stable ZFS and disables Mesa Git. Available to select in systemd-boot if the usual kernel or graphics stack causes trouble.

## ZFS Impermanence on shutdown

On full-seat hosts, [`seat.nix`](nixos-modules/seat.nix) configures a hook in the systemd shutdown ramfs. During a clean shutdown or reboot, it rolls the root dataset back to `zroot/ROOT/empty@start` and syncs the pool. An abrupt power loss can leave root changes in place for the next boot. Data on `/var/persistent` and `/var/residues` lives on separate datasets and survives the rollback.

## Remote logs and maintenance

- [`systemd-journal-upload`](nixos-modules/journal-upload.nix) sends journal over WireGuard to [`systemd-journal-remote` on `vps-lab`](nixos-configurations/vps-lab/servers/journal-remote.nix). Entries already received remain available on the VPS if some ZFS pool becomes inaccessible.
- [`ksysrqd`](nixos-modules/ksysrqd.nix) provides remote Magic SysRq, useful when userspace becomes unresponsive but the kernel and network still respond.

## On-demand services

The [`lazy-proxy` module](nixos-modules/lazy-proxy.nix) takes a map of systemd services and ports and creates a listening socket for each. The first connection starts the backend and `systemd-socket-proxyd` forwards traffic to its loopback listener. Meant to be used within the VPN. 

## Networking

[`common/ssot.nix`](common/ssot.nix) is the shared inventory for hostnames, LAN addresses, WireGuard and SSH public keys, DNS names, and service ports. Each machine's VPN entry derives its IPv4 and IPv6 addresses from its assigned number and the shared prefixes. It also derives its `*.vpn.internal` name from its hostname.

- The [NixOS core](nixos-modules/core.nix) generates `/etc/hosts` entries for VPN names and LAN aliases. It also uses the shared SSH keyring for authorized keys.
- [`vps-lab` is the WireGuard hub](nixos-configurations/vps-lab/servers/wireguard.nix). It builds peers from the inventory. On full-seat hosts, the shared [WireGuard client module](nixos-modules/wireguard-client.nix) uses the hub's public key and endpoint and routes the VPN subnets through `wg0`.
- [AdGuard Home on `vps-lab`](nixos-configurations/vps-lab/servers/adguard.nix) caches upstream DNS responses and uses the same inventory to answer `*.vpn.internal` IPv4 lookups from VPN clients.
