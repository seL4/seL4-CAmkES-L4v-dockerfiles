#!/bin/sh
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -ef

############################################
# env setup

: "${DOCKERHUB:=trustworthysystems/}"

# Base images
: "${DEBIAN_IMG:=debian:trixie-slim}"
: "${BASETOOLS_IMG:=base_tools}"

# Core images
: "${SEL4_IMG:=sel4}"
: "${CAMKES_IMG:=camkes}"
: "${L4V_IMG:=l4v}"

# Allow override of which 'version' (aka tag) of an image to pull in
: "${IMG_POSTFIX:=:latest}"

# Dockerfile directory location
: "${DOCKERFILE_DIR:=dockerfiles}"

# For images that are prebuilt
: "${PREBUILT_CAKEML_IMG:=prebuilt_cakeml}"
: "${PREBUILT_SYSINIT_IMG:=prebuilt_sysinit}"

# Extra vars
DOCKER_BUILD="docker build"
DOCKER_INSPECT="docker inspect"
DOCKER_FLAGS="--force-rm=true"

# By default use host architecture
: "${HOST_ARCH:=$(arch)}"

# Special variables to be passed through Docker to the build scripts
: "${SCM}"


###########################
# For 'prebuilt' images, the idea is that for things that take a long
# time to build, and don't change very much, we should build them
# once, and then pull them in as needed.
# TODO: make this work better..
: "${CAKEML_BASE_DATE:=2019_01_13}"


############################################
# builder functions

build_internal_image()
{
    base_img="$1"
    dfile_name="$2"
    img_name="$3"
    shift 3  # any params left over are just injected into the docker command
             # presumably as flags


    build_args_to_pass_to_docker=$(echo "$build_args" | grep "=" | awk '{print "--build-arg", $1}')
    # shellcheck disable=SC2086
    $DOCKER_BUILD --platform $DOCKER_PLATFORM $DOCKER_FLAGS \
        --build-arg BASE_IMG="$base_img" \
        --build-arg SCM="$SCM" \
        $build_args_to_pass_to_docker \
        -f "$DOCKERFILE_DIR/$dfile_name" \
        -t "$img_name" \
        "$@" \
        .

    echo "Size of $img_name:"
    $DOCKER_INSPECT -f "{{ .Size }}" "$img_name" | xargs printf "%'d\n"
}

build_image()
{
    base_img="$1"
    dfile_name="$2"
    img_name="$3"
    shift 3

    build_internal_image "$DOCKERHUB$base_img" "$dfile_name" "$DOCKERHUB$img_name" "$@"
}

apply_software_to_image()
{
    prebuilt_img="$1"
    builder_dfile="$2"
    orig_img="$3"
    new_img="$4"
    shift 4

    # NOTE: it's OK to supply docker build-args that aren't requested in the Dockerfile
    # shellcheck disable=SC2086
    $DOCKER_BUILD --platform $DOCKER_PLATFORM $DOCKER_FLAGS \
		--build-arg BASE_BUILDER_IMG="$DOCKERHUB$prebuilt_img" \
		--build-arg BASE_IMG="$DOCKERHUB$orig_img" \
        --build-arg SCM="$SCM" \
		-f "$DOCKERFILE_DIR/$builder_dfile" \
		-t "$DOCKERHUB$new_img" \
        "$@" \
		.

    echo "Size of $new_img:"
    $DOCKER_INSPECT -f "{{ .Size }}" "$new_img" | xargs printf "%'d\n"
}
############################################

############################################
# Recipes for standard images

build_sel4()
{
    # Don't need $IMG_POSTFIX here, because:
    # - debian is just debian
    # - basetools doesn't get pushed out, and is built here anyway
    build_internal_image "$DEBIAN_IMG" base_tools.Dockerfile "$BASETOOLS_IMG"
    build_internal_image "$BASETOOLS_IMG" sel4.Dockerfile "$DOCKERHUB$SEL4_IMG"
}

build_camkes()
{
    build_image "$SEL4_IMG$IMG_POSTFIX" camkes.Dockerfile "$CAMKES_IMG"
}

build_l4v()
{
    build_image "$CAMKES_IMG$IMG_POSTFIX" l4v.Dockerfile "$L4V_IMG"
}

############################################
# Build prebuildable images

prebuild_warning()
{
    cat <<EOF
You have asked to build a 'prebuilt' image for $img_to_build.
If you just want to use the $img_to_build compilers, rather
than rebuilt the toolchain itself, use:
    build.sh -b sel4 -s $img_to_build
It will be much faster! Waiting for 10 seconds incase you
change your mind
EOF
    sleep 10
}

