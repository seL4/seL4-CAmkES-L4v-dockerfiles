#!/bin/bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# Don't make caches by default. Docker will set this to be 'yes'
: "${MAKE_CACHES:=no}"

# By default, assume we are on a desktop (usually less destructive)
: "${DESKTOP_MACHINE:=yes}"

# Docker may set this variable - fill if not set
: "${SCM:=https://github.com}"

# Haskell stack install directory
: "${STACK_ROOT:=/etc/stack}"
: "${STACK_GID:=1234}"

# tmp space for building
: "${TEMP_DIR:=/tmp}"

# Required for cakeml
/tmp/apply-polyml.sh

# At the end of each Docker image, we switch back to normal Debian
# apt repos, so we need to switch back to the Snapshot repos now
possibly_toggle_apt_snapshot

# Get dependencies
as_root dpkg --add-architecture i386
as_root dpkg --add-architecture arm64
as_root apt-get update -q

# lib32stdc++-14-dev for 32-bit Linux VMM
as_root apt-get install -y --no-install-recommends \
    acl \
    fakeroot \
    linux-libc-dev-i386-cross \
    linux-libc-dev:i386 \
    pkg-config \
    spin \
    lib32stdc++-14-dev:amd64 \
    # end of list

# Required for testing
as_root apt-get install -y --no-install-recommends \
    gdb \
    libssl-dev \
    libcunit1-dev \
    libglib2.0-dev \
    libsqlite3-dev \
    libgmp3-dev \
    # end of list

# Required for stack to use tcp properly
as_root apt-get install -y --no-install-recommends \
    netbase \
    # end of list

# Required for rumprun
as_root apt-get install -y --no-install-recommends \
    dh-autoreconf \
    genisoimage \
    gettext \
    rsync \
    xxd \
    # end of list

# Get python deps for CAmkES
as_root pip3 install --break-system-packages --no-cache-dir \
    camkes-deps \
    nose \
    # end of list

# Get stack
export GHCUP_INSTALL_BASE_PREFIX=/opt/ghcup
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
                                                                   BOOTSTRAP_HASKELL_GHC_VERSION=9.2.8 \
                                                                   BOOTSTRAP_HASKELL_CABAL_VERSION=3.10 \
                                                                   BOOTSTRAP_HASKELL_INSTALL_STACK=1 sh

# shellcheck disable=SC1091
source "$GHCUP_INSTALL_BASE_PREFIX/.ghcup/env"
echo "export GHCUP_INSTALL_BASE_PREFIX=/opt/ghcup" >> "$HOME/.bashrc"
echo "source $GHCUP_INSTALL_BASE_PREFIX/.ghcup/env" >> "$HOME/.bashrc"

as_root rm -f "$GHCUP_INSTALL_BASE_PREFIX"/.ghcup/cache/*

# Pick a random group ID, one that won't clash with common user GIDs
as_root groupadd -g "$STACK_GID" stack

try_nonroot_first mkdir -p "$STACK_ROOT" || chown_dir_to_user "$STACK_ROOT"
# Try to use ACLs to keep permissions, but may not work with underlying filesystem
as_root setfacl -Rm "g:stack:rwx" "$STACK_ROOT"
echo "allow-different-user: true" >> "$STACK_ROOT/config.yaml"
as_root chgrp -R stack "$STACK_ROOT"
as_root chmod -R g+rwx "$STACK_ROOT"
as_root chmod g+s "$STACK_ROOT"
echo "export STACK_ROOT=\"$STACK_ROOT\"" >> "$HOME/.bashrc"

if [ "$MAKE_CACHES" = "yes" ] ; then
    # Get a project that relys on stack, and use it to init the capDL-tool cache \
    # then delete the repo, because we don't need it.
    try_nonroot_first mkdir -p "$TEMP_DIR/camkes" || chown_dir_to_user "$TEMP_DIR/camkes"
    pushd "$TEMP_DIR/camkes"
        repo init -u "${SCM}/seL4/camkes-manifest.git" --depth=1
        repo sync -j 4
        mkdir build
        pushd build
            ../init-build.sh
            ninja
        popd
    popd
    rm -rf camkes

    # Update the permissions after cache is full
    as_root chgrp -R stack "$STACK_ROOT"
    as_root chmod -R g+rwx "$STACK_ROOT"
fi

possibly_toggle_apt_snapshot
