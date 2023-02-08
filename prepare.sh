#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

echo "Install dependencies"

# TODO: drop once new distros are available
test "$(lsb_release -cs)" = "jammy" && sudo add-apt-repository -y ppa:v-launchpad-jochen-sprickerhof-de/sbuild
sudo apt update
sudo apt install -y sbuild mmdebstrap distro-info debian-archive-keyring ccache vcstool python3-rosdep2 catkin python3-bloom curl apt-cacher-ng

echo "Setup build environment"

mkdir -p "$HOME/.cache/sbuild"
mmdebstrap --variant=buildd --include=apt,ccache,auto-apt-proxy \
  --customize-hook='chroot "$1" update-ccache-symlinks' \
  --components=main,universe "$DEB_DISTRO" "$HOME/.cache/sbuild/$DEB_DISTRO-amd64.tar"

ccache --zero-stats --max-size=10.0G

# allow ccache access from sbuild
chmod a+X "$HOME"
chmod -R a+rwX "$HOME/.cache/ccache"

cat << "EOF" > "$HOME/.sbuildrc"
$build_environment = { "CCACHE_DIR" => "/build/ccache" };
$path = "/usr/lib/ccache:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games";
$build_path = "/build/package/";
$dsc_dir = "package";
$unshare_bind_mounts = [ { directory => "$HOME/.cache/ccache", mountpoint => "/build/ccache" } ];
$verbose = 1;
EOF
echo "$SBUILD_CONF" >> "$HOME/.sbuildrc"

cat ~/.sbuildrc

echo "Checkout workspace"

mkdir src
vcs import --recursive --input  "$REPOS_FILE" src
