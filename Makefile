#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Docker-compatible image tool to use (could also be 'podman')
DOCKER ?= docker
DOCKERHUB ?= trustworthysystems/

# Base images
DEBIAN_IMG ?= debian:buster
BASETOOLS_IMG ?= base_tools

# Core images
SEL4_IMG ?= sel4
CAMKES_IMG ?= camkes
L4V_IMG ?= l4v

# Extra feature images
RUST_IMG ?= sel4-rust
CAMKES_VIS_IMG ?= camkes-vis
SEL4_TEX_IMG ?= sel4-tex
CAMKES_TEX_IMG ?= camkes-tex
PREBUILT_CAKEML_IMG ?= prebuilt_cakeml
BINARY_DECOMP_IMG ?= binary_decomp

# Test images
SEL4_TST_IMG ?= sel4_test
CAMKES_TST_IMG ?= camkes_test
L4V_TST_IMG ?= l4v_test

# Interactive images
EXTRAS_IMG := extras
USER_IMG := user_img-$(shell whoami)
USER_BASE_IMG := $(SEL4_IMG)
HOST_DIR ?= $(shell pwd)

# Volumes
DOCKER_VOLUME_HOME ?= $(shell whoami)-home
DOCKER_VOLUME_ISABELLE ?= $(shell whoami)-isabelle

# Extra vars
DOCKER_BUILD ?= $(DOCKER) build
DOCKER_FLAGS ?= --force-rm=true
INTERNAL ?= no
ifndef EXEC
	EXEC := bash
	DOCKER_RUN_FLAGS += -it
endif

ETC_LOCALTIME := $(realpath /etc/localtime)

# Extra arguments to pass to `docker run` if it is or is not `podman` - these
# are constructed in a very verbose way to be obvious about why we want to do
# certain things under regular `docker` vs` podman`
# Note that `docker --version` will not say "podman" if symlinked.
CHECK_DOCKER_IS_PODMAN  := $(DOCKER) --help 2>&1 | grep -q podman
IF_DOCKER_IS_PODMAN     := $(CHECK_DOCKER_IS_PODMAN) && echo
IF_DOCKER_IS_NOT_PODMAN := $(CHECK_DOCKER_IS_PODMAN) || echo
# If we're not `podman` then we'll use the `-u` and `-g` options to set the
# user in the container
EXTRA_DOCKER_IS_NOT_PODMAN_RUN_ARGS := $(shell $(IF_DOCKER_IS_NOT_PODMAN) \
    "-u $(shell id -u):$(shell id -g)" \
)
# If we are `podman` then we'll prefer to use `--userns=keep-id` to set up and
# use the appropriate sub{u,g}id mappings rather than end up using UID 0 in the
# container
EXTRA_DOCKER_IS_PODMAN_RUN_ARGS     := $(shell $(IF_DOCKER_IS_PODMAN) \
    "--userns=keep-id" \
)
# And we'll jam them into one variable to reduce noise in `docker run` lines
EXTRA_DOCKER_RUN_ARGS   := $(EXTRA_DOCKER_IS_NOT_PODMAN_RUN_ARGS) \
                           $(EXTRA_DOCKER_IS_PODMAN_RUN_ARGS)

###########################
# For 'prebuilt' images, the idea is that for things that take a long
# time to build, and don't change very much, we should build them
# once, and then pull them in as needed.
USE_CAKEML ?= yes
CAKEML_BASE_DATE ?= 2019_01_13


################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: pull_sel4_image
pull_sel4_image:
	$(DOCKER) pull $(DOCKERHUB)$(SEL4_IMG)

.PHONY: pull_sel4-tex_image
pull_sel4-tex_image:
	$(DOCKER) pull $(DOCKERHUB)$(SEL4_TEX_IMG)

.PHONY: pull_camkes_image
pull_camkes_image:
	$(DOCKER) pull $(DOCKERHUB)$(CAMKES_IMG)

.PHONY: pull_camkes-tex_image
pull_camkes_image-tex:
	$(DOCKER) pull $(DOCKERHUB)$(CAMKES_TEX_IMG)

.PHONY: pull_l4v_image
pull_l4v_image:
	$(DOCKER) pull $(DOCKERHUB)$(L4V_IMG)

.PHONY: pull_images_from_dockerhub
pull_images_from_dockerhub: pull_sel4_image pull_camkes_image pull_l4v_image