build_cakeml()
{
    prebuild_warning >&2
    build_image "$CAMKES_IMG$IMG_POSTFIX" cakeml.Dockerfile "$PREBUILT_CAKEML_IMG"
}

build_sysinit()
{
    prebuild_warning >&2
    build_image "$CAMKES_IMG$IMG_POSTFIX" sysinit.Dockerfile "$PREBUILT_SYSINIT_IMG"
}


############################################
# Argparsing

show_help()
{
    # TODO:
    # - learn best way to represent that -s can be supplied multiple times
    available_software=$(cd "$DOCKERFILE_DIR"; find . -name 'apply-*.Dockerfile' \
                            | sed 's/.Dockerfile//;s@./apply-@@' \
                            | sort \
                            | tr "\n" "|")
    cat <<EOF
    build.sh [-r] [-v] [-p] [-a arch] -b [sel4|camkes|l4v] -s [$available_software] -s ... -e MAKE_CACHES=no -e ...

     -r     Rebuild docker images (don't use the docker cache)
     -v     Verbose mode
     -s     Software packages to install on top of the base image. Use -s for each package.
     -e     Build arguments (NAME=VALUE) to docker build. Use a -e for each build arg.
     -p     Pull base image first. Rather than build the base image,
            get it from the web first
     -a     Supply x86_64 for building Intel images, and arm64 for Arm images.
            Defaults to x86_64 on x86-based hosts and arm64 on ARM64 hosts.

    Sneaky hints:
     - To build 'prebuilt' images, you can run:
           build.sh -b [riscv|cakeml]
       but it will take a while!
     - You can actually run this with '-b sel4-rust', or any other existing image,
       but it will ruin the sorting of the name.
EOF

}

# init cmdline vars to nothing
img_to_build=
software_to_apply=
pull_base_first=

while getopts "h?pvb:rs:e:a:" opt
do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  set -x
        ;;
    b)  img_to_build=$OPTARG
        ;;
    p)  pull_base_first=y
        ;;
    r)  DOCKER_FLAGS="$DOCKER_FLAGS --no-cache"
        ;;
    s)  software_to_apply="$software_to_apply $OPTARG"
        ;;
    e)  build_args="$build_args\n$OPTARG"
        ;;
    a)  HOST_ARCH="$OPTARG"
        ;;
    :)  echo "Option -$opt requires an argument." >&2
        exit 1
        ;;
    esac
done

if [ "$HOST_ARCH" = "x86_64" ] || \
   [ "$HOST_ARCH" = "amd64" ] || \
   [ "$HOST_ARCH" = "i386" ]; then
    DOCKER_PLATFORM="linux/amd64"
elif [ "$HOST_ARCH" = "arm64" ]; then
    DOCKER_PLATFORM="linux/arm64"
else
    echo "Unsupported host architecture: $HOST_ARCH"
    exit 1
fi

echo "Building for $DOCKER_PLATFORM"

if [ -z "$img_to_build" ]
then
    echo "You need to supply a \`-b\`" >&2
    show_help >&2
    exit 1
fi



############################################
# Processing

if [ -z "$pull_base_first" ]
then
    # If we don't want to pull the base image from Dockerhub, build it
    "build_${img_to_build}"
else
    docker pull "$DOCKERHUB$img_to_build$IMG_POSTFIX"
fi

# get a unique, sorted, space seperated list of software to apply.
softwares=$(echo "$software_to_apply" | tr ' ' '\n' | sort -u | tr '\n' ' ')

base_img="$img_to_build"
base_img_postfix="$IMG_POSTFIX"
for s in $softwares
do
    echo "$s to install!"
    if test -f "$DOCKERFILE_DIR/apply-${s}.Dockerfile"; then
        # Try to resolve if we have a prebuilt image for the software being asked for.
        # If not, <shrug />, docker won't pick up the variable anyway, so no harm done.
        prebuilt_img="$(echo "PREBUILT_${s}_IMG" | tr "[:lower:]" "[:upper:]")"
        prebuilt_img="$(eval echo \$"$prebuilt_img")"
        apply_software_to_image "$prebuilt_img" "apply-${s}.Dockerfile" "$base_img$base_img_postfix" "$base_img-$s"
        base_img="$base_img-$s"
        base_img_postfix="" # only apply the postfix in the first loop
    fi
done



