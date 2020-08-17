#!/bin/bash

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# General usage scripts location
: "${SCRIPTS_DIR:=$HOME/bin}"

# Are we building inside Trustworthy Systems?
: "${INTERNAL:=no}"

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

    # If we are using snapshot, then turn it on now 
    possibly_toggle_apt_snapshot

    # Tell apt that we should prefer packages from Buster
    as_root tee -a /etc/apt/apt.conf.d/70debconf << EOF
APT::Default-Release "buster";
EOF

    # Tell apt to retry a few times before failing
    as_root tee -a /etc/apt/apt.conf.d/80retries << EOF
APT::Acquire::Retries "3";
EOF

    # These commands supposedly speed-up and better dockerize apt.
    echo "force-unsafe-io" | as_root tee /etc/dpkg/dpkg.cfg.d/02apt-speedup > /dev/null
    echo "Acquire::http {No-Cache=True;};" | as_root tee /etc/apt/apt.conf.d/no-cache > /dev/null
fi

as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        bc \
        ca-certificates \
        devscripts \
        expect \
        git \
        jq \
        make \
        mercurial \
        python-dev \
        python-pip \
        python3-dev \
        python3-pip \
        wget \
        # end of list

# Install python dependencies for both python 2 & 3
# Upgrade pip first, then install setuptools (required for other pip packages)
# Install some basic python tools
for pip in "pip2" "pip3"; do
    as_root ${pip} install --no-cache-dir \
        setuptools
    as_root ${pip} install --no-cache-dir \
        aenum \
        gitlint \
        nose \
        pexpect \
        plyplus \
        sh \
        # end of list
done

# 'reuse' tool only available for python3:
as_root pip3 install --no-cache-dir \
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

# If this is being built inside Trustworthy Systems, get some scripts used to control simulations
if [ "$INTERNAL" = "yes" ]; then
    pushd "$SCRIPTS_DIR"
        git clone --depth=1 http://bitbucket.ts.data61.csiro.au/scm/sel4proj/console_reboot.git
        chmod +x console_reboot/simulate/*
        # Get some useful SEL4 tools
        git clone --depth=1 "${SCM}/sel4/sel4_libs.git"
    popd
fi
