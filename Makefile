CHANNEL=$(shell basename $(shell pwd))

MANIFEST_DIR   := ./manifests
MANIFESTS := $(shell find $(MANIFEST_DIR) -name '*.yaml')

lint: $(MANIFESTS)
	@replicated release lint --yaml-dir $(MANIFEST_DIR)

release: $(MANIFESTS)
	@replicated release create \
		--app ${REPLICATED_APP} \
		--token ${REPLICATED_API_TOKEN} \
		--auto -y \
		--yaml-dir $(MANIFEST_DIR) \
		--promote $(CHANNEL)
