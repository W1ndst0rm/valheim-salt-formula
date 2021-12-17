# FORMULANAME=$(shell grep name: metadata.yml|head -1|cut -d : -f 2|grep -Eo '[a-z0-9\-\_]*')
# VERSION=$(shell grep version: metadata.yml|head -1|cut -d : -f 2|grep -Eo '[a-z0-9\.\-\_]*')
# VERSION_MAJOR := $(shell echo $(VERSION)|cut -d . -f 1-2)
# VERSION_MINOR := $(shell echo $(VERSION)|cut -d . -f 3)

# NEW_MAJOR_VERSION ?= $(shell date +%Y.%m|sed 's,\.0,\.,g')
# NEW_MINOR_VERSION ?= $(shell /bin/bash -c 'echo $$[ $(VERSION_MINOR) + 1 ]')

MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))

ifneq ($(subst -j,,$(JOB_FLAG)),)
JOBS := $(subst -j,,$(JOB_FLAG))
else
JOBS := 1
endif

all:
	@echo "make lint    - Run lint tests"
	@echo "make test-local    - Run test using docker locally"

lint:
	salt-lint valheim/

install-salt:
	[ ! -d test ] || (cd test; docker compose exec  --privileged masterless sh /srv/utils/install-salt.sh)

launch-dev-cluster:
	[ ! -d test ] || (cd test; docker compose up -d)

test-dev-cluster:
	@echo "Test dev Cluster"
	[ ! -d test ] || (cd test; docker compose exec  --privileged masterless salt-call --local state.apply valheim -l debug)

test-show-sls-dev-cluster:
	@echo "Test dev Cluster"
	[ ! -d test ] || (cd test; docker compose exec  --privileged masterless salt-call --local state.show_sls valheim)

render-sls:
	salt-call --local state.show_sls valheim

salt-check:
	@echo "Test dev Cluster"
	[ ! -d test ] || (cd test; docker compose exec  --privileged masterless salt-call --local test.ping -l debug)

destroy-dev-cluster:
	@echo "Destory dev Cluster"
	[ ! -d test ] || (cd test; docker compose down)

test-local: launch-dev-cluster install-salt test-dev-cluster test-show-sls-dev-cluster destroy-dev-cluster
