#!/bin/bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# General usage scripts location
: "${SCRIPTS_DIR:=$HOME/bin}"

# Repo location
: "${REPO_DIR:=$HOME/bin}"

# By default, assume we are on a desktop (usually less destructive)
: "${DESKTOP_MACHINE:=yes}"

# Docker may set this variable - fill if not set
: "${SCM:=https://github.com}"

# Debian Snapshot date
: "${SNAPSHOT_DATE:=20200717T204551Z}"

if [ "$DESKTOP_MACHINE" = "no" ] ; then

    # We need to start with a fresh sources.list, to put in both the regular
    # sources, and the snapshot ones
    as_root tee /etc/apt/sources.list << EOF
# deb http://snapshot.debian.org/archive/debian/$SNAPSHOT_DATE buster main
deb http://deb.debian.org/debian buster main
# deb http://snapshot.debian.org/archive/debian-security/$SNAPSHOT_DATE buster/updates main
deb http://security.debian.org/debian-security buster/updates main
# deb http://snapshot.debian.org/archive/debian/$SNAPSHOT_DATE buster-updates main
deb http://deb.debian.org/debian buster-updates main

EOF
    # Now we need to get stretch (oldstable) and bullseye (testing) from snapshot too
    for release in stretch bullseye; do
        grep "buster main" /etc/apt/sources.list | sed "s/buster/$release/g"  | as_root tee -a "/etc/apt/sources.list"
    done

    # This flag is required so that using older snapshots works OK.
    as_root sed -i  's/deb http:\/\/snapshot/deb \[check-valid-until=no\] http:\/\/snapshot/g' /etc/apt/sources.list

    # Tell apt that we should prefer packages from Buster
    as_root tee -a /etc/apt/apt.conf.d/70debconf << EOF
APT::Default-Release "buster";
EOF

    # Snapshot has some rate limiting, so avoid its ire:
    as_root tee -a /etc/apt/apt.conf.d/80snapshot << EOF
# Acquire::Retries "3";
# Acquire::http::Dl-Limit "300";
EOF

    # These commands supposedly speed-up and better dockerize apt.
    echo "force-unsafe-io" | as_root tee /etc/dpkg/dpkg.cfg.d/02apt-speedup > /dev/null
    echo "Acquire::http {No-Cache=True;};" | as_root tee /etc/apt/apt.conf.d/no-cache > /dev/null

    # If we are using snapshot, then turn it on now
    possibly_toggle_apt_snapshot
fi

as_root apt-get update -q
# Get wget first, so we can bootstrap anything else we need
as_root apt-get install -y --no-install-recommends \
        wget \
        # end of list

################################################################################
#
# We need to upgrade apt first, as the later versions have fixes for interacting
# with Debian Snapshot. See here for more info:
#   https://lists.debian.org/debian-snapshot/2020/08/msg00006.html
# Apt needs to be 2.1.10 or later

# Get the latest version of Apt from bullseye. This installs a bunch of the
# updated dependencies for apt. Note that this apt is coming from snapshot
# itself, so may be behind the real bullseye.
as_root apt-get install -y --no-install-recommends -t bullseye \
        apt \
        # end of list

# Check what version of apt we have.
current_apt_ver=$(apt-cache policy apt | grep "Installed" | xargs | cut -d' ' -f2)  # xargs strips out whitespace

# Put the required version and the current version through semantic versioning sort,
# and see if the top entry is still pointing at the 'needed' tag.
# If so, go get a newer apt from Debian.
# We use 2.1.9, to make this a greater-than operation.
if printf '2.1.9 needed\n%s have\n' "$current_apt_ver" | sort -rV | head -n 1 | grep -q needed; then
    for pkg in "libapt-pkg6.0_2.1.10_amd64.deb" "apt_2.1.10_amd64.deb" ; do
        wget --limit-rate=300k "http://snapshot.debian.org/archive/debian/20200811T150316Z/pool/main/a/apt/$pkg"
        as_root apt install "./$pkg" -t bullseye -y
        rm "./$pkg"  # clean-up package
    done
fi
#
################################################################################

as_root apt-get install -y --no-install-recommends \
        bc \
        ca-certificates \
        devscripts \
        expect \
        git \
        iproute2 \
        iputils-ping \
        jq \
        make \
        python3-dev \
        python3-pip \
        ssh \
        traceroute \
        # end of list

# Install python dependencies for both python 2 & 3
# Upgrade pip first, then install setuptools (required for other pip packages)
# Install some basic python tools
as_root pip3 install --no-cache-dir \
    setuptools
as_root pip3 install --no-cache-dir \
    gitlint \
    nose \
    reuse \
    # end of list


# Add some symlinks so some programs can find things
if [ "$DESKTOP_MACHINE" = "no" ] ; then
    as_root ln -s /usr/bin/hg /usr/local/bin/hg
    as_root ln -s /usr/bin/make /usr/bin/gmake
fi

try_nonroot_first mkdir -p "$SCRIPTS_DIR" || chown_dir_to_user "$SCRIPTS_DIR"

# Install Google's repo
try_nonroot_first mkdir -p "$REPO_DIR" || chown_dir_to_user "$REPO_DIR"
wget -O - https://storage.googleapis.com/git-repo-downloads/repo > "$REPO_DIR/repo"
chmod a+x "$REPO_DIR/repo"
echo "export PATH=\$PATH:$REPO_DIR" >> "$HOME/.bashrc"
export PATH=$PATH:$REPO_DIR  # make repo available ASAP
