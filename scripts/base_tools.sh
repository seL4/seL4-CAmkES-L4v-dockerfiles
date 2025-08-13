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
: "${SNAPSHOT_DATE:=20240509T144113Z}"

if [ "$DESKTOP_MACHINE" = "no" ] ; then

    # We need to start with a fresh sources.list, to put in both the regular
    # sources, and the snapshot ones
    as_root tee /etc/apt/sources.list << EOF
# deb http://snapshot.debian.org/archive/debian/$SNAPSHOT_DATE/ trixie main
deb http://deb.debian.org/debian trixie main
# deb http://snapshot.debian.org/archive/debian-security/$SNAPSHOT_DATE/ trixie-security main
deb http://security.debian.org/debian-security trixie-security main
# deb http://snapshot.debian.org/archive/debian/$SNAPSHOT_DATE/ trixie-updates main
deb http://deb.debian.org/debian trixie-updates main
EOF

    # Snapshot has some rate limiting, so avoid its ire
    # Also avoid refusal to use updates from snapshot
    # These are commented out for the "normal" setting -- the comments will be
    # removed by possibly_toggle_apt_snapshot when we are using the snapshot.
    as_root tee -a /etc/apt/apt.conf.d/80snapshot << EOF
# Acquire::Retries "5";
# Acquire::http::Dl-Limit "1000";
# Acquire::Check-Valid-Until false;
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

as_root apt-get install -y --no-install-recommends \
        bc \
        xxd \
        ca-certificates \
        devscripts \
        expect \
        git \
        iproute2 \
        iputils-ping \
        jq \
        make \
        python-is-python3 \
        python3-dev \
        python3-pip \
        ssh \
        traceroute \
        # end of list

# Install python dependencies
# Upgrade pip first, then install setuptools (required for other pip packages)
# Install some basic python tools
as_root pip3 install --break-system-packages --no-cache-dir \
    setuptools
as_root pip3 install --break-system-packages --no-cache-dir \
    gitlint \
    nose \
    reuse \
    # end of list


# Add some symlinks so some programs can find things
if [ "$DESKTOP_MACHINE" = "no" ] ; then
    as_root ln -s /usr/bin/hg /usr/local/bin/hg
fi

try_nonroot_first mkdir -p "$SCRIPTS_DIR" || chown_dir_to_user "$SCRIPTS_DIR"

# Install Google's repo
try_nonroot_first mkdir -p "$REPO_DIR" || chown_dir_to_user "$REPO_DIR"
wget -O - https://storage.googleapis.com/git-repo-downloads/repo > "$REPO_DIR/repo"
chmod a+x "$REPO_DIR/repo"
echo "export PATH=\$PATH:$REPO_DIR" >> "$HOME/.bashrc"
export PATH=$PATH:$REPO_DIR  # make repo available ASAP
