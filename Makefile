DOCKERHUB ?= trustworthysystems/
BASE_IMG ?= base_tools
SEL4_IMG ?= sel4
RISCV_IMG ?= sel4-riscv
CAMKES_IMG ?= camkes
RUST_IMG ?= sel4-rust
L4V_IMG ?= l4v
SEL4_TST_IMG ?= sel4_test
CAMKES_TST_IMG ?= camkes_test
L4V_TST_IMG ?= l4v_test
EXTRAS_IMG := extras
USER_IMG := user_img
USER_BASE_IMG := $(SEL4_IMG)
HOST_DIR ?= $(shell pwd)

DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true
INTERNAL ?= no


################################################
# Build dependencies for sel4/camkes/l4v
#################################################
.PHONY: base_tools rebuild_base_tools
base_tools:
	docker pull debian:stretch
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg INTERNAL=$(INTERNAL) \
		-f base_tools.dockerfile \
		-t $(BASE_IMG) \
		.
rebuild_base_tools: DOCKER_FLAGS += --no-cache
rebuild_base_tools: base_tools

.PHONY: sel4 rebuild_sel4
sel4: base_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(BASE_IMG) \
		-f sel4.dockerfile \
		-t $(DOCKERHUB)$(SEL4_IMG) \
		.
rebuild_sel4: DOCKER_FLAGS += --no-cache
rebuild_sel4: sel4

.PHONY: sel4-riscv rebuild_sel4-riscv
sel4-riscv:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg SEL4_IMG=$(SEL4_IMG) \
		-f sel4-riscv.dockerfile \
		-t $(DOCKERHUB)$(RISCV_IMG) \
		.
rebuild_sel4-riscv: DOCKER_FLAGS += --no-cache
rebuild_sel4-riscv: sel4-riscv

.PHONY: camkes rebuild_camkes
camkes: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg SEL4_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f camkes.dockerfile \
		-t $(DOCKERHUB)$(CAMKES_IMG) \
		.
rebuild_camkes: DOCKER_FLAGS += --no-cache
rebuild_camkes: camkes

.PHONY: camkes-rust rebuild_camkes-rust
camkes-rust: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg CAMKES_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f rust.dockerfile \
		-t $(DOCKERHUB)$(RUST_IMG) \
		.
rebuild_camkes-rust: DOCKER_FLAGS += --no-cache
rebuild_camkes-rust: camkes-rust

.PHONY: l4v rebuild_l4v
l4v: camkes camkes-rust
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg CAMKES_IMG=$(DOCKERHUB)$(RUST_IMG) \
		-f l4v.dockerfile \
		-t $(DOCKERHUB)$(L4V_IMG) \
		.
rebuild_l4v: DOCKER_FLAGS += --no-cache
rebuild_l4v: l4v
		#--build-arg CAMKES_IMG=$(DOCKERHUB)$(CAMKES_IMG) 

.PHONY: all
all: base_tools sel4 sel4-riscv camkes camkes-rust l4v

.PHONY: rebuild_all
rebuild_all: rebuild_base_tools rebuild_sel4 rebuild_sel4-riscv rebuild_camkes rebuild_camkes-rust rebuild_l4v


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
		--build-arg SEL4_IMG=$(DOCKERHUB)$(SEL4_IMG) \
		-f sel4_tests.dockerfile \
		-t $(SEL4_TST_IMG) \
		.
retest_sel4: DOCKER_FLAGS += --no-cache
retest_sel4: test_sel4

.PHONY: test_camkes
test_camkes: 
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg CAMKES_IMG=$(DOCKERHUB)$(CAMKES_IMG) \
		-f camkes_tests.dockerfile \
		-t $(CAMKES_TST_IMG) \
		.
retest_camkes: DOCKER_FLAGS += --no-cache
retest_camkes: test_camkes

.PHONY: test_l4v
test_l4v:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg L4V_IMG=$(DOCKERHUB)$(L4V_IMG) \
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

.PHONY: pull_camkes_image
pull_camkes_image:
	docker pull $(DOCKERHUB)$(CAMKES_IMG)

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

.PHONY: user_camkes
user_camkes: build_user_camkes user_run

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
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=$(DISPLAY) \
		$(USER_IMG)-$(shell id -u) bash


.PHONY: build_user
build_user:
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
build_user_camkes: USER_BASE_IMG = $(CAMKES_IMG)
build_user_camkes: build_user
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

.PHONY: clean
clean: clean_data clean_images
