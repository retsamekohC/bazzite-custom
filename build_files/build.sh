#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### KDE Plasma from the Fedora KDE SIG staging COPR (ahead of Fedora updates)

KDE_REPO=kde-final
KDE_URL="https://download.copr.fedorainfracloud.org/results/@kdesig/kde-final"
KDE_OPTS=(
    --repofrompath="${KDE_REPO},${KDE_URL}/fedora-$(rpm -E %fedora)-x86_64/"
    --setopt="${KDE_REPO}.gpgcheck=1"
    --setopt="${KDE_REPO}.gpgkey=${KDE_URL}/pubkey.gpg"
    # COPR publishes SRPMs in the same repo; their build deps clash with Bazzite's mesa
    --setopt="${KDE_REPO}.excludepkgs=*.src"
)

# Bazzite versionlocks KDE and Qt; drop the locks for packages kde-final ships
dnf5 repoquery "${KDE_OPTS[@]}" --repo="${KDE_REPO}" --qf '%{name}\n' | sort -u > /tmp/kde-final.txt
mapfile -t locked < <(python3 - /tmp/kde-final.txt <<'EOF'
import sys, tomllib
ours = set(open(sys.argv[1]).read().split())
locks = tomllib.load(open("/etc/dnf/versionlock.toml", "rb")).get("packages", [])
print("\n".join(sorted({p["name"] for p in locks} & ours)))
EOF
)
if (( ${#locked[@]} )); then
    dnf5 versionlock delete "${locked[@]}"
fi

dnf5 -y upgrade "${KDE_OPTS[@]}" --from-repo="${KDE_REPO}"

# Fail the build if Plasma did not end up at the kde-final version
want=$(dnf5 repoquery "${KDE_OPTS[@]}" --repo="${KDE_REPO}" --latest-limit=1 --qf '%{evr}' plasma-workspace)
have=$(rpm -q --qf '%{EVR}' plasma-workspace)
[[ "${have}" == "${want}" ]]

### Signature policy for this image

jq '.transports.docker["ghcr.io/retsamekohc/bazzite-custom"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/retsamekohc-bazzite-custom.pub",
        "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json > /tmp/policy.json
cat /tmp/policy.json > /etc/containers/policy.json
