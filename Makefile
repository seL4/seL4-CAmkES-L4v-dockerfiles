
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
SEL4_RISCV_IMG ?= sel4-riscv
CAMKES_RISCV_IMG ?= camkes-riscv
L4V_RISCV_IMG ?= l4v-riscv
PREBUILT_RISCV_IMG ?= prebuilt_riscv_compilers
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
DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true
INTERNAL ?= no
ifndef EXEC
	EXEC := bash
	DOCKER_RUN_FLAGS += -it
endif

###########################
# For 'prebuilt' images, the idea is that for things that take a long
# time to build, and don't change very much, we should build them 
# once, and then pull them in as needed.
USE_PREBUILT_RISCV ?= yes
RISCV_BASE_DATE ?= 2018_06_04
USE_CAKEML_RISCV ?= yes
CAKEML_BASE_DATE ?= 2019_01_13


################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: pull_sel4_image
pull_sel4_image:
	docker pull $(DOCKERHUB)$(SEL4_IMG)

.PHONY: pull_sel4-riscv_image
pull_sel4-riscv_image:
	docker pull $(DOCKERHUB)$(SEL4_RISCV_IMG)

.PHONY: pull_camkes_image
pull_camkes_image:
	docker pull $(DOCKERHUB)$(CAMKES_IMG)

.PHONY: pull_camkes-riscv_image
pull_camkes_image-riscv:
	docker pull $(DOCKERHUB)$(CAMKES_RISCV_IMG)

.PHONY: pull_l4v_image
pull_l4v_image:
	docker pull $(DOCKERHUB)$(L4V_IMG)

.PHONY: pull_l4v-riscv_image
pull_l4v_image-riscv:
	docker pull $(DOCKERHUB)$(L4V_RISCV_IMG)

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

.PHONY: user_sel4-riscv
user_sel4-riscv: build_user_sel4-riscv user_run

.PHONY: user_camkes
user_camkes: build_user_camkes user_run

.PHONY: user_camkes-riscv
user_camkes-riscv: build_user_camkes-riscv user_run

.PHONY: user_l4v
user_l4v: build_user_l4v user_run_l4v

.PHONY: user_run
user_run:
	docker run \
		$(DOCKER_RUN_FLAGS) \
		--hostname in-container \
		--rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(HOST_DIR):/host:z \
		-v $(DOCKER_VOLUME_HOME):/home/$(shell whoami) \
		-v /etc/localtime:/etc/localtime:ro \
		$(USER_IMG) $(EXEC)

.PHONY: user_run_l4v
user_run_l4v:
	docker run \
		$(DOCKER_RUN_FLAGS) \
		--hostname in-container \
		--rm \
		-u $(shell id -u):$(shell id -g) \
		-v $(HOST_DIR):/host:z \
		-v $(DOCKER_VOLUME_HOME):/home/$(shell whoami) \
		-v $(DOCKER_VOLUME_ISABELLE):/isabelle:exec \
		-v /etc/localtime:/etc/localtime:ro \
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

	# Figure out if any trustworthy systems docker images are potentially too old
	@for img in $(shell docker images --filter=reference='trustworthysystems/*:latest' -q); do \
		if [ $$(( ( $$(date +%s) - $$(date --date=$$(docker inspect --format='{{json .Created}}' $${img} | tr -d '"') +%s) ) / (60*60*24) )) -gt 30 ]; then \
			echo "The docker image: $$(docker inspect --format='{{(index .RepoTags 0)}}' $${img}) is getting a bit old (more than 30 days). You should consider updating it."; \
			sleep 2; \
		fi; \
	done;


.PHONY: build_user
build_user: run_checks
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=USER_BASE_IMG=$(DOCKERHUB)$(USER_BASE_IMG) \
		-f dockerfiles/extras.dockerfile \
		-t $(EXTRAS_IMG) \
		.
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=EXTRAS_IMG=$(EXTRAS_IMG) \
		--build-arg=UNAME=$(shell whoami) \
		--build-arg=UID=$(shell id -u) \
		-f dockerfiles/user.dockerfile \
		-t $(USER_IMG) .
build_user_sel4: USER_BASE_IMG = $(SEL4_IMG)
build_user_sel4: build_user
build_user_sel4-riscv: USER_BASE_IMG = $(SEL4_RISCV_IMG)
build_user_sel4-riscv: build_user
build_user_camkes: USER_BASE_IMG = $(CAMKES_IMG)
build_user_camkes: build_user
build_user_camkes-riscv: USER_BASE_IMG = $(CAMKES_RISCV_IMG)
build_user_camkes-riscv: build_user
build_user_l4v: USER_BASE_IMG = $(L4V_IMG)
build_user_l4v: build_user
build_user_l4v-riscv: USER_BASE_IMG = $(L4V_RISCV_IMG)
build_user_l4v-riscv: build_user

.PHONY: clean_isabelle
clean_isabelle:
	docker volume rm $(DOCKER_VOLUME_ISABELLE)

.PHONY: clean_home_dir
clean_home_dir:
	docker volume rm $(DOCKER_VOLUME_HOME)

.PHONY: clean_data
clean_data: clean_isabelle clean_home_dir

.PHONY: clean_images
clean_images:
	-docker rmi $(USER_IMG)
	-docker rmi extras
	-docker rmi $(DOCKERHUB)$(L4V_IMG)
	-docker rmi $(DOCKERHUB)$(CAMKES_IMG)
	-docker rmi $(DOCKERHUB)$(SEL4_IMG)
	-docker rmi $(DOCKERHUB)$(SEL4_RISCV_IMG)
	-docker rmi $(DOCKERHUB)$(CAMKES_RISCV_IMG)
	-docker rmi $(DOCKERHUB)$(L4V_RISCV_IMG)

.PHONY: clean
clean: clean_data clean_images
