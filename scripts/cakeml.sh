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

: "${HOL_DIR:=/usr/local/bin/HOL}"
: "${CAKEML_DIR:=/usr/local/bin/cakeml}"
: "${CAKEML32_BIN_DIR:=/usr/local/bin/cake-x64-32}"
: "${CAKEML64_BIN_DIR:=/usr/local/bin/cake-x64-64}"
: "${CAKEML_BUILD_NUMBER:=1282}"
: "${HOL_COMMIT:=178b21f73b1ce392ba4db463708c3f25600112f5}"
: "${CAKEML_COMMIT:=6f71ec748c056d9a784b0d01d2b96d77b6e006ca}"
: "${CAKEML_REMOTE:=https://github.com/CakeML/cakeml.git}"

: "${TMP_DIR:=/tmp}"

# Not strictly necessary, but it makes the apt operations in
# ../dockerfiles/cakeml.dockerfile work.
as_root apt-get update -q

# Set up tools to compile CakeML
try_nonroot_first git clone https://github.com/HOL-Theorem-Prover/HOL.git "$HOL_DIR" || chown_dir_to_user "$HOL_DIR"
pushd "$HOL_DIR"
    git checkout $HOL_COMMIT
    mkdir -p tools-poly
    echo "val polymllibdir =\"/usr/lib/x86_64-linux-gnu/\";" > tools-poly/poly-includes.ML
    poly < tools/smart-configure.sml
    bin/build
    chmod -R 757 "$PWD"
popd

get_cakeml()
{
    local dir="$1"
    local url="$2"
    local filename
    filename="$(basename "$url")"

    try_nonroot_first mkdir "$dir" || chown_dir_to_user "$dir"
    pushd "$dir"
        wget -4 "$url" --directory-prefix="$TMP_DIR"
        tar -xvzf "$TMP_DIR/$filename" --strip 1  # Don't untar the top container directory
        rm "$TMP_DIR/$filename"                   # clean up tar

        make cake
    popd
}

# These are known-good cakemls
get_cakeml "$CAKEML32_BIN_DIR" "https://cakeml.org/regression/artefacts/${CAKEML_BUILD_NUMBER}/cake-x64-32.tar.gz"
get_cakeml "$CAKEML64_BIN_DIR" "https://cakeml.org/regression/artefacts/${CAKEML_BUILD_NUMBER}/cake-x64-64.tar.gz"

if [ "$MAKE_CACHES" = "yes" ] ; then
    try_nonroot_first git clone "$CAKEML_REMOTE" "$CAKEML_DIR" || chown_dir_to_user "$CAKEML_DIR"
    pushd "$CAKEML_DIR"
        git checkout $CAKEML_COMMIT
        # Pre-build the following cakeml directories to speed up subsequent cakeml app builds
        for dir in "basis" "compiler/parsing";
            do
                pushd ${dir}
                    "$HOL_DIR/bin/Holmake"
                popd
            done
        chmod -R 757 "$CAKEML_DIR"
    popd
fi
