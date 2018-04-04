# This file can be sourced from your .bashrc or .zshrc (so make sure it works
# in both zsh and bash!).

setup_ertos_env() {
    # Don't pollute the user's environment
    local ARCH

    ARCH=`uname -m`

    # We currently support the following machines:
    #  Linux i686
    #  Linux x86_64
    #  Mac OS X
    ERTOS_MACHINE=
    [ "$ARCH" = "i686" ] && ERTOS_MACHINE=x86_32
    [ "$ARCH" = "x86_64" ] && ERTOS_MACHINE=x86_64
    [ "`uname -s`" = "Darwin" ] && ERTOS_MACHINE=darwin

    PATH=/opt/ertos/bin:$PATH

    # Preferred ARM toolchain:
    PATH=/opt/ertos/toolchains-$ERTOS_MACHINE/arm-2010.09/bin:$PATH

    # Preferred x86 toolchain:
    PATH=/opt/ertos/toolchains-$ERTOS_MACHINE/ia32-2010.09/bin:$PATH

    # Simulators
    PATH=/opt/ertos/simulators-$ERTOS_MACHINE/:$PATH
}

setup_ertos_env
