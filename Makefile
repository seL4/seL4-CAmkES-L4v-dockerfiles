
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
PREBUILT_RISCV_IMG ?= prebuilt_riscv_compilers
BINARY_DECOMP_IMG ?= binary_decomp

# Test images 
SEL4_TST_IMG ?= sel4_test
CAMKES_TST_IMG ?= camkes_test
L4V_TST_IMG ?= l4v_test

# Interactive images
EXTRAS_IMG := extras
USER_IMG := user_img
USER_BASE_IMG := $(SEL4_IMG)
HOST_DIR ?= $(shell pwd)

# Extra vars
DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true
INTERNAL ?= no

USE_PREBUILT_RISCV ?= yes
RISCV_BASE_DATE ?= 2018_06_04

#################################################
# Build dependencies for core images
#################################################
.PHONY: base_tools rebuild_base_tools
base_tools:
	docker pull $(DEBIAN_IMG)
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DEBIAN_IMG) \
		--build-arg INTERNAL=$(INTERNAL) \
		-f base_tools.dockerfile \
		-t $(BASETOOLS_IMG) \
		.
rebuild_base_tools: DOCKER_FLAGS += --no-cache
rebuild_base_tools: base_tools

.PHONY: sel4 rebuild_sel4
sel4: base_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(BASETOOLS_IMG) \
		-f sel4.dockerfile \
		-t $(DOCKERHUB)$(SEL4_IMG) \
		.
rebuild_sel4: DOCKER_FLAGS += --no-cache
rebuild_sel4: sel4

.PHONY: camkes rebuild_camkes
camkes: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f camkes.dockerfile \
		-t $(DOCKERHUB)$(CAMKES_IMG) \
		.
rebuild_camkes: DOCKER_FLAGS += --no-cache
rebuild_camkes: camkes

.PHONY: l4v rebuild_l4v
l4v: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f l4v.dockerfile \
		-t $(DOCKERHUB)$(L4V_IMG) \
		.
rebuild_l4v: DOCKER_FLAGS += --no-cache
rebuild_l4v: l4v

############################################
## RISC-V
###########################################
.PHONY: sel4-riscv rebuild_sel4-riscv
ifneq ($(USE_PREBUILT_RISCV),yes)
	RISCV_BASE_DATE := latest
endif
riscv: sel4
	echo $(RISCV_BASE_DATE)
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(SEL4_IMG):$(RISCV_BASE_DATE) \
		-f riscv.dockerfile \
		-t $(DOCKERHUB)$(PREBUILT_RISCV_IMG) \
		.

sel4-riscv: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_BUILDER_IMG=$(DOCKERHUB)$(PREBUILT_RISCV_IMG) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f apply-riscv.dockerfile \
		-t $(DOCKERHUB)$(SEL4_RISCV_IMG) \
		.
rebuild_sel4-riscv: DOCKER_FLAGS += --no-cache
rebuild_sel4-riscv: sel4-riscv

.PHONY: camkes-riscv rebuild_camkes-riscv
camkes-riscv: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_BUILDER_IMG=$(DOCKERHUB)$(PREBUILT_RISCV_IMG) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f apply-riscv.dockerfile \
		-t $(DOCKERHUB)$(CAMKES_RISCV_IMG) \
		.
rebuild_camkes-riscv: DOCKER_FLAGS += --no-cache
rebuild_camkes-riscv: camkes-riscv

#################################################
## Extra features
#################################################
.PHONY: camkes-rust rebuild_camkes-rust
camkes-rust: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f rust.dockerfile \
		-t $(DOCKERHUB)$(RUST_IMG) \
		.
rebuild_camkes-rust: DOCKER_FLAGS += --no-cache
rebuild_camkes-rust: camkes-rust

.PHONY: camkes-vis rebuild_camkes-vis
camkes-vis: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f camkes-vis.dockerfile \
		-t $(DOCKERHUB)$(CAMKES_VIS_IMG) \
		.
rebuild_camkes-vis: DOCKER_FLAGS += --no-cache
rebuild_camkes-vis: camkes-vis

.PHONY: binary_decomp rebuild_binary_decomp
binary_decomp: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg SEL4_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f binary_decomp.dockerfile \
		-t $(DOCKERHUB)$(BINARY_DECOMP_IMG) \
		.
