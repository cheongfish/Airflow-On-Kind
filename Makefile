.PHONY: deploy-kind clean-kind
# .PHONY: all clean deploy-metastore deploy-mysql deploy-trino clean-mysql clean-metastore clean-trino deploy-kind clean-kind
# By using ":=" fix initiate parameters
manifest_path := sandbox
waiting_seconds := 120s
cluster_name := test
host_path := $(shell pwd)

# --- Deployment Targets ---

KIND_HOST_PATH := $(shell pwd)
KIND_CONFIG_TEMP := $(manifest_path)/kind-cluster-temp.yaml

deploy-kind: app_name = $(patsubst deploy-%,%,$(@))
deploy-kind:
	@echo "Generating temporary Kind cluster config with dynamic hostPath..."
	@yq e '.nodes[1].extraMounts[0].hostPath = "$(KIND_HOST_PATH)"' $(manifest_path)/kind-cluster.yaml > $(KIND_CONFIG_TEMP)
	@echo Start deploy $(cluster_name) $(app_name)
	@kind create cluster --config $(KIND_CONFIG_TEMP) --name $(cluster_name)
	@echo "Waiting for $(app_name) cluster to be available..."
	@kubectl wait --for=condition=running pod -l tier=control-plane -n kube-system --timeout=$(waiting_seconds)
	@echo "✅ Deploy Complete: $(app_name)"
	@rm -f $(KIND_CONFIG_TEMP) # Clean up temporary file

clean-kind: app_name = $(patsubst deploy-%,%,$(@))
clean-kind:
	@echo "Start clean $(app_name) ..."
	@kind delete cluster --name $(cluster_name) || true
	@echo "✅ Clean Complete: $(app_name)"
	@rm -f $(KIND_CONFIG_TEMP) # Also clean up if clean-kind is run directly

# all: deploy-mysql deploy-metastore deploy-trino

# deploy-mysql: app_name = $(patsubst deploy-%,%,$(@))
# deploy-mysql:
# 	@echo Start deploy $(app_name)
# 	@kubectl create namespace $(app_name) || true
# 	@kubectl create -f $(manifest_path)/$(app_name)/ -n $(app_name)
# 	@echo "Waiting for $(app_name) deployment to be available..."
# 	@kubectl wait --for=condition=available deployment -l app=$(app_name) -n $(app_name) --timeout=$(waiting_seconds)
# 	@echo "✅ Deploy Complete: $(app_name)"


# deploy-metastore: app_name = $(patsubst deploy-%,%,$(@))
# deploy-metastore: waiting_seconds_init-schema = 240
# deploy-metastore:
# 	@echo Start deploy $(app_name)
# 	@kubectl create namespace $(app_name) || true
# 	@echo waiting $(waiting_seconds_init-schema)s for set up mysql
# 	@sleep $(waiting_seconds_init-schema)s | pv -t > /dev/null
# 	@echo "Start deploy init-schema for $(app_name)"
# 	@kubectl create -f $(manifest_path)/$(app_name)/init-schema.yaml -n $(app_name)
# 	@echo "Waiting for $(waiting_seconds) $(app_name) job to be completed..."
# 	@kubectl wait --for=condition=completed pod -l job-name=hive-initschema -n $(app_name) --timeout=$(waiting_seconds)
# 	@echo "Complete deploy init-schema for $(app_name)"
# 	@echo "Start deploy $(app_name) resources"
# 	@kubectl create -f $(manifest_path)/$(app_name)/resources/ -n $(app_name)
# 	@echo "Waiting for $(waiting_seconds) $(app_name) pod to be ready..."
# 	@kubectl wait --for=condition=ready pod -l app=$(app_name) -n $(app_name) --timeout=$(waiting_seconds)
# 	@echo "✅ Deploy Complete: $(app_name)"

# deploy-trino: app_name = $(patsubst deploy-%,%,$(@))
# deploy-trino:
# 	@echo "Start deploy $(app_name)"
# 	@helm install trino -n $(app_name) -f $(manifest_path)/$(app_name)/override-values.yaml $(manifest_path)/$(app_name)/   --create-namespace --debug
# 	@echo "Waiting $(waiting_seconds) for $(app_name) deployment to be available..."
# 	@kubectl wait --for=condition=available deployment -l app.kubernetes.io/instance=$(app_name) -n $(app_name) --timeout=$(waiting_seconds)
# 	@echo "✅ Deploy Complete: $(app_name)"

# clean-mysql: app_name = $(patsubst clean-%,%,$(@))
# clean-mysql:
# 	@echo "Start clean $(app_name) ..."
# 	@kubectl delete -f $(manifest_path)/mysql/ -n $(app_name) || true
# 	@echo "✅ Clean Complete: $(app_name)"

# clean-metastore: app_name = $(patsubst clean-%,%,$(@))
# clean-metastore:
# 	@echo "Start clean $(app_name) ..."
# 	@kubectl delete -f $(manifest_path)/$(app_name)/init-schema.yaml -n $(app_name) || true
# 	@kubectl delete -f $(manifest_path)/$(app_name)/resources/ -n $(app_name) || true
# 	@echo "✅ Clean Complete: $(app_name)"

# clean-trino: app_name = $(patsubst clean-%,%,$(@))
# clean-trino:
# 	@echo "Start clean $(app_name) ..."
# 	@helm uninstall trino -n $(app_name) || true
# 	@echo "✅ Clean Complete: $(app_name)"




# clean: clean-trino clean-metastore clean-mysql
