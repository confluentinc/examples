
THIS_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MKFILE_DIR := $(dir $(MKFILE_PATH))

include $(THIS_MKFILE_DIR)../common/Makefile

GKE_BASE_CLUSTER_ID ?= cp-examples-operator
GKE_BASE_REGION ?= us-central1
GKE_BASE_ZONE ?= us-central1-a
GKE_BASE_SUBNET ?= default
GKE_BASE_CLUSTER_VERSION ?= 1.12.8-gke.10
GKE_BASE_MACHINE_TYPE ?= n1-highmem-2
GKE_BASE_IMAGE_TYPE ?= COS
GKE_BASE_DISK_TYPE ?= pd-standard
GKE_BASE_DISK_SIZE ?= 100
GKE_BASE_NUM_NODES ?= 10
GKE_BASE_REGION ?= us-central1
GKE_BASE_ZONE ?= us-central1-a
GKE_BASE_SUBNET ?= default
GKE_BASE_CLUSTER_VERSION ?= 1.12.8-gke.10
GKE_BASE_MACHINE_TYPE ?= n1-highmem-4
GKE_BASE_IMAGE_TYPE ?= COS
GKE_BASE_DISK_TYPE ?= pd-standard
GKE_BASE_DISK_SIZE ?= 100
GKE_BASE_NUM_NODES ?= 10

KUBECTL_CONTEXT ?= gke_$(GCP_PROJECT_ID)_$(GKE_BASE_ZONE)_$(GKE_BASE_CLUSTER_ID)

gke-kubectl-current-context = $(shell kubectl config current-context 2>&1 /dev/null)

kubectl-cmd = kubectl --context $(KUBECTL_CONTEXT) -n operator $(1)

HELM_COMMON_FLAGS := --set global.provider.registry.fqdn=docker.io --set global.provider.name=gcp --set global.provider.region=$(GKE_BASE_REGION) --set global.provider.kubernetes.deployment.zones={$(GKE_BASE_ZONE)} --set global.provider.storage.provisioner=kubernetes.io/gce-pd --set global.provider.storage.reclaimPolicy=Delete --set global.provider.storage.parameters.type=pd-ssd --set global.provider.sasl.plain.username=test --set global.provider.sasl.plain.password=test123

gke-cluster-exists = $(if $(shell gcloud --format json container clusters list | jq -r '.[] | select(.name == "$(GKE_BASE_CLUSTER_ID)") | .name'),,false)

gke-check-dependencies: check-dependencies
	@$(call check-var-defined,GCP_PROJECT_ID)
	@$(call check-dependency,gcloud)
	@$(call echo_pass,gke-base dependencies verified)

gke-create-cluster: gke-check-dependencies
	@gcloud container --project $(GCP_PROJECT_ID) clusters create $(GKE_BASE_CLUSTER_ID) --zone $(GKE_BASE_ZONE) --no-enable-basic-auth --cluster-version $(GKE_BASE_CLUSTER_VERSION) --machine-type $(GKE_BASE_MACHINE_TYPE) --image-type $(GKE_BASE_IMAGE_TYPE) --disk-type $(GKE_BASE_DISK_TYPE) --disk-size $(GKE_BASE_DISK_SIZE) --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes $(GKE_BASE_NUM_NODES) --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$(GCP_PROJECT_ID)/global/networks/default" --subnetwork "projects/$(GCP_PROJECT_ID)/regions/$(GKE_BASE_REGION)/subnetworks/$(GKE_BASE_SUBNET)" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

gke-base-validate: gke-check-dependencies init
	@$(call echo_pass,validation complete)

###### OPERATOR MANAGEMENT ######
gke-base-deploy-operator: gke-base-validate ## Deploys the Confluent Operator into the configured k8s cluster 
	@$(call echo_stdout_header,deploy operator)	
	@helm upgrade --wait --install --namespace operator --set operator.enabled=true $(HELM_COMMON_FLAGS) operator $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,operator deployed)

gke-base-wait-for-operator: ## Waits until the Confluent Operator rollout status is complete
	@$(call echo_stdout_header,wait for operator)	
	$(call kubectl-cmd,rollout status deployment/cc-operator)
	$(call kubectl-cmd,rollout status deployment/cc-manager)
	@$(call echo_stdout_footer)	
	@$(call echo_pass,operator ready)

gke-base-destroy-operator: ## Destroy the operator deployment on the configured k8s cluster
	@$(call echo_stdout_header,destroy operator)
	-helm delete --purge operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,operator destroyed)

