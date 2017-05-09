base_img ?= base_tools
sel4_img ?= sel4
camkes_img ?= camkes
l4v_img ?= l4v
sel4_tst_img ?= sel4_test
camkes_tst_img ?= camkes_test
l4v_tst_img ?= l4v_test
extras_img := extras
user_img := user_img
user_base_img := $(sel4_img)
dockerhub_prefix := trustworthysystems/
HOST_DIR ?= $(shell pwd)

DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true


################################################
# Build dependencies for sel4/camkes/l4v
#################################################
.PHONY: base_tools rebuild_base_tools
base_tools:
	docker pull debian:stretch
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f base_tools.dockerfile -t $(base_img) .
rebuild_base_tools: DOCKER_FLAGS += --no-cache
rebuild_base_tools: base_tools

.PHONY: sel4 rebuild_sel4
sel4: base_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f sel4.dockerfile -t $(dockerhub_prefix)$(sel4_img) .
rebuild_sel4: DOCKER_FLAGS += --no-cache
rebuild_sel4: sel4

.PHONY: camkes rebuild_camkes
camkes: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f camkes.dockerfile -t $(dockerhub_prefix)$(camkes_img) .
rebuild_camkes: DOCKER_FLAGS += --no-cache
rebuild_camkes: camkes

.PHONY: l4v rebuild_l4v
l4v: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f l4v.dockerfile -t $(dockerhub_prefix)$(l4v_img) .
rebuild_l4v: DOCKER_FLAGS += --no-cache
rebuild_l4v: l4v

.PHONY: all
all: base_tools sel4 camkes l4v

.PHONY: rebuild_all
rebuild_all: rebuild_base_tools rebuild_sel4 rebuild_camkes rebuild_l4v


################################################
# Testing if the dependencies are still working
# for sel4/camkes/l4v
#################################################
.PHONY: run_tests
run_tests: test_sel4 test_camkes #test_lv4  # very expensive to test by default
rerun_tests: DOCKER_FLAGS += --no-cache
rerun_tests: run_tests

.PHONY: test_sel4
test_sel4: sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f sel4_tests.dockerfile -t $(sel4_tst_img) .
retest_sel4: DOCKER_FLAGS += --no-cache
retest_sel4: test_sel4

.PHONY: test_camkes
test_camkes: camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f camkes_tests.dockerfile -t $(camkes_tst_img) .
retest_camkes: DOCKER_FLAGS += --no-cache
retest_camkes: test_camkes

.PHONY: test_l4v
test_l4v: l4v
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f l4v_tests.dockerfile -t $(l4v_tst_img) .
	docker run -it --rm -v verification_cache:/tmp/cache $(l4v_img)  # run as container for caching
retest_l4v: DOCKER_FLAGS += --no-cache
retest_l4v: test_l4v


################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: pull_sel4_image
pull_sel4_image:
	docker pull trustworthysystems/sel4

.PHONY: pull_camkes_image
pull_camkes_image:
	docker pull trustworthysystems/camkes

.PHONY: pull_l4v_image
pull_l4v_image:
	docker pull trustworthysystems/l4v

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
		$(user_img)-$(shell id -u) bash
	docker rmi $(user_img)-$(shell id -u) 


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
		-e DISPLAY=unix$DISPLAY \
		$(user_img)-$(shell id -u) bash
	docker rmi $(user_img)-$(shell id -u) 


.PHONY: build_user
build_user:
	sed -i -e '/FROM/c\FROM trustworthysystems/$(user_base_img)' extras.dockerfile
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f extras.dockerfile -t $(extras_img) .
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=UNAME=$(shell whoami) \
		--build-arg=UID=$(shell id -u) \
		-f user.dockerfile \
		--no-cache \
		-t $(user_img)-$(shell id -u) .
build_user_sel4: user_base_img = $(sel4_img)
build_user_sel4: build_user
build_user_camkes: user_base_img = $(camkes_img)
build_user_camkes: build_user
build_user_l4v: user_base_img = $(l4v_img)
build_user_l4v: build_user
