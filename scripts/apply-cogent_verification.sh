#!/bin/bash

set -exuo pipefail

# Source common functions
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD
# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

# Where will cogent libraries go
: "${COGENT_DIR:=/usr/local/cogent}"

# Autocorres version
: "${AC_VER:=autocorres-1.6.1}"
: "${AC_DIR:=$COGENT_DIR/autocorres}"

if [[ ! -d $COGENT_DIR ]]; then
    echo "No COGENT_DIR found! You need to run the apply-cogent.sh script first!"
    exit 1
fi

as_root apt-get update -q
as_root apt-get install -y --no-install-recommends \
    cabal-install/testing \
    # end of list

echo "export PATH=\"\$PATH:\$HOME/.cabal/bin\"" >> "$HOME/.bashrc"

# Do cabal things
cabal update
cabal install \
    happy \
    alex \
    # end of list

for pip in "pip2" "pip3"; do 
    as_root ${pip} install --no-cache-dir \
        ruamel.yaml \
        termcolor 
        # end of list
done

(
    cd "$COGENT_DIR"
    git submodule update --init --depth 1 --recursive -- isabelle
    ln -s "$PWD/isabelle/bin/isabelle" /usr/local/bin/isabelle

    isabelle components -I
    isabelle components -a

    wget "http://ts.data61.csiro.au/projects/TS/autocorres/${AC_VER}.tar.gz"
    tar -xf "${AC_VER}.tar.gz" && rm "${AC_VER}.tar.gz"
    mv "${AC_VER}" "${AC_DIR}"

    (
        cd cogent
        cabal sandbox init --sandbox="$HOME/.cogent-sandbox"
        cabal sandbox add-source ../isa-parser --sandbox="$HOME/.cogent-sandbox"

        sed -i 's/^jobs:.*$/jobs: 2/' "$HOME/.cabal/config"
        cp misc/cabal.config.d/cabal.config-8.6.5 cabal.config

        cabal install --only-dependencies --force-reinstalls --enable-tests --dry -v --flags="haskell-backend docgent"
        cabal install --only-dependencies --force-reinstalls --flags="haskell-backend docgent";  # --enable-tests;
    )
) || exit 1

# Isabelle downloads tar.gz files, and then uncompresses them for its contrib.
# We don't need both the uncompressed AND decompressed versions, but Isabelle
# checks for the tarballs. To fool it, we now truncate the tars and save disk space.
(
    cd "$HOME/.isabelle/contrib"
    truncate -s0 ./*.tar.gz
    ls -lah  # show the evidence
) || exit 1
as_root rm -rf /tmp/isabelle-  # This is a random tmp folder isabelle makes
