CHANNEL=development

MANIFEST_DIR   := ./manifests
MANIFESTS := $(shell find $(MANIFEST_DIR) -name '*.yaml' -o -name '*.tgz')

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