gke-base-wait-for-operator-destruction: ## Will wait until the Confluent Operator & Manager are destroyed
	@$(call echo_stdout_header,ensure operator destroyed)
	-$(call kubectl-cmd,wait --timeout=60s --for=delete deployment/cc-manager)
	-$(call kubectl-cmd,wait --timeout=60s --for=delete deployment/cc-operator)
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper gone)
#################################

###### ZOOKEEPER MANAGEMENT ######
gke-base-deploy-zookeeper: ## Deploys Zookeeper into the configured k8s cluster
	@$(call echo_stdout_header,deploy zookeeper)
	helm upgrade --wait --install --namespace operator --set zookeeper.enabled=true --set zookeeper.replicas=3 --set zookeeper.resources.cpu=200m --set zookeeper.resources.memory=512Mi $(HELM_COMMON_FLAGS) zookeeper $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper deployed)

gke-base-wait-for-zookeeper: ## Waits until the Zookeeper rollout is complete
	@$(call echo_stdout_header,wait for zookeper)
	source $(COMMON_MKFILE_DIR)retry.sh; retry 50 kubectl --context $(KUBECTL_CONTEXT) -n operator get sts zookeeper 
	$(call kubectl-cmd,rollout status statefulset/zookeeper)
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper ready)

gke-base-destroy-zookeeper: ## Destroy the Zookeeper cluster
	@$(call echo_stdout_header,destroy zookeeper)
	-helm delete --purge zookeeper
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper destroyed)

gke-base-wait-for-zookeeper-destruction: ## Waits until the Zookeper cluster is destroyed
	@$(call echo_stdout_header,ensure zookeeper destroyed)
	-$(call kubectl-cmd,wait --timeout=60s --for=delete statefulset/zookeeper)
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper gone)
#################################

gke-base-deploy-kafka:
	@$(call echo_stdout_header,deploy kafka)
	helm upgrade --install --namespace operator --set kafka.enabled=true --set kafka.replicas=3 --set kafka.resources.cpu=200m --set kafka.resources.memory=1Gi --set kafka.loadBalancer.enabled=false --set kafka.tls.enabled=false --set kafka.metricReporter.enabled=false $(HELM_COMMON_FLAGS) kafka $(OPERATOR_PATH)helm/confluent-operator
	@$(call kubectl-cmd,rollout status statefulset/zookeeper)
	@$(call echo_stdout_footer)	
	@$(call echo_pass,kafka deployed)

gke-base-deploy-schemaregistry:
	@$(call echo_stdout_header,deploy schema registry)
	helm upgrade --install --namespace operator --set schemaregistry.enabled=true --set schemaregistry.dependencies.kafka.brokerCount=3 --set schemaregistry.dependencies.kafka.bootstrapEndpoint=kafka:9071 $(HELM_COMMON_FLAGS) schemaregistry $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,schema registry deployed)

gke-base-deploy-connect:
	@$(call echo_stdout_header,deploy connect)
	helm upgrade --install --namespace operator --set connect.enabled=true --set connect.tls.enabled=false --set connect.loadBalancer.enabled=false --set connect.dependencies.kafka.brokerCount=3 --set connect.dependencies.kafka.bootstrapEndpoint=kafka:9071 --set connect.dependencies.schemaregistry.enabled=true --set connect.dependencies.schemaregistry.url=http://schemaregistry:8081 $(HELM_COMMON_FLAGS) connect $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,schema registry deployed)

gke-base-demo: 
	@make --no-print-directory gke-base-deploy-operator
	@make --no-print-directory gke-base-wait-for-operator
	@make --no-print-directory gke-base-deploy-zookeeper
	@make --no-print-directory gke-base-wait-for-zookeeper
	@$(call echo_pass,GKE Base Demo running)

gke-base-destroy-demo: gke-base-validate
	@make --no-print-directory gke-base-destroy-zookeeper
	@make --no-print-directory gke-base-wait-for-zookeeper-destruction
	@make --no-print-directory gke-base-destroy-operator
	@make --no-print-directory gke-base-wait-for-operator-destruction
	@$(call echo_stdout_header,check for abandoned resources)
	@$(call kubectl_cmd,get all)
	@$(call echo_stdout_footer)
	@$(call echo_pass,GKE Base Demo destroyed)

demo:
	@make --no-print-directory gke-base-demo

destroy-demo:
	@make --no-print-directory gke-base-destroy-demo

