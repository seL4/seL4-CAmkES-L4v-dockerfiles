#!/bin/bash

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

# tmp space for building 
: "${TEMP_DIR:=/tmp}"

# Get dependencies
as_root dpkg --add-architecture i386
as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
    fakeroot \
    lib32stdc++-6-dev \
    linux-libc-dev-i386-cross \
    linux-libc-dev:i386 

# Required for testing
as_root apt-get install -y --no-install-recommends \
    gdb \
    libssl-dev \
    libcunit1-dev \
    libglib2.0-dev \
    libsqlite3-dev \
    libgmp3-dev 

# Required for stack to use tcp properly
as_root apt-get install -y --no-install-recommends \
    netbase \
    pkg-config \
    spin 
        
# Required for rumprun
as_root apt-get install -y --no-install-recommends \
    dh-autoreconf \
    genisoimage \
    gettext \
    rsync \
    xxd 

# Required for cakeml
as_root apt-get install -y --no-install-recommends \
    polyml \
    libpolyml-dev


# Get python deps for CAmkES
for p in "pip2" "pip3"; do
    as_root ${p} install --no-cache-dir \
        camkes-deps \
        jinja2
done

# Get stack
wget -O - https://get.haskellstack.org/ | sh
echo "export PATH=\"\$PATH:\$HOME/.local/bin\"" >> "$HOME/.bashrc"

# CAmkES is hard coded to look for clang in /opt/clang/
as_root ln -s /usr/lib/llvm-3.8 /opt/clang

if [ "$MAKE_CACHES" = "yes" ] ; then
    # Get a project that relys on stack, and use it to init the capDL-tool cache \
    # then delete the repo, because we don't need it.
    try_nonroot_first mkdir -p "$TEMP_DIR/camkes" || chown_dir_to_user "$TEMP_DIR/camkes" 
    (
        cd "$TEMP_DIR/camkes"
        repo init -u "${SCM}/seL4/camkes-manifest.git" --depth=1
        repo sync -j 4
        mkdir build
        (
            cd build
            ../init-build.sh
            ninja
        ) || exit 1
    ) || exit 1
    rm -rf camkes
fi
