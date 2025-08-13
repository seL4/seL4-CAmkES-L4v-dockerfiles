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

possibly_toggle_apt_snapshot

# Get deps required for VisualCAmkES
as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        graphviz \
        python-pyqt5 \
        python-pyqt5.qtsvg \
        xauth \
        xvfb \
        # end of list

as_root pip3 install --break-system-packages --no-cache-dir \
    ansi2html \
    graphviz \
    pydotplus \
    # end of list

possibly_toggle_apt_snapshot
