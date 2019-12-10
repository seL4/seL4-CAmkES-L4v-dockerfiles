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

if [ "$DESKTOP_MACHINE" = "no" ] ; then
    # Add an apt preferences file, which states that stable is preferable than testing when automatically
    # picking packages.
    as_root tee -a /etc/apt/preferences > /dev/null << EOF
    Package: *
    Pin: release a=testing
    Pin-Priority: 900
    
    Package: *
    Pin: release a=unstable
    Pin-Priority: 800
EOF
fi

# Add additional architectures for cross-compiled libraries.
# Install the tools required to compile seL4.
as_root apt-get update -q
as_root dpkg --add-architecture armhf
as_root dpkg --add-architecture armel
as_root apt-get install -y --no-install-recommends \
    astyle=3.1-2 \
    build-essential \
    ccache \
    clang \
    cmake \
    cmake-curses-gui \
    coreutils \
    cpio \
    curl \
    device-tree-compiler \
    g++-6 \
    g++-6-aarch64-linux-gnu \
    g++-6-arm-linux-gnueabi \
    g++-6-arm-linux-gnueabihf \
    gcc-6 \
    gcc-6-aarch64-linux-gnu \
    gcc-6-arm-linux-gnueabi \
    gcc-6-arm-linux-gnueabihf \
    gcc-6-base \
    gcc-6-multilib \
    gcc-arm-none-eabi \
    libarchive-dev \
    libcc1-0 \
    libclang-dev \
    libncurses-dev \
    libuv1 \
    libxml2-utils \
    locales \
    ninja-build \
    protobuf-compiler \
    python-protobuf \
    qemu-system-arm \
    qemu-system-x86 \
    sloccount \
    u-boot-tools \
    # end of list


if [ "$DESKTOP_MACHINE" = "no" ] ; then
    # Set default compiler to be gcc-6 using update-alternatives
    for compiler in gcc \
                    g++ \
                    # end of list
        do
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); do
            name=$(basename ${file})
            echo "$name - $file"
            as_root update-alternatives --install "${file}" "${name}" "${file}-6" 50 || :  # don't stress if it doesn't work
            as_root update-alternatives --auto "${name}" || :
        done
    done

    for compiler in gcc-6-arm-linux-gnueabi \
                    cpp-6-arm-linux-gnueabi \
                    gcc-6-aarch64-linux-gnu \
                    cpp-6-aarch64-linux-gnu \
                    gcc-6-arm-linux-gnueabihf \
                    cpp-6-arm-linux-gnueabihf \
                    g++-6-aarch64-linux-gnu \
                    g++-6-arm-linux-gnueabi \
                    g++-6-arm-linux-gnueabihf \
                    # end of list
    do
        echo ${compiler}
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); do
            name=$(basename ${file} | sed 's/-6$//g')
            link=$(echo ${file} | sed 's/-6$//g')
            echo "$name - $file"
            as_root update-alternatives --install "${link}" "${name}" "${file}" 60 || :
            as_root update-alternatives --auto "${name}" || :
        done
    done
fi

# Get seL4 python2/3 deps
# Pylint is for checking included python scripts
for p in "pip2" "pip3"; do
    as_root ${p} install --no-cache-dir \
        pylint \
        sel4-deps \
        # end of list
done


if [ "$MAKE_CACHES" = "yes" ] ; then
    # Build seL4test for a few platforms to populate binary artifact caches.
    # This should improve build times by caching libraries that rarely change.
    mkdir -p ~/.sel4_cache 
    try_nonroot_first mkdir -p "$TEMP_DIR/sel4test" || chown_dir_to_user "$TEMP_DIR/sel4test"
    (
        cd "$TEMP_DIR/sel4test"
        repo init -u "${SCM}/seL4/sel4test-manifest.git" --depth=1
        repo sync -j 4
        mkdir build
        (
            cd build
            for plat in "sabre" "ia32" "x86_64" "tx1" "tk1 -DARM_HYP=ON"; do 
                ../init-build.sh -DPLATFORM=$plat  # no "" around plat, so HYP still works
                ninja
                rm -rf ./*
            done
        ) || exit 1
    ) || exit 1
    rm -rf sel4test
fi

if [ "$DESKTOP_MACHINE" = "no" ] ; then
    # Set up locales. en_AU chosen because we're in Australia.
    echo 'en_AU.UTF-8 UTF-8' | as_root tee /etc/locale.gen > /dev/null
    as_root dpkg-reconfigure --frontend=noninteractive locales
    echo "LANG=en_AU.UTF-8" | as_root tee -a /etc/default/locale > /dev/null
    echo "export LANG=en_AU.UTF-8" >> "$HOME/.bashrc"
fi
