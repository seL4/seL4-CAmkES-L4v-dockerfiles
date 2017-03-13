# Dockerfiles for seL4, CAmkES, and L4v dependencies

## Requirements:

 * docker (See here for instructions: https://docs.docker.com/engine/installation)
 * make

It is recommended you add yourself to the docker group, so you can run docker commands without using sudo.


## Quick start:
To get a running build environment for sel4 and camkes, run:

    make user

Or to map a particular directory to the /host dir in the container:

    make user HOST_DIR=/scratch/sel4_stuff  # as an example


## What is this?
This repository contains dockerfiles which map out the dependencies for seL4, CAmkES, and L4v. It also contains some infrastructure to allow people to use the containers in a useful way.

These dockerfiles are used as the basis for regression testing in the Trustworthy Systems group, and hence should represent a well tested and up to date environment


## To run:
To get an environment within the container, run:

    make user

which will give you a terminal with CAmkES dependencies built. You can be more specific with:

    make user_sel4
    make user_camkes  # alias for 'make user'
    make user_l4v

The container will map the current working directory from the host to /host within the container. You should be able to read and write files, as the container copies your username and UID.

If you want to map a different folder, you can specify it on the command line:

    make user_sel4 HOST_DIR=/scratch/sel4_stuff

The images will be pulled from DockerHub if your machine does not have them.


## Adding dependencies
The images and dockerfiles for seL4/CAmkES/L4v only specify enough dependencies to pass the tests in the \*tests.dockerfile. The `extras.dockerfile` acts as a shim between the DockerHub images and the `user.dockerfile`. 

Adding dependencies into the `extras.dockerfile` will build them the next time you run `make user`, and then be cached from then on.


## To build the local dockerfiles:
To build the local dockerfiles into images, run:

    make all

To build a specific image, specify it with make:

    make sel4
    make camkes
    make l4v

Please note that building images locally does not currently work with the `make user` commands, which all use the DockerHub images.


## Security
Running Docker on your machine has its own security risks which you should be aware of. Be sure to read the Docker documentation.

Of particular note in this case, your UID and GID are being baked into an image that exists for the lifetime of your session. Any other user on the host who is part of the docker group could spawn a separate container of this image, and hence have read and write access to your files.

Use at your own risk.

## All (useful) commands

### Starting a container from DockerHub
    user             # Alias for user_camkes
    user_sel4        # Start a container with seL4 dependencies
    user_camkes      # Start a container with seL4 + CAmkES dependencies
    user_l4v         # Start a container with seL4 + CAmkES + L4v dependencies

### Getting the images from DockerHub
    pull_sel4_image                # Pull the seL4 image from DockerHub 
    pull_camkes_image              # Pull the CAmkES image from DockerHub 
    pull_l4v_image                 # Pull the L4v image from DockerHub 
    pull_images_from_dockerhub     # Pull all the above images from DockerHub 

### Building the local Dockerfiles
Please note that building images locally does not currently work with the `make user` commands, which all use the DockerHub images.

    base_tools                  
    sel4                        
    camkes                      
    l4v                         
    all
    
    rebuild_base_tools          
    rebuild_sel4                
    rebuild_camkes              
    rebuild_l4v                 
    rebuild_all                 

### Testing the local Dockerfiles
    test_sel4
    test_camkes                 
    test_l4v
    
    retest_sel4                 
    retest_camkes               
    retest_l4v                  
    
    run_tests                   
    rerun_tests                 
