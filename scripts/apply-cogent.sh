#!/bin/bash

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# Where will cogent libraries go
: "${COGENT_DIR:=/usr/local/cogent}"

try_nonroot_first git clone https://github.com/NICTA/cogent.git "$COGENT_DIR" || chown_dir_to_user "$COGENT_DIR"
(
    cd "$COGENT_DIR/cogent/"
    stack build
    stack install  # installs the binary to $HOME/.local/bin
    as_root ln -s "$HOME/.local/bin/cogent" /usr/local/bin/cogent
) || exit 1