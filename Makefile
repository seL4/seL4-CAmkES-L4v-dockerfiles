
base_img := base_tools
sel4_img := selfour
camk_img := camkes
veri_img := verification
sel4_tst_img := selfour_test

DOCKER_FLAGS = --force-rm=true

.PHONY: all
all: build_external_deps 

.PHONY: build_external_deps rebuild_external_deps
build_external_deps:
	# Get extremely basic tools (e.g. wget)
	docker build $(DOCKER_FLAGS) -f base_tools.dockerfile -t $(base_img) .
	# Build sel4 deps
	docker build $(DOCKER_FLAGS) -f sel4.dockerfile -t $(sel4_img) .
	# Build camkes deps
	docker build $(DOCKER_FLAGS) -f camkes.dockerfile -t $(camk_img) .
	# Build l4v deps
	docker build $(DOCKER_FLAGS) -f l4v.dockerfile -t $(veri_img) .
rebuild_external_deps: export DOCKER_FLAGS += --no-cache
rebuild_external_deps: build_external_deps


.PHONY: run_tests
run_tests:
	docker build $(DOCKER_FLAGS) -f sel4_tests.dockerfile -t $(sel4_tst_img) .
