#!/bin/bash

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# Where will cogent libraries go
: "${COGENT_DIR:=/usr/local/cogent}"

# Not strictly necessary, but it makes the apt operations in
# ../dockerfiles/apply-cogent.dockerfile work.
as_root apt-get update -q

try_nonroot_first git clone --depth=1 https://github.com/NICTA/cogent.git "$COGENT_DIR" || chown_dir_to_user "$COGENT_DIR"
(
    cd "$COGENT_DIR/cogent/"
    stack build
    stack install  # installs the binary to $HOME/.local/bin
    as_root ln -s "$HOME/.local/bin/cogent" /usr/local/bin/cogent

    # For now, just put an empty folder where autocorres may go in the future
    mkdir autocorres
) || exit 1


# Get the linux kernel headers, to build filesystems with
as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        linux-headers-amd64 \
        # end of list

# Get the dir of the kernel headers. Because we're in a container, we can't be sure
# that the kernel running is the same as the headers, and so can't use uname
kernel_headers_dir="$(find /usr/src -maxdepth 1 -name 'linux-headers-*amd64' -type d | head -n 1)"

echo "export KERNELDIR=\"$kernel_headers_dir\"" >> "$HOME/.bashrc"

