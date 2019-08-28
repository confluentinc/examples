
THIS_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MKFILE_DIR := $(dir $(MKFILE_PATH))

include $(THIS_MKFILE_DIR)../common/Makefile

GKE_BASE_CLUSTER_ID ?= cp-examples-operator
GKE_BASE_REGION ?= us-central1
GKE_BASE_ZONE ?= us-central1-a
GKE_BASE_SUBNET ?= default
GKE_BASE_CLUSTER_VERSION ?= 1.12.8-gke.10
GKE_BASE_MACHINE_TYPE ?= n1-standard-2
GKE_BASE_IMAGE_TYPE ?= COS
GKE_BASE_DISK_TYPE ?= pd-standard
GKE_BASE_DISK_SIZE ?= 100
GKE_BASE_NUM_NODES ?= 10

HELM_COMMON_FLAGS := --set global.provider.registry.fqdn=docker.io --set global.provider.name=gcp --set global.provider.region=$(GKE_BASE_REGION) --set global.provider.kubernetes.deployment.zones={$(GKE_BASE_ZONE)} --set global.provider.storage.provisioner=kubernetes.io/gce-pd --set global.provider.storage.reclaimPolicy=Delete --set global.provider.storage.parameters.type=pd-ssd --set global.provider.sasl.plain.username=test --set global.provider.sasl.plain.password=test123

gke-kubectl-current-context = $(shell kubectl config current-context)

gke-cluster-exists = $(if $(shell gcloud --format json container clusters list | jq -r '.[] | select(.name == "$(GKE_BASE_CLUSTER_ID)") | .name'),,false)

gke-create-cluster: gke-base-validate
	@gcloud container --project $(GCP_PROJECT_ID) clusters create $(GKE_BASE_CLUSTER_ID) --zone $(GKE_BASE_ZONE) --no-enable-basic-auth --cluster-version $(GKE_BASE_CLUSTER_VERSION) --machine-type $(GKE_BASE_MACHINE_TYPE) --image-type $(GKE_BASE_IMAGE_TYPE) --disk-type $(GKE_BASE_DISK_TYPE) --disk-size $(GKE_BASE_DISK_SIZE) --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes $(GKE_BASE_NUM_NODES) --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$(GCP_PROJECT_ID)/global/networks/default" --subnetwork "projects/$(GCP_PROJECT_ID)/regions/$(GKE_BASE_REGION)/subnetworks/$(GKE_BASE_SUBNET)" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

gke-base-check-dependencies: init
	@$(call check-dependency,gcloud)
	@$(call echo_pass,gke-base dependencies verified)

gke-base-validate: gke-base-check-dependencies
	@$(call check-var-defined,GCP_PROJECT_ID)
ifeq (,$(findstring $(GKE_BASE_CLUSTER_ID),$(gke-kubectl-current-context)))
	@$(error "kubectl context does not appear to be set properly, should point to '$(GKE_BASE_CLUSTER_ID)'. See: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl")
endif
	@$(call echo_pass,kubectl context set to: $(gke-kubectl-current-context))
	@$(call echo_pass,validation complete)

gke-base-deploy-operator:
	@$(call echo_stdout_header,deploy operator)	
	@helm upgrade --wait --install --namespace operator --set operator.enabled=true $(HELM_COMMON_FLAGS) operator $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,operator deployed)

gke-base-deploy-zookeeper:
	@$(call echo_stdout_header,deploy zookeeper)
	helm upgrade --wait --install --namespace operator --set zookeeper.enabled=true --set zookeeper.replicas=3 --set zookeeper.resources.cpu=200m --set zookeeper.resources.memory=512Mi $(HELM_COMMON_FLAGS) zookeeper $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,zookeeper deployed)

gke-base-deploy-kafka:
	@$(call echo_stdout_header,deploy kafka)
	helm upgrade --wait --install --namespace operator --set kafka.enabled=true --set kafka.replicas=3 --set kafka.resources.cpu=200m --set kafka.resources.memory=1Gi --set kafka.loadBalancer.enabled=false --set kafka.tls.enabled=false --set kafka.metricReporter.enabled=false $(HELM_COMMON_FLAGS) kafka $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,kafka deployed)

gke-base-deploy-schemaregistry:
	@$(call echo_stdout_header,deploy schema registry)
	helm upgrade --wait --install --namespace operator --set schemaregistry.enabled=true --set schemaregistry.dependencies.kafka.brokerCount=3 --set schemaregistry.dependencies.kafka.bootstrapEndpoint=kafka:9071 $(HELM_COMMON_FLAGS) schemaregistry $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,schema registry deployed)

gke-base-deploy-connect:
	@$(call echo_stdout_header,deploy connect)
	helm upgrade --wait --install --namespace operator --set connect.enabled=true --set connect.tls.enabled=false --set connect.loadBalancer.enabled=false --set connect.dependencies.kafka.brokerCount=3 --set connect.dependencies.kafka.bootstrapEndpoint=kafka:9071 --set connect.dependencies.schemaregistry.enabled=true --set connect.dependencies.schemaregistry.url=http://schemaregistry:8081 $(HELM_COMMON_FLAGS) connect $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer)	
	@$(call echo_pass,schema registry deployed)

gke-base-demo: gke-base-validate
	@make --no-print-directory gke-base-deploy-operator
	@make --no-print-directory gke-base-deploy-zookeeper
	@make --no-print-directory gke-base-deploy-kafka
	@make --no-print-directory gke-base-deploy-schemaregistry
	@make --no-print-directory gke-base-deploy-connect
	@$(call echo_pass,GKE Base Demo running)

# TODO: Wait until all destroyed w/ a timeout
gke-base-destroy-demo: gke-base-validate
	-@helm del --purge connect
	-@helm del --purge schemaregistry	
	-@helm del --purge kafka
	-@helm del --purge zookeeper
	-@helm del --purge operator
	@$(call echo_stdout_header,check for abandoned resources)
	@kubectl get -n operator all
	@$(call echo_stdout_footer)
	@$(call echo_pass,GKE Base Demo destroyed)

demo:
	@make --no-print-directory gke-base-demo

destroy-demo:
	@make --no-print-directory gke-base-destroy-demo
