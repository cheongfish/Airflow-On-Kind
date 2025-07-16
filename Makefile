.PHONY: all deploy-kind clean-kind deploy-airflow deploy-kind clean-all
# By using ":=" fix initiate parameters
manifest_path := manifest
waiting_seconds := 120s
cluster_name := test
mount_container_path := /mnt/worker/dags
kind-cluster-maniest := kind-cluster_template
local-pvc-manifest := local-pvc
local-pv-manifest := local-pv
# --- Deployment Targets ---

KIND_HOST_PATH := $(shell pwd)
KIND_CONFIG_TEMP := kind-cluster-temp.yaml

all: deploy-kind deploy-airflow

deploy-kind: app_name = $(patsubst deploy-%,%,$(@))
deploy-kind:
	@echo "Generating temporary Kind cluster config with dynamic properties..."
	@yq e '.nodes[1].extraMounts[0].hostPath = "$(KIND_HOST_PATH)" | .nodes[1].extraMounts[0].containerPath = "$(mount_container_path)"' $(KIND_HOST_PATH)/$(kind-cluster-maniest).yaml > $(KIND_CONFIG_TEMP)
	@echo Start deploy $(cluster_name) $(app_name)
	@kind create cluster --config $(KIND_CONFIG_TEMP) --name $(cluster_name)
	@echo "Waiting for $(app_name) cluster to be available... timeout $(waiting_seconds)"
	@kubectl wait --for=condition=Ready pod -l tier=control-plane -n kube-system --timeout=$(waiting_seconds)
	@echo "✅ Deploy Complete: $(app_name)"
	@rm -f $(KIND_CONFIG_TEMP) # Clean up temporary file

deploy-airflow: app_name = $(patsubst deploy-%,%,$(@))
deploy-airflow:
	@echo Start deploy $(app_name)
	@kubectl create namespace $(app_name) || true
	@kubectl create -f $(local-pvc-manifest).yaml -f $(local-pv-manifest).yaml -n $(app_name)
	@helm install $(app_name) -f $(manifest_path)/$(app_name)/override-values.yaml $(manifest_path)/$(app_name)/ -n $(app_name) --debug
	@echo "Waiting for $(app_name) deployment to be available..."
	@kubectl wait --for=condition=available deployment -l release=$(app_name) -n $(app_name) --timeout=$(waiting_seconds)
	@kubectl port-forward service/airflow-api-server -n $(app_name) 8080:8080 #TODO: dynamically extract from airflow-chart manifest
	@echo "✅ Deploy Complete: $(app_name)"


clean-airflow: app_name = $(patsubst clean-%,%,$(@))
clean-airflow:
	@echo "Start clean $(app_name) ..."
	@kubectl delete -f $(local-pvc-manifest).yaml -f $(local-pv-manifest).yaml -n $(app_name)
	@helm uninstall $(app_name) -n $(app_name) || true
	@kubectl delete ns $(app_name)
	@echo "✅ Clean Complete: $(app_name)"

clean-kind: app_name = $(patsubst clean-%,%,$(@))
clean-kind:
	@echo "Start clean $(app_name) ..."
	@kind delete cluster --name $(cluster_name) || true
	@echo "✅ Clean Complete: $(app_name)"
	@rm -f $(KIND_CONFIG_TEMP) # Also clean up if clean-kind is run directly

clean-all: clean-airflow clean-kind
