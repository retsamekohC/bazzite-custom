# bazzite-custom

`ghcr.io/ublue-os/bazzite-nvidia-open:stable` with KDE Plasma, Frameworks and Gear upgraded
from the Fedora KDE SIG staging COPR [`@kdesig/kde-final`](https://copr.fedorainfracloud.org/coprs/g/kdesig/kde-final/),
i.e. ahead of Fedora updates. Rebuilt daily.

## Rebase

```bash
# 1. unsigned first, so the signature policy for this image gets installed
rpm-ostree rebase ostree-unverified-registry:ghcr.io/retsamekohc/bazzite-custom:latest
systemctl reboot

# 2. signed
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/retsamekohc/bazzite-custom:latest
systemctl reboot
```

## Back to stock Bazzite

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia-open:stable
```

## Verify the signature

```bash
cosign verify --key cosign.pub ghcr.io/retsamekohc/bazzite-custom:latest
```