################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: user
user: user_camkes  # use CAmkES as the default

.PHONY: user_sel4
user_sel4: build_user_sel4 user_run

.PHONY: user_sel4-tex
user_sel4-tex: build_user_sel4-tex user_run

.PHONY: user_camkes
user_camkes: EXTRA_DOCKER_RUN_ARGS +=  --group-add stack
user_camkes: build_user_camkes user_run

.PHONY: user_camkes-tex
user_camkes-tex: EXTRA_DOCKER_RUN_ARGS +=  --group-add stack
user_camkes-tex: build_user_camkes-tex user_run

.PHONY: user_l4v
user_l4v: EXTRA_DOCKER_RUN_ARGS +=  --group-add stack
user_l4v: build_user_l4v user_run_l4v

.PHONY: user_run
user_run:
	$(DOCKER) run \
		$(DOCKER_RUN_FLAGS) \
		--hostname in-container \
		--rm \
		$(EXTRA_DOCKER_RUN_ARGS) \
		--group-add sudo \
		-v $(HOST_DIR):/host:z \
		-v $(DOCKER_VOLUME_HOME):/home/$(shell whoami) \
		-v $(ETC_LOCALTIME):/etc/localtime:ro \
		$(USER_IMG) $(EXEC)

.PHONY: user_run_l4v
user_run_l4v:
	$(DOCKER) run \
		$(DOCKER_RUN_FLAGS) \
		--hostname in-container \
		--rm \
		$(EXTRA_DOCKER_RUN_ARGS) \
		-v $(HOST_DIR):/host:z \
		-v $(DOCKER_VOLUME_HOME):/home/$(shell whoami) \
		-v $(DOCKER_VOLUME_ISABELLE):/isabelle \
		--group-add sudo \
		-v $(ETC_LOCALTIME):/etc/localtime:ro \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=$(DISPLAY) \
		$(USER_IMG) $(EXEC)


.PHONY: run_checks
run_checks:
ifeq ($(shell id -u),0)
	@echo "You are running this as root (either via sudo, or directly)."
	@echo "This system is designed to run under your own user account."
	@echo "You can add yourself to the docker group to make this work:"
	@echo "    sudo su -c usermod -aG docker your_username"
	@exit 1
endif

	scripts/utils/check_for_old_docker_imgs.sh


.PHONY: build_user
build_user: run_checks
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=USER_BASE_IMG=$(DOCKERHUB)$(USER_BASE_IMG) \
		-f dockerfiles/extras.Dockerfile \
		-t $(EXTRAS_IMG) \
		.
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=EXTRAS_IMG=$(EXTRAS_IMG) \
		--build-arg=UNAME=$(shell whoami) \
		--build-arg=UID=$(shell id -u) \
		--build-arg=GID=$(shell id -g) \
		--build-arg=GROUP=$(shell id -gn) \
		-f dockerfiles/user.Dockerfile \
		-t $(USER_IMG) .
build_user_sel4: USER_BASE_IMG = $(SEL4_IMG)
build_user_sel4: build_user
build_user_sel4-tex: USER_BASE_IMG = $(SEL4_TEX_IMG)
build_user_sel4-tex: build_user
build_user_camkes: USER_BASE_IMG = $(CAMKES_IMG)
build_user_camkes: build_user
build_user_camkes-tex: USER_BASE_IMG = $(CAMKES_TEX_IMG)
build_user_camkes-tex: build_user
build_user_l4v: USER_BASE_IMG = $(L4V_IMG)
build_user_l4v: build_user

.PHONY: clean_isabelle
clean_isabelle:
	$(DOCKER) volume rm $(DOCKER_VOLUME_ISABELLE)

.PHONY: clean_home_dir
clean_home_dir:
	$(DOCKER) volume rm $(DOCKER_VOLUME_HOME)

.PHONY: clean_data
clean_data: clean_isabelle clean_home_dir

.PHONY: clean_images
clean_images:
	-$(DOCKER) rmi $(USER_IMG)
	-$(DOCKER) rmi extras
	-$(DOCKER) rmi $(DOCKERHUB)$(L4V_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(CAMKES_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(SEL4_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(SEL4_TEX_IMG)
	-$(DOCKER) rmi $(DOCKERHUB)$(CAMKES_TEX_IMG)

.PHONY: clean
clean: clean_data clean_images
