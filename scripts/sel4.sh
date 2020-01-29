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

: "${GCC_V8_AS_DEFAULT:=yes}"

# Add additional architectures for cross-compiled libraries.
# Install the tools required to compile seL4.
as_root apt-get update -q
as_root dpkg --add-architecture armhf
as_root dpkg --add-architecture armel
as_root apt-get install -y --no-install-recommends \
    astyle=3.1-2 \
    build-essential \
    ccache \
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
    g++-8 \
    g++-8-aarch64-linux-gnu \
    g++-8-arm-linux-gnueabi \
    g++-8-arm-linux-gnueabihf \
    gcc-8 \
    gcc-8-aarch64-linux-gnu \
    gcc-8-arm-linux-gnueabi \
    gcc-8-arm-linux-gnueabihf \
    gcc-8-base \
    gcc-8-multilib \
    gcc-arm-none-eabi \
    libarchive-dev \
    libcc1-0 \
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

# We need to get clang 8 from Debian Bullseye
as_root apt-get install -y --no-install-recommends -t bullseye \
    clang=1:8.0-48.3 \
    libclang-dev=1:8.0-48.3 \
    # end of list

if [ "$DESKTOP_MACHINE" = "no" ] ; then
    if [ "$GCC_V8_AS_DEFAULT" = "yes" ] ; then
        compiler_version=8
    else
        compiler_version=6
    fi
    # Set default compiler to be gcc-8 using update-alternatives
    # This is necessary particularly for the cross-compilers, whom sometimes don't put 
    # a genericly named version of themselves in the PATH.
    for compiler in gcc \
                    g++ \
                    # end of list
        do
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); do
            name=$(basename ${file})
            echo "$name - $file"
            as_root update-alternatives --install "${file}" "${name}" "${file}-${compiler_version}" 50 || :  # don't stress if it doesn't work
            as_root update-alternatives --auto "${name}" || :
        done
    done

    for compiler in gcc-${compiler_version}-arm-linux-gnueabi \
                    cpp-${compiler_version}-arm-linux-gnueabi \
                    g++-${compiler_version}-arm-linux-gnueabi \
                    gcc-${compiler_version}-aarch64-linux-gnu \
                    cpp-${compiler_version}-aarch64-linux-gnu \
                    g++-${compiler_version}-aarch64-linux-gnu \
                    gcc-${compiler_version}-arm-linux-gnueabihf \
                    cpp-${compiler_version}-arm-linux-gnueabihf \
                    g++-${compiler_version}-arm-linux-gnueabihf \
                    # end of list
    do
        echo ${compiler}
        for file in $(dpkg-query -L ${compiler} | grep /usr/bin/); do
            name=$(basename ${file} | sed "s/-${compiler_version}\$//g")
            link=$(echo ${file} | sed "s/-${compiler_version}\$//g")
            echo "$name - $file"
            (
                as_root update-alternatives --install "${link}" "${name}" "${file}" 60 && \
                as_root update-alternatives --auto "${name}"
            ) || : # Don't worry if this fails
        done
    done
fi


# Get seL4 python2/3 deps
# Pylint is for checking included python scripts
for pip in "pip2" "pip3"; do
    as_root ${pip} install --no-cache-dir \
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
                ninja || exit 1
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
