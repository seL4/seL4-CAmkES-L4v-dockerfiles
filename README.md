<!--
     Copyright 2024, Proofcraft Pty Ltd
     Copyright 2020, Data61, CSIRO

     SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Docker containers for seL4, CAmkES, and L4v dependencies

## Requirements

* docker (See [here](https://get.docker.com) or [here](https://docs.docker.com/engine/installation) for instructions)
* make

It is recommended you add yourself to the docker group, so you can run docker commands without using sudo.

## Quick start

To get a running build environment for seL4 and CAmkES, run:

    git clone https://github.com/seL4/seL4-CAmkES-L4v-dockerfiles.git
    cd seL4-CAmkES-L4v-dockerfiles
    make user

Or to map a particular directory to the /host dir in the container:

    make user HOST_DIR=/scratch/sel4_stuff  # as an example


## What is this?

This repository contains docker files which map out the dependencies for seL4, CAmkES, and L4v. It also contains some infrastructure to allow people to use the containers in a useful way.

These docker files are used as the basis for regression testing in the seL4 Foundation, and hence should represent a well tested and up to date environment


## To run

Get the repository of docker files by cloning them from GitHub:

    git clone https://github.com/seL4/seL4-CAmkES-L4v-dockerfiles.git
    cd seL4-CAmkES-L4v-dockerfiles

To get an environment within the container, run:

    make user

which will give you a terminal with CAmkES dependencies built. You can be more specific with:

    make user_sel4
    make user_camkes  # alias for 'make user'
    make user_l4v

The container will map the current working directory from the host to /host within the container. You should be able to read and write files, as the container copies your username and UID.

If you want to map a different folder, you can specify it on the command line:

    make user_sel4 HOST_DIR=/scratch/sel4_stuff

You can also specify commands to be executed inside the container by using `EXEC`:

    make user EXEC="bash -c 'echo hello world'"

The images will be pulled from DockerHub if your machine does not have them.

Alternately, you can define a bash function in your `bashrc`, such as this:

    function container() {
        if [[ $# > 0 ]]; then
            make -C /<path>/<to>/seL4-CAmkES-L4v-dockerfiles user HOST_DIR=$(pwd) EXEC="bash -c '""$@""'"
        else
            make -C /<path>/<to>/seL4-CAmkES-L4v-dockerfiles user HOST_DIR=$(pwd)
        fi
    }

Where you replace the path to match where you cloned the git repo of the docker files. This then allows you to run:

    container

to start the container interactively in your current directory, or:

    container "echo hello && echo world"

to execute commands in the container in your current directory.

### Example of compiling seL4 test

Start by creating a new workspace on your machine:

    mkdir ~/sel4test

Start up the container:

    make user HOST_DIR=~/sel4test
    # in-container terminal
    jblogs@in-container:/host$

Get seL4 test:

    jblogs@in-container:/host$ repo init -u https://github.com/seL4/sel4test-manifest.git
    jblogs@in-container:/host$ repo sync
    jblogs@in-container:/host$ ls
    apps configs Kbuild Kconfig kernel libs Makefile projects tools

Compile and simulate seL4 test for x86-64:

    jblogs@in-container:/host$ mkdir build-x86
    jblogs@in-container:/host$ cd build-x86
    jblogs@in-container:/host$ ../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE
    jblogs@in-container:/host$ ninja
    # ... time passes...
    jblogs@in-container:/host$ ./simulate
    ...
    Test VSPACE0002 passed

        </testcase>

        <testcase classname="sel4test" name="Test all tests ran">

        </testcase>

    </testsuite>

    All is well in the universe

## Adding dependencies

The images and docker files for seL4/CAmkES/L4v only specify enough dependencies to pass the tests in the \*tests.docker file. The `extras.dockerfile` acts as a shim between the DockerHub images and the `user.dockerfile`.

Adding dependencies into the `extras.dockerfile` will build them the next time you run `make user`, and then be cached from then on.

## To build the local Docker files

To build the Docker files locally, you will need to use the included `build.sh` script. It has a help menu:

    ./build.sh -h
        build.sh [-r] -b [sel4|camkes|l4v] -s [binary_decomp|cakeml|camkes_vis|riscv|rust|sysinit] -s ... -e MAKE_CACHES=no -e ...

         -r     Rebuild docker images (don't use the docker cache)
         -v     Verbose mode
         -s     Strict mode
         -e     Build arguments (NAME=VALUE) to docker build. Use a -e for each build arg.
         -p     Pull base image first. Rather than build the base image,
                get it from the web first
         -a     Supply x86_64 for building Intel images, and arm64 for Arm images.
                Defaults to x86_64 on x86-based hosts and arm64 on ARM64 hosts.

### Example builds

To build the seL4 image, run:

    ./build.sh -b sel4

Note that the `-b` flag stands for the `base image`. There are 3 base images: `sel4`, `camkes`, and `l4v`. Each base image includes the previous one, i.e.: the `camkes` image has everything the `sel4` image has, plus the camkes dependencies.

To add additional software to the image, you can use the `-s` flag, to add `software`. For example:

    ./build.sh -b camkes -s cakeml  # This adds the CakeML compiler

    ./build.sh -b sel4 -s cakeml -s rust  # This adds the CakeML compiler and Rust compiler

You can also pass configuration variables through to docker (in docker terms, these are `BUILD_ARGS`) by using the `-e` flag. For example, you can turn off priming the build caches:

    ./build.sh -b sel4 -e MAKE_CACHES=no

To speed things up, you can ask to pull the base image from DockerHub first with the `-p` flag:

    # This adds the CakeML compiler and pulls camkes from DockerHub
    ./build.sh -p -b camkes -s cakeml

## Security

Running Docker on your machine has its own security risks which you should be aware of. Be sure to read the Docker documentation.

Of particular note in this case, your UID and GID are being baked into an image. Any other user on the host who is part of the docker group could spawn a separate container of this image, and hence have read and write access to your files. Of course, if they are part of the docker group, they could do this anyway, but it just makes it a bit easier.

Use at your own risk.

## Released images on DockerHub

The seL4 CI pushes "known working" images to DockerHub under the [`trustworthysystems/` DockerHub
organisation][1], usually once a week. Each time an image is pushed out, it is tagged with a
`YYYY_MM_DD` formatted date. Images with the `:latest` tag are the ones currently in use in the seL4
CI system.

[1]: https://hub.docker.com/u/trustworthysystems

## Troubleshooting Docker "no space left on device"

If you are building the docker images in this repository and are seeing error
messages such as `no space left on device`, especially on MacOS, these are the
things you can do:

* On MacOS, the default overall disk space allocated to Docker is relatively
  small and it needs to fit all images, containers, and volumes. The larger
  CAmkES images are around 14GB in size, and if you have multiple of them the
  numbers add up quickly. Increasing the size of the overall disk allocation to
  somewhere in the vicinity of 128GB is usually enough to fix the problem. To do
  so, in the Docker Desktop app, go to Settings (gear box at the top right in
  version 4.29, for instance), go to Resources, scroll down to find "Virtual
  disk limit", and increase to 128GB or more.

* On Linux, Docker does not have a bound on disk space, but you might find
  overall disk space on the host to be low. You can either free up disk space
  elsewhere on the host, or try to free up Docker resources.

* Freeing up unused Docker resources (Linux and MacOS). The following steps free
  up space in increasing order of aggressiveness. If you just want to free all
  of it, skip to the last step.

      # free up all dangling images and all stopped containers
      docker system prune

  This is relatively safe in that it won't remove images you might still want to
  use. You can list current docker images using the command `docker image ls`
  and remove specific ones with `docker image rm <image>`. To remove all images
  not attached to a currently running container, you can

      # remove all images
      docker image prune -a

  The wipe-all option to remove everything that is not currently in use by a
  running container is:

      # remove everything not currently in use
      docker system prune -a
      docker volume prune -a
