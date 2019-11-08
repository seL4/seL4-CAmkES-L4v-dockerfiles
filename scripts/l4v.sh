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

# Some customisability for isabelle
: "${ISABELLE_DIR:=/isabelle}"
: "${NEW_ISABELLE_SETTINGS:=$DIR/../res/isabelle_settings}"

# tmp space for building L4v for caching
: "${TEMP_L4V_LOCATION:=/tmp/verification}"

as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
        librsvg2-bin \
        libwww-perl \
        libxslt-dev \
        libxml2-dev \
        mlton \
        texlive-bibtex-extra \
        texlive-fonts-recommended \
        texlive-generic-extra \
        texlive-latex-extra \
        texlive-metapost \

# dependencies for testing
as_root apt-get install -y --no-install-recommends \
        less \
        python-psutil \
        python-lxml \


# Get l4v and setup isabelle
try_nonroot_first mkdir "$ISABELLE_DIR" || chown_dir_to_user "$ISABELLE_DIR"
ln -s "$ISABELLE_DIR" "$HOME/.isabelle"
mkdir -p "$HOME/.isabelle/etc"

ISABELLE_SETTINGS_LOCATION="$HOME/.isabelle/etc/settings"
cp "$NEW_ISABELLE_SETTINGS" "$ISABELLE_SETTINGS_LOCATION"

if [ "$MAKE_CACHES" = "yes" ] ; then
    # Get a copy of the L4v repo, and build all the isabelle and haskell 
    # components, so we have them cached.
    mkdir -p "$TEMP_L4V_LOCATION"
    (
        cd "$TEMP_L4V_LOCATION"
        repo init -u "${SCM}/seL4/verification-manifest.git" --depth=1
        repo sync -c
        (
            cd l4v 
            ./isabelle/bin/isabelle components -a
            (
                cd spec/haskell
                make sandbox
            ) || exit 1
        ) || exit 1
    ) || exit 1

    # Now cleanup the stuff we don't want cached
    rm -rf "$TEMP_L4V_LOCATION"
    as_root rm -rf /tmp/isabelle-  # This is a random tmp folder isabelle makes

    # Isabelle downloads tar.gz files, and then uncompresses them for its contrib.
    # We don't need both the uncompressed AND decompressed versions, but Isabelle
    # checks for the tarballs. To fool it, we now truncate the tars and save disk space.
    (
        cd "$HOME/.isabelle/contrib"
        truncate -s0 ./*.tar.gz
        ls -lah  # show the evidence
    ) || exit 1
fi