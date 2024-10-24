NODE_VERSION ?= 0.0.1

GITHUB_USERNAME = streamweaverio
GO_REPO_NAME = go-protos

PROTO_DIR = definitions/
PROTO_FILES = $(PROTO_DIR)*.proto

# Output paths
OUTPUT_GO = ./outputs/protos
OUTPUT_NODE = ./outputs/protos

# package names
PACKAGE_GO = github.com/$(GITHUB_USERNAME)/$(GO_REPO_NAME)

clean_node:
	@rm -rf $(OUTPUT_NODE)

clean_go:
	@rm -rf $(OUTPUT_NODE)

gen_go: clean_go
	@mkdir -p $(OUTPUT_GO)
	protoc -I $(PROTO_DIR) $(PROTO_FILES) \
	--go_out=$(OUTPUT_GO) \
	--go-grpc_out=$(OUTPUT_GO)

gen_node_ts: clean_node
	@mkdir -p $(OUTPUT_NODE)
	./node_modules/.bin/grpc_tools_node_protoc \
	  --js_out=import_style=commonjs,binary:$(OUTPUT_NODE) \
	  --grpc_out=grpc_js:$(OUTPUT_NODE) \
	  --plugin=protoc-gen-grpc=./node_modules/.bin/grpc_tools_node_protoc_plugin \
	  -I $(PROTO_DIR) $(PROTO_FILES) && \
	  protoc \
	  --plugin=protoc-gen-ts=./node_modules/.bin/protoc-gen-ts \
	  --ts_out=grpc_js:$(OUTPUT_NODE) \
	  -I $(PROTO_DIR) $(PROTO_FILES)

package_go:
	@cd $(OUTPUT_GO)/$(PACKAGE_GO) && \
	if [ -f go.mod ]; then go mod tidy; else go mod init $(PACKAGE_GO) && go mod tidy; fi

package_node:
	@cd $(OUTPUT_NODE) && npm init --scope=@streamweaverio -y
	@cd $(OUTPUT_NODE) && npm version $(NODE_VERSION)
	@cd $(OUTPUT_NODE) && npm install grpc @grpc/grpc-js google-protobuf --save
	@cd $(OUTPUT_NODE) && npm install --save-dev @types/google-protobuf
	@if [ -n "$(NPM_TOKEN)" ]; then \
		echo "//registry.npmjs.org/:_authToken=$(NPM_TOKEN)" > $(OUTPUT_NODE)/.npmrc; \
		echo "NPM authentication configured"; \
	else \
		cd $(OUTPUT_NODE) && npm login --scope=@streamweaverio; \
	fi
	@echo "Node.js package preparation complete"
