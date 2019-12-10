#!/bin/bash

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# Where will cogent libraries go
: "${COGENT_DIR:=/usr/local/cogent}"

git clone https://github.com/NICTA/cogent.git "$COGENT_DIR"
(
    cd "$COGENT_DIR/cogent/"
    stack build
    stack install  # installs the binary to $HOME/.local/bin
) || exit 1

echo "export PATH=\"\$PATH:\$HOME/.local/bin\"" >> "$HOME/.bashrc"