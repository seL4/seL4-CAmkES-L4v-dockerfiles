#!/bin/bash

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
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

: "${TMP_DIR:=/tmp}"

# Set up tools to compile CakeML
try_nonroot_first git clone https://github.com/HOL-Theorem-Prover/HOL.git "$HOL_DIR" || chown_dir_to_user "$HOL_DIR"
(
    cd "$HOL_DIR"
    git checkout 8384b1c70482d5fbd9ad4d83775cae2a05294515
    mkdir -p tools-poly
    echo "val polymllibdir =\"/usr/lib/x86_64-linux-gnu/\";" > tools-poly/poly-includes.ML
    poly < tools/smart-configure.sml
    bin/build
    chmod -R 757 "$PWD"
) || exit 1

echo "export PATH=\"\$PATH:$HOL_DIR/bin\"" >> "$HOME/.bashrc"

get_cakeml()
{
    local dir="$1"
    local url="$2"
    local filename
    filename="$(basename "$url")"

    try_nonroot_first mkdir "$dir" || chown_dir_to_user "$dir"
    (
        cd "$dir"
        wget "$url" --directory-prefix="$TMP_DIR"
        tar -xvzf "$TMP_DIR/$filename" --strip 1  # Don't untar the top container directory
        rm "$TMP_DIR/$filename"                   # clean up tar

        make cake
    ) || exit 1
}

# These are known-good cakemls
get_cakeml "$CAKEML32_BIN_DIR" "https://cakeml.org/regression/artefacts/989/cake-x64-32.tar.gz"
get_cakeml "$CAKEML64_BIN_DIR" "https://cakeml.org/regression/artefacts/989/cake-x64-64.tar.gz"

if [ "$MAKE_CACHES" = "yes" ] ; then
    try_nonroot_first git clone https://github.com/CakeML/cakeml.git "$CAKEML_DIR" || chown_dir_to_user "$CAKEML_DIR"
    (
        cd "$CAKEML_DIR"
        git checkout 980410c6c89921c2e8950a5127bd9f32791f50bf
        # Pre-build the following cakeml directories to speed up subsequent cakeml app builds
        for dir in "basis" "compiler/parsing";
            do
                (
                    cd ${dir} && "$HOL_DIR/bin/Holmake"
                ) || exit 1
            done
        chmod -R 757 "$CAKEML_DIR"
    ) || exit 1
fi