rebuild_binary_decomp: DOCKER_FLAGS += --no-cache
rebuild_binary_decomp: binary_decomp


##################################################

.PHONY: all
all: base_tools sel4 camkes camkes-rust camkes-vis l4v sel4-riscv camkes-riscv binary_decomp

.PHONY: rebuild_all
rebuild_all: rebuild_base_tools rebuild_sel4 rebuild_sel4-riscv rebuild_camkes rebuild_camkes-riscv rebuild_camkes-rust rebuild_l4v


################################################
# Testing if the dependencies are still working
# for sel4/camkes/l4v
#################################################
.PHONY: run_tests
run_tests: test_sel4 test_camkes #test_lv4  # very expensive to test by default
rerun_tests: DOCKER_FLAGS += --no-cache
rerun_tests: run_tests

.PHONY: test_sel4
test_sel4:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f sel4_tests.dockerfile \
		-t $(SEL4_TST_IMG) \
		.
retest_sel4: DOCKER_FLAGS += --no-cache
retest_sel4: test_sel4

.PHONY: test_camkes
test_camkes:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f camkes_tests.dockerfile \
		-t $(CAMKES_TST_IMG) \
		.
retest_camkes: DOCKER_FLAGS += --no-cache
retest_camkes: test_camkes

.PHONY: test_l4v
test_l4v:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(DOCKERHUB)$(L4V_IMG) \
		-f l4v_tests.dockerfile \
		-t $(L4V_TST_IMG) \
		.
	docker run -it --rm -v verification_cache:/tmp/cache $(DOCKERHUB)$(L4V_TST_IMG)  # run as container for caching
retest_l4v: DOCKER_FLAGS += --no-cache
retest_l4v: test_l4v


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
		-it \
		--hostname in-container \
		--rm \
		-u $(shell whoami) \
		-v $(HOST_DIR):/host \
		-v $(shell whoami)-home:/home/$(shell whoami) \
		-v /etc/localtime:/etc/localtime:ro \
		$(USER_IMG)-$(shell id -u) bash

.PHONY: user_run_l4v
user_run_l4v:
	docker run \
		-it \
		--hostname in-container \
		--rm \
		-u $(shell whoami) \
		-v $(HOST_DIR):/host \
		-v $(shell whoami)-home:/home/$(shell whoami) \
		-v $(shell whoami)-isabelle:/isabelle \
		-v /etc/localtime:/etc/localtime:ro \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=$(DISPLAY) \
		$(USER_IMG)-$(shell id -u) bash


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
		if [ $$(( ( $$(date +%s) - $$(date --date=$$(docker inspect --format='{{.Created}}' $${img}) +%s) ) / (60*60*24) )) -gt 30 ]; then \
			echo "The docker image: $$(docker inspect --format='{{(index .RepoTags 0)}}' $${img}) is getting a bit old (more than 30 days). You should consider updating it."; \
			sleep 2; \
		fi; \
	done;


.PHONY: build_user
build_user: run_checks
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=USER_BASE_IMG=$(DOCKERHUB)$(USER_BASE_IMG) \
		-f extras.dockerfile \
		-t $(EXTRAS_IMG) \
		.
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=EXTRAS_IMG=$(EXTRAS_IMG) \
		--build-arg=UNAME=$(shell whoami) \
		--build-arg=UID=$(shell id -u) \
		-f user.dockerfile \
		-t $(USER_IMG)-$(shell id -u) .
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

.PHONY: clean_isabelle
clean_isabelle:
	docker volume rm $(shell whoami)-isabelle

.PHONY: clean_home_dir
clean_home_dir:
	docker volume rm $(shell whoami)-home

.PHONY: clean_data
clean_data: clean_isabelle clean_home_dir

.PHONY: clean_images
clean_images:
	-docker rmi $(USER_IMG)-$(shell id -u)
	-docker rmi extras
	-docker rmi $(DOCKERHUB)$(L4V_IMG)
	-docker rmi $(DOCKERHUB)$(CAMKES_IMG)
	-docker rmi $(DOCKERHUB)$(SEL4_IMG)
	-docker rmi $(DOCKERHUB)$(SEL4_RISCV_IMG)
	-docker rmi $(DOCKERHUB)$(CAMKES_RISCV_IMG)

.PHONY: clean
clean: clean_data clean_images
