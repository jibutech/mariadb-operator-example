.DEFAULT_GOAL:=help
SHELL:=/bin/bash
NAMESPACE=mariadb

##@ Application

install: ## Install all resources (CR/CRD's, RBAC and Operator)
	@echo ....... Creating namespace ....... 
	- kubectl create namespace ${NAMESPACE}
	@echo ....... Applying CRDs .......
	- kubectl apply -f deploy/crds/mariadb.persistentsys_mariadbs_crd.yaml -n ${NAMESPACE}
	- kubectl apply -f deploy/crds/mariadb.persistentsys_backups_crd.yaml -n ${NAMESPACE}
	- kubectl apply -f deploy/crds/mariadb.persistentsys_monitors_crd.yaml -n ${NAMESPACE}
	@echo ....... Applying Rules and Service Account .......
	- kubectl apply -f deploy/service_account.yaml  -n ${NAMESPACE}
	- kubectl apply -f deploy/role.yaml -n ${NAMESPACE}
	- sed -i 's/.*namespace:.*/    namespace: ${NAMESPACE}/' deploy/role_binding.yaml
	- kubectl apply -f deploy/role_binding.yaml  -n ${NAMESPACE}
	@echo ....... Applying Operator .......
	- kubectl apply -f deploy/operator.yaml -n ${NAMESPACE}
	@echo ....... Creating the CRs .......
	- kubectl apply -f deploy/crds/mariadb.persistentsys_v1alpha1_mariadb_cr.yaml -n ${NAMESPACE}
	- kubectl apply -f deploy/crds/mariadb.persistentsys_v1alpha1_monitor_cr.yaml -n ${NAMESPACE}

uninstall: ## Uninstall all that all performed in the $ make install
	@echo ....... Uninstalling .......
	@echo ....... Deleting CRs.......
	- kubectl delete -f deploy/crds/mariadb.persistentsys_v1alpha1_backup_cr.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/crds/mariadb.persistentsys_v1alpha1_mariadb_cr.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/crds/mariadb.persistentsys_v1alpha1_monitor_cr.yaml -n ${NAMESPACE}

	@echo ....... Deleting Operator ......
	- kubectl delete -f deploy/operator.yaml -n ${NAMESPACE}
	@echo ....... Deleting PV and PVC.......

	- kubectl delete pv mariadb-backup-${NAMESPACE}-pv
	- kubectl delete pv mariadb-${NAMESPACE}-pv

	@echo ....... Deleting CRDs.......
	- kubectl delete -f deploy/crds/mariadb.persistentsys_backups_crd.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/crds/mariadb.persistentsys_mariadbs_crd.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/crds/mariadb.persistentsys_monitors_crd.yaml -n ${NAMESPACE}
	@echo ....... Deleting Rules and Service Account .......
	- kubectl delete -f deploy/role_binding.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/role.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/service_account.yaml -n ${NAMESPACE}

##@ Development

code-vet: ## Run go vet for this project. More info: https://golang.org/cmd/vet/
	@echo go vet
	go vet $$(go list ./... )

code-fmt: ## Run go fmt for this project
	@echo go fmt
	go fmt $$(go list ./... )

code-dev: ## Run the default dev commands which are the go fmt and vet then execute the $ make code-gen
	@echo Running the common required commands for developments purposes
	- make code-fmt
	- make code-vet
	- make code-gen

code-gen: ## Run the operator-sdk commands to generated code (k8s and openapi)
	@echo Updating the deep copy files with the changes in the API
	operator-sdk generate k8s
	@echo Updating the CRD files with the OpenAPI validations
	operator-sdk generate openapi


.PHONY: help
help: ## Display this help
	@echo -e "Usage:\n  make \033[36m<target>\033[0m"
	@awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
