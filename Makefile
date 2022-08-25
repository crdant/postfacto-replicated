PROJECT_DIR    := $(shell pwd)
PROJECT_PARAMS := secrets/params.yaml
CHANNEL        := $(shell yq .replicated.channel $(PROJECT_PARAMS))

MANIFEST_DIR := $(PROJECT_DIR)/manifests
MANIFESTS    := $(shell find $(MANIFEST_DIR) -name '*.yaml' -o -name '*.tgz')
BUILD_DIR    := build

TEAM        := $(shell yq .team $(PROJECT_PARAMS))
PIPELINE    := $(shell basename $(PROJECT_DIR))
REPOSITORY  := $(shell git remote get-url origin | sed -Ene's_git@(github.com):([^/]*)_https://\1/\2_p')

CI_DIR   := $(PROJECT_DIR)/ci
BRANCH   := $(shell git branch --show-current)
PRE      := SNAPSHOT

.PHONY: secrets
secrets: $(PROJECT_PARAMS)
	@vault kv put concourse/$(TEAM)/$(PIPELINE)/minio \
		fqdn=$(shell yq .minio.fqdn $(PROJECT_PARAMS)) \
		access_key_id=$(shell yq .minio.access-key $(PROJECT_PARAMS)) \
		secret_access_key=$(shell yq .minio.secret-key $(PROJECT_PARAMS)) \
	@vault kv put concourse/$(TEAM)/$(PIPELINE)/replicated \
		api-token=$(shell yq .replicated.api-token $(PROJECT_PARAMS))

.PHONY: pipeline
pipeline: secrets
	@fly --target $(TEAM) set-pipeline --pipeline $(PIPELINE) --config $(CI_DIR)/pipeline/pipeline.yaml \
			--var repository=$(REPOSITORY) --var branch=$(BRANCH) --var channel=$(CHANNEL) \
			--var bump=$(BUMP) --var pre=$(PRE)
	@fly --target $(TEAM) unpause-pipeline --pipeline $(PIPELINE)

lint: $(MANIFESTS)
	@replicated release lint --yaml-dir $(MANIFEST_DIR)

release: $(MANIFESTS)
	@replicated release create \
		--app ${REPLICATED_APP} \
		--token ${REPLICATED_API_TOKEN} \
		--auto -y \
		--yaml-dir $(MANIFEST_DIR) \
		--promote $(CHANNEL)

install:
	@kubectl kots install ${REPLICATED_APP}

encrypt:
	@gpg --armor --encrypt --sign --output secrets/params.yaml.enc secrets/params.yaml

decrypt:
	@gpg --decrypt secrets/params.yaml.enc > secrets/params.yaml
