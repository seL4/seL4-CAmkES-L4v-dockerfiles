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

# tmp space for building
: "${TEMP_DIR:=/tmp}"
: "${CARGO_HOME:=/etc/cargo}"

# Not strictly necessary, but it makes the apt operations in
# ../dockerfiles/apply-rust.dockerfile work.
as_root apt-get update -q

try_nonroot_first mkdir -p "$TEMP_DIR" || chown_dir_to_user "$TEMP_DIR"
# Get rust nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > "$TEMP_DIR/rustup.sh"

try_nonroot_first mkdir -p "$CARGO_HOME" || chown_dir_to_user "$CARGO_HOME"

sh "$TEMP_DIR/rustup.sh" -y
rm "$TEMP_DIR/rustup.sh"

# Update the current shell
# shellcheck disable=SC1090
source "$CARGO_HOME"/env

# Make sure that all the files are accessible to other users:
try_nonroot_first chmod -R o+rx "$CARGO_HOME"

# Add cargo and rust to PATH
echo "export CARGO_HOME=\"$CARGO_HOME\"" >> "$HOME/.bashrc"
echo "export PATH=\"\$PATH:\$CARGO_HOME/bin\"" >> "$HOME/.bashrc"
