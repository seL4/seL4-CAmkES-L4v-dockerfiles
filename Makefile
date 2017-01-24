base_img ?= base_tools
sel4_img ?= selfour
camkes_img ?= camkes
l4v_img ?= l4v
sel4_tst_img ?= selfour_test
camkes_tst_img ?= camkes_test
l4v_tst_img ?= l4v_test

DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true

.PHONY: base_tools rebuild_base_tools
base_tools:
	docker pull debian:stretch
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f base_tools.dockerfile -t $(base_img) .
rebuild_base_tools: DOCKER_FLAGS += --no-cache
rebuild_base_tools: base_tools

.PHONY: sel4 rebuild_sel4
sel4: base_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f sel4.dockerfile -t $(sel4_img) .
rebuild_sel4: DOCKER_FLAGS += --no-cache
rebuild_sel4: sel4

.PHONY: camkes rebuild_camkes
camkes: base_tools sel4
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f camkes.dockerfile -t $(camkes_img) .
rebuild_camkes: DOCKER_FLAGS += --no-cache
rebuild_camkes: camkes

.PHONY: l4v rebuild_l4v
l4v: base_tools sel4 camkes
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f l4v.dockerfile -t $(l4v_img) .
rebuild_l4v: DOCKER_FLAGS += --no-cache
rebuild_l4v: l4v


.PHONY: all
all: base_tools sel4 camkes l4v

.PHONY: rebuild_all
rebuild_all: rebuild_base_tools rebuild_sel4 rebuild_camkes rebuild_l4v

.PHONY: run_tests
run_tests:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f sel4_tests.dockerfile -t $(sel4_tst_img) .
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f camkes_tests.dockerfile -t $(camkes_tst_img) .
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f l4v_tests.dockerfile -t $(l4v_tst_img) .
	docker run -t --rm -v /scratch/tmp/verification:/tmp/cache $(l4v_img)  # run as container for caching
rerun_tests: DOCKER_FLAGS += --no-cache
rerun_tests: l4v

.PHONY: test_sel4
test_sel4:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f sel4_tests.dockerfile -t $(sel4_tst_img) .
retest_sel4: DOCKER_FLAGS += --no-cache
retest_sel4: test_sel4

.PHONY: test_camkes
test_camkes:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) -f camkes_tests.dockerfile -t $(camkes_tst_img) .
retest_camkes: DOCKER_FLAGS += --no-cache
retest_camkes: test_camkes
