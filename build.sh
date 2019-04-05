#!/bin/sh

set -efu

############################################
# env setup

: "${DOCKERHUB:=trustworthysystems/}"

# Base images
: "${DEBIAN_IMG:=debian:buster}"
: "${BASETOOLS_IMG:=base_tools}"

# Core images
: "${SEL4_IMG:=sel4}"
: "${CAMKES_IMG:=camkes}"
: "${L4V_IMG:=l4v}"


# For images that are prebuilt
: "${PREBUILT_RISCV_IMG:=prebuilt_riscv_compilers}"
: "${PREBUILT_CAKEML_IMG:=prebuilt_cakeml}"

# Extra vars
DOCKER_BUILD="docker build"
DOCKER_FLAGS="--force-rm=true"
INTERNAL="no"


###########################
# For 'prebuilt' images, the idea is that for things that take a long
# time to build, and don't change very much, we should build them 
# once, and then pull them in as needed.
# TODO: make this work better..
: "${USE_PREBUILT_RISCV:=yes}"
: "${RISCV_BASE_DATE:=2018_06_04}"
: "${USE_CAKEML_RISCV:=yes}"
: "${CAKEML_BASE_DATE:=2019_01_13}"


############################################
# builder functions

build_internal_image()
{
    base_img="$1"
    dfile_name="$2"
    img_name="$3"
    shift 3;
    other_flags=$@

    $DOCKER_BUILD $DOCKER_FLAGS \
        --build-arg base_img="${base_img}" \
        ${other_flags} \
        -f "${dfile_name}" \
        -t "${img_name}" \
        .
}

build_image()
{
    base_img="$1"
    dfile_name="$2"
    img_name="$3"
    shift 3;
    other_flags=$@

    build_internal_image "${DOCKERHUB}${base_img}" "${dfile_name}" "${DOCKERHUB}${img_name}" $other_flags
}

apply_software_to_image()
{
    prebuilt_img="$1"
    builder_dfile="$2"
    orig_img="$3"
    new_img="$4"
    shift 4;
    other_flags=$@

    # NOTE: it's OK to supply docker build-args that aren't requested in the Dockerfile

    $DOCKER_BUILD $DOCKER_FLAGS \
		--build-arg BASE_BUILDER_IMG="${DOCKERHUB}${prebuilt_img}" \
		--build-arg BASE_IMG="${DOCKERHUB}${orig_img}" \
        ${other_flags} \
		-f "${builder_dfile}" \
		-t "${DOCKERHUB}${new_img}" \
		.
}
############################################

############################################
# Recipes for standard images

build_sel4()
{
    build_internal_image "$DEBIAN_IMG" base_tools.dockerfile "$BASETOOLS_IMG" "--build-arg INTERNAL=${INTERNAL}"
    build_internal_image "$BASETOOLS_IMG" sel4.dockerfile "${DOCKERHUB}${SEL4_IMG}"
}

build_camkes()
{
    build_image ${SEL4_IMG} camkes.dockerfile ${CAMKES_IMG}
}

build_l4v()
{
    build_image ${CAMKES_IMG} l4v.dockerfile ${L4V_IMG}
}

############################################
# Build prebuildable images

prebuild_warning()
{
    echo "You have asked to build a 'prebuilt' image for ${img_to_build}."
    echo "If you just want to use the ${img_to_build} compilers, rather"
    echo "than rebuilt the toolchain itself, use:"
    echo "    build.sh -b sel4 -s ${img_to_build}"
    echo "It will be much faster! Waiting for 10 seconds incase you"
    echo "change your mind"
    sleep 10
}

build_riscv()
{
    prebuild_warning
    build_image ${SEL4_IMG} riscv.dockerfile ${PREBUILT_RISCV_IMG}
}

build_cakeml()
{
    prebuild_warning
    build_image ${CAMKES_IMG} cakeml.dockerfile ${PREBUILT_CAKEML_IMG}
}


############################################
# Argparsing

show_help()
{
    # TODO:
    # - learn how to use sed better
    # - learn best way to represent that -s can be supplied multiple times
    available_software=$(find . -name 'apply-*.dockerfile' \
                            | sed 's/.dockerfile//' \
                            | sed 's/.\/apply-//' \
                            | sort \
                            | tr "\n" "|")
    echo "build.sh [-r] -b [sel4|camkes|l4v] -s [${available_software}] -s ..."
    echo ""
    echo " -r     Rebuild docker images (don't use the docker cache)"
    echo " -v     Verbose mode"
    echo " -s     Strict mode"
    echo ""
    echo "Sneaky hints:"
    echo " - You can actually run this with \`-b sel4-rust\`, or any other existing image,"
    echo "   but it will ruin the sorting of the name."
    echo " - To build 'prebuilt' images, you can run:"
    echo "       build.sh -b [riscv|cakeml] "
    echo "   but it will take a while!"

}

# init cmdline vars to nothing
img_to_build=
software_to_apply=
pull_base_first=

while getopts "h?epvb:rs:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    e)  strict=1
        set -e
        ;;
    v)  verbose=1
        set -x
        ;;
    b)  img_to_build=$OPTARG
        ;;
    p)  pull_base_first=y
        ;;
    r)  DOCKER_FLAGS="${DOCKER_FLAGS} --no-cache"
        ;;
    s)  software_to_apply="$software_to_apply $OPTARG"
        ;;
    :)  echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
done

if test -z "$img_to_build"; then
    echo "You need to supply a \`-b\`" >&2
    show_help
    exit 1
fi



############################################
# Processing

if test -z "$pull_base_first"; then
    # If we don't want to pull the base image from Dockerhub, build it
    "build_${img_to_build}"
else
    docker pull "${DOCKERHUB}${img_to_build}"
fi

# get a unique, sorted, space seperated list of software to apply.
#softwares="$(echo $software_to_apply | sed 's/ /\n/g' | sort | uniq | sed 's/\n/ /g')"
softwares="$(echo $software_to_apply | tr ' ' '\n' | sort | uniq | tr '\n' ' ')"

base_img="$img_to_build"
for s in $softwares; do
    echo $s to install!
    if test -f "apply-${s}.dockerfile"; then
        # Try to resolve if we have a prebuilt image for the software being asked for.
        # If not, <shrug />, docker won't pick up the variable anyway, so no harm done.
        prebuilt_img="$(echo PREBUILT_${s}_IMG | tr [a-z] [A-Z])"
        prebuilt_img="$(eval echo \$$prebuilt_img)"
        apply_software_to_image "${prebuilt_img}" "apply-${s}.dockerfile" "$base_img" "${base_img}-${s}"
        base_img="${base_img}-${s}"
    fi
done



