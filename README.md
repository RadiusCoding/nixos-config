# NixOS Config

NixOS flake-based configuration for x86_64 and aarch64 systems.

## Setup

Clone the repo:

```bash
git clone https://github.com/<your-username>/nixos-config.git ~/nixos-config
```

### x86_64 (sagetop)

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#sagetop
```

### aarch64 (UTM / ARM VM)

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#nixos-arm
```

## After first install

A `rebuild` shell alias is available on both systems, so you can just run:

```bash
rebuild
```
