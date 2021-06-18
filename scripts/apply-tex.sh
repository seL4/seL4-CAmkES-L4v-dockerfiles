#!/bin/bash
#
# Copyright 2021, Proofcraft Pty Ltd
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Install sufficient LaTeX packages to build seL4 reference manual
# doxygen is already installed in sel4.sh

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

possibly_toggle_apt_snapshot

as_root apt-get update -q

as_root apt-get install -y --no-install-recommends \
        texlive \
        texlive-latex-extra \
        # end of list

possibly_toggle_apt_snapshot

# For some reason this pacakge doesn't work on snapshot:
as_root apt-get install -y --no-install-recommends \
        texlive-fonts-extra \
        # end of list
