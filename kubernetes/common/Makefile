.PHONY: *

HELP_TAB_WIDTH = 25

.DEFAULT_GOAL := help

SHELL=/bin/bash -o pipefail

echo_fail = printf "\e[31m✘ \033\e[0m$(1)\n"
echo_pass = printf "\e[32m✔ \033\e[0m$(1)\n"
echo_stdout_header = printf "\n+++++++++++++ $(1)\n"
echo_stdout_footer = printf "+++++++++++++ $(1)\n"
echo_stdout_footer_pass = printf "\e[32m✔ \033\e[0m ++++++++++ $(1) \n"

COMMON_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
COMMON_MKFILE_DIR := $(dir $(COMMON_MKFILE_PATH))

# includes should come after any usage of MAKEFILE_LIST
# as it affects the results of that command and the result of our usage of
# lastword above changes after this include
include ../../utils/config.env

OPERATOR_FILE_NAME := confluent-operator-$(OPERATOR_BUNDLE_VERSION)-for-confluent-platform-$(OPERATOR_BUNDLE_CP_VERSION).tar.gz
OPERATOR_DOWNLOAD_PATH := $(COMMON_MKFILE_DIR)cp/operator/$(OPERATOR_FILE_NAME)
OPERATOR_PATH := $(dir $(OPERATOR_DOWNLOAD_PATH))$(OPERATOR_BUNDLE_VERSION)/

check-dependency = $(if $(shell command -v $(1)),$(call echo_pass,found $(1)),$(call echo_fail,$(1) not installed);exit 1)

check-var-defined = $(if $(strip $($1)),,$(error "$1" is not defined))

check-dependencies:
	@$(call check-dependency,curl)
	@$(call check-dependency,tar)
	@$(call check-dependency,kubectl)
	@$(call check-dependency,helm)
	@$(call check-dependency,jq)

help: ## shows help for each target
	@$(foreach m,$(MAKEFILE_LIST),grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(m) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-$(HELP_TAB_WIDTH)s\033[0m %s\n", $$1, $$2}';)

extended-help: 
	@$(foreach m,$(MAKEFILE_LIST),grep -E '^[a-zA-Z_-]+:.*?#_ .*$$' $(m) | sort | awk 'BEGIN {FS = ":.*?#_ "}; {printf "\033[36m%-$(HELP_TAB_WIDTH)s\033[0m %s\n", $$1, $$2}';)

# https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-1.6.0-for-confluent-platform-6.0.0.tar.gz
get-helm-bundle: #_ Download the Confluent Operator Helm bundle locally in preparation for installation
ifeq (,$(wildcard $(OPERATOR_DOWNLOAD_PATH)))
	@mkdir -p $(dir $(OPERATOR_DOWNLOAD_PATH))
	@echo "downloading Confluent Operator to $(OPERATOR_DOWNLOAD_PATH)"
	@curl -s https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/$(OPERATOR_FILE_NAME) --output $(OPERATOR_DOWNLOAD_PATH)
endif
ifeq (,$(wildcard $(OPERATOR_PATH)))
	@mkdir -p $(dir $(OPERATOR_DOWNLOAD_PATH))$(OPERATOR_BUNDLE_VERSION)/
	@echo "Extracting operator to $(OPERATOR_PATH)"
	@tar xf $(OPERATOR_DOWNLOAD_PATH) -C $(OPERATOR_PATH)
endif
	@$(call echo_pass,Confluent Platform Operator helm bundle ready at: $(OPERATOR_PATH))

init: check-dependencies get-helm-bundle #_ Initializes the common dependencies @echo
	@$(call echo_pass,common initialization complete)

ensure-namespace:
	@$(call echo_stdout_header,ensuring namespace is available)	
	-kubectl --context $(KUBECTL_CONTEXT) apply -f $(COMMON_MKFILE_DIR)cfg/operator-namespace.json
	@$(call echo_stdout_footer_pass,namespace ready)

base-demo-validate: init
	@echo
	@make --no-print-directory ensure-namespace

###### OPERATOR MANAGEMENT ######
deploy-operator: #_ Deploys the Confluent Operator into the configured k8s cluster 
	@$(call echo_stdout_header,deploy operator)	
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set operator.enabled=true operator $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,operator deployed)

wait-for-operator: #_ Waits until the Confluent Operator rollout status is complete
	@$(call echo_stdout_header,wait for operator)	
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status deployment/cc-operator
	@$(call echo_stdout_footer_pass,operator ready)

destroy-operator: #_ Destroy the operator deployment on the configured k8s cluster
	@$(call echo_stdout_header,destroy operator)
	-helm delete operator --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,operator destroyed)

wait-for-operator-destruction: #j Will wait until the Confluent Operator & Manager are destroyed
	@$(call echo_stdout_header,ensure operator destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete deployment/cc-operator
	@$(call echo_stdout_footer_pass,operator gone)
#################################

###### ZOOKEEPER MANAGEMENT ######
deploy-zookeeper: #_ Deploys Zookeeper into the configured k8s cluster
	@$(call echo_stdout_header,Deploy Zookeeper)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set zookeeper.image.tag=$(OPERATOR_CP_IMAGE_TAG) --set zookeeper.replicas=$(ZOOKEEPER_REPLICAS) --set zookeeper.enabled=true zookeeper $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Zookeeper deployed)

wait-for-zookeeper: #_ Waits until the Zookeeper rollout is complete
	@$(call echo_stdout_header,Wait for Zookeper)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts zookeeper 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/zookeeper
	@$(call echo_stdout_footer_pass,Zookeeper ready)

destroy-zookeeper: #_ Purge the Zookeeper package 
	@$(call echo_stdout_header,Purge the Zookeeper package)
	-helm delete zookeeper --namespace $(KUBECTL_NAMESPACE)
# There are currently some issues with ZK cleanup in the Helm packages, for now i'm helping along with extra delete commands
	-kubectl -n $(KUBECTL_NAMESPACE) delete sts/zookeeper
	-kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper;kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper-0-internal;
	-kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper;kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper-1-internal;
	-kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper;kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper-2-internal;
	@$(call echo_stdout_footer_pass,Zookeeper purged)

wait-for-zookeeper-destruction: #_ Waits until the Zookeper cluster is destroyed
	@$(call echo_stdout_header,Ensure Zookeeper destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/zookeeper
	@$(call echo_stdout_footer_pass,Zookeeper gone)
#################################

######### KAFKA MANAGEMENT ######
deploy-kafka: #_ Deploys Kafka into the configured k8s cluster
	@$(call echo_stdout_header,deploy kafka) 
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set kafka.image.tag=$(OPERATOR_CP_IMAGE_TAG) --set kafka.replicas=$(KAFKA_REPLICAS) --set kafka.enabled=true kafka $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Kafka deployed)

wait-for-kafka: #_ Waits until the Kafka rollout is complete
	@$(call echo_stdout_header,Wait for Kafka)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts kafka 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/kafka
	@$(call echo_stdout_footer_pass,Kafka ready)

destroy-kafka: #_ Purge the Kafka package 
	@$(call echo_stdout_header,Purge the Kafka package)
	-helm delete kafka --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,Kafka purged)

wait-for-kafka-destruction: #_ Waits until the Kafka cluster is destroyed
	@$(call echo_stdout_header,Ensure Kafka destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/kafka
	@$(call echo_stdout_footer_pass,Kafka gone)
#################################

### SCHEMA REGISTRY MANAGEMENT ##
deploy-schemaregistry: #_ Deploys the Schmea Registry to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Schema Registry)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set schemaregistry.image.tag=$(OPERATOR_CP_IMAGE_TAG) --set schemaregistry.enabled=true --set schemaregistry.replicas=$(SCHEMA_REGISTRY_REPLICAS) schemaregistry $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Schema Registry deployed)

wait-for-schemaregistry: #_ Waits until the Schema Registry rollout is complete
	@$(call echo_stdout_header,Wait for Schema Registry)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts schemaregistry
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/schemaregistry
	@$(call echo_stdout_footer_pass,Schema Registry ready)

destroy-schemaregistry: #_ Purge the Schema Registry package
	@$(call echo_stdout_header,Purge the Schema Registry package)
	-helm delete schemaregistry --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,Schema Registry purged) 

wait-for-schemaregistry-destruction: #_ Waits until the Schema Registry is destroyed
	@$(call echo_stdout_header,Ensure Schema Registry destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/schemaregistry
	@$(call echo_stdout_footer_pass,Schema Registry gone)
#################################

##### CONNECT  MANAGEMENT #######
deploy-connect: #_ Deploys Kafka Connect to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Kafka Connect)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set connect.image.tag=$(OPERATOR_KAFKA_CONNECT_DATAGEN_IMAGE_TAG) --set connect.enabled=true --set connect.replicas=$(CONNECT_REPLICAS) connect $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Kafka Connect deployed)

wait-for-connect: #_ Waits until the Kafka Connect rollout is complete
	@$(call echo_stdout_header,Wait for Kafka Connect)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts connectors
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/connectors
	@$(call echo_stdout_footer_pass,Kafka Connect ready)

destroy-connect: #_ Purge the Kafka Connect package 
	@$(call echo_stdout_header,Purge the Kafka Connect package)
	-helm delete connect --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,Kafka Connect purged)

wait-for-connect-destruction: #_ Waits until Kafka Connect is destroyed
	@$(call echo_stdout_header,Ensure Kafka Connect destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/connectors
	@$(call echo_stdout_footer_pass,Kafka Connect gone)
#################################

### CONTROL CENTER MANAGEMENT ####
deploy-controlcenter: #_ Deploys Confluent Control Center to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Control Center)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set controlcenter.image.tag=$(OPERATOR_CP_IMAGE_TAG) --set controlcenter.enabled=true controlcenter $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Control Center deployed)

wait-for-controlcenter: #_ Waits until the Control Center rollout is complete
	@$(call echo_stdout_header,Wait for Control Center)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts controlcenter 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/controlcenter
	@$(call echo_stdout_footer_pass,Control Center ready)

destroy-controlcenter: #_ Purge the Control Center package 
	@$(call echo_stdout_header,Purge the Control Center package)
	-helm delete controlcenter --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,Control Center purged)

wait-for-controlcenter-destruction: #_ Waits until Control Center is destroyed
	@$(call echo_stdout_header,Ensure Control Center destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/controlcenter
	@$(call echo_stdout_footer_pass,Control Center gone)
#################################

### CLICKS DATA GEN CONNECTOR ###
deploy-clicks-connector-config: #_ Deploys configuration for a connector that generates sample click data
	@$(call echo_stdout_header,Deploy clicks datagen connector config)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(COMMON_MKFILE_DIR)cfg/clicks-datagen-connector-configmap.yaml
	@$(call echo_stdout_footer_pass,clicks datagen connector config deployed)

destroy-clicks-connector-deploy-job: #_ Destroys the job that deployed the sample data generator connector
	@$(call echo_stdout_header,destroy Deploy clicks datagen connector job)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete jobs/clicks-datagen-connector-deploy ## name dependnecy in file, required unless/until TTL works across all k8s configurations
	@$(call echo_stdout_footer_pass,clicks datagen connector job destroyed)

deploy-clicks-connector: deploy-clicks-connector-config destroy-clicks-connector-deploy-job #_ Deploys a connector that generates sample click data
	@$(call echo_stdout_header,Deploy clicks datagen connector)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(COMMON_MKFILE_DIR)cfg/clicks-datagen-connector-deploy-job.yaml
	@$(call echo_stdout_footer_pass,clicks datagen connector deployed)
#################################

### STOCK TRADES DATA GEN CONNECTOR ###
deploy-stock-trades-connector-config: #_ Deploys configuration for a connector that generates sample stock trade data
	@$(call echo_stdout_header,Deploy stock trades datagen connector config)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(COMMON_MKFILE_DIR)cfg/stock-trades-datagen-connector-configmap.yaml
	@$(call echo_stdout_footer_pass,stock trades datagen connector config deployed)

destroy-stock-trades-connector: #_ Destroys the deploy job and configuration for the sample stock trades data generator
	@$(call echo_stdout_header,destroy Deploy stock trades datagen connector)
	-make --no-print-directory destroy-stock-trades-connector-deploy-job
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete configmap/stock-trades-datagen-connector
	@$(call echo_stdout_footer_pass,stock trades datagen connector destroyed)

destroy-stock-trades-connector-deploy-job: #_ Destroys the job that deployed the sample stock trades data generator connector
	@$(call echo_stdout_header,destroy Deploy stock trades datagen connector job)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete jobs/stock-trades-datagen-connector-deploy ## name dependnecy in file, required unless/until TTL works across all k8s configurations
	@$(call echo_stdout_footer_pass,stock trades datagen connector job destroyed)

deploy-stock-trades-connector: deploy-stock-trades-connector-config destroy-stock-trades-connector-deploy-job #_ Deploys a connector that generates sample stock trades data
	@$(call echo_stdout_header,Deploy stock trades datagen connector)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(COMMON_MKFILE_DIR)cfg/stock-trades-datagen-connector-deploy-job.yaml
	@$(call echo_stdout_footer_pass,stock trades datagen connector deployed)
#################################

########## CLIENT SECRETS #######
deploy-client-secrets:
	@$(call echo_stdout_header,Deploy client secrets)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(COMMON_MKFILE_DIR)cfg/kafka-client-secrets.yaml
	@$(call echo_stdout_footer_pass,client secrets deployed)

destroy-client-secrets:
	@$(call echo_stdout_header,Delete client secrets)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete secret kafka-client.properties
	@$(call echo_stdout_footer_pass,client secrets destroyed)
#################################

########## CLIENT CONSOLE #######
destroy-client-console:
	@$(call echo_stdout_header,Delete client-console)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete pod client-console 
	@$(call echo_stdout_footer_pass,client-console destroyed)
#################################


###### REPLICATOR MANAGEMENT ######
deploy-replicator: #_ Deploys Replicator into the configured k8s cluster
	@$(call echo_stdout_header,Deploy Replicator)
	@echo "helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set replicator.enabled=true $(HELM_COMMON_FLAGS) --set global.sasl.plain.username=[redacted] --set global.sasl.plain.password=[redacted] replicator $(OPERATOR_PATH)helm/confluent-operator"
	@helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set replicator.enabled=true $(HELM_COMMON_FLAGS) --set global.sasl.plain.username=$(CCLOUD_API_KEY) --set global.sasl.plain.password=$(CCLOUD_API_SECRET) replicator $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Replicator deployed)

wait-for-replicator: #_ Waits until the Replicator rollout is complete
	@$(call echo_stdout_header,Wait for Replicator)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts replicator 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/replicator
	@$(call echo_stdout_footer_pass,Replicator ready)

destroy-replicator: #_ Purge the Replicator package 
	@$(call echo_stdout_header,Purge the Replicator package)
	-helm delete replicator --namespace $(KUBECTL_NAMESPACE)
	@$(call echo_stdout_footer_pass,Replicator purged)

wait-for-replicator-destruction: #_ Waits until the Replicator cluster is destroyed
	@$(call echo_stdout_header,Ensure Replicator destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/replicator
	@$(call echo_stdout_footer_pass,Replicator gone)
#################################

##### DEMO HELM CHART #####
deploy-replicator-demo-helm: #_ Deploys the helm chart for some custom items for this demo
	@$(call echo_stdout_header,Deploy Replicator Deploy Job)
	@echo "helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set global.sasl.plain.username=[redacted] --set global.sasl.plain.password=[redacted] replicator-cc $(COMMON_MKFILE_DIR)helm/replicator-cc"
	@helm upgrade --install --namespace $(KUBECTL_NAMESPACE) $(HELM_COMMON_FLAGS) --set global.sasl.plain.username=$(CCLOUD_API_KEY) --set global.sasl.plain.password=$(CCLOUD_API_SECRET) replicator-cc $(COMMON_MKFILE_DIR)helm/replicator-cc
	@$(call echo_stdout_footer_pass,Replicator Deploy Job deployed)

destroy-demo-helm: #_ Destroys the deploy job and configuration for Replicator
	@$(call echo_stdout_header,destroy Deploy stock trades datagen connector)
	-helm delete replicator-cc --namespace $(KUBECTL_NAMESPACE)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete configmap/stock-trades-datagen-connector
	@$(call echo_stdout_footer_pass,stock trades datagen connector destroyed)
#################################

run-base-demo: base-demo-validate
	@make --no-print-directory deploy-operator
	@make --no-print-directory wait-for-operator
	@make --no-print-directory deploy-zookeeper
	@make --no-print-directory wait-for-zookeeper
	@make --no-print-directory deploy-kafka
	@make --no-print-directory wait-for-kafka
	@make --no-print-directory deploy-client-secrets
	@make --no-print-directory deploy-schemaregistry
	@make --no-print-directory wait-for-schemaregistry
	@make --no-print-directory deploy-connect
	@make --no-print-directory wait-for-connect
ifeq ($(strip $(SKIP_CLICKS)),)
	@make --no-print-directory deploy-clicks-connector
endif
	@make --no-print-directory deploy-controlcenter
	@make --no-print-directory wait-for-controlcenter

destroy-base-demo: base-demo-validate
	@make --no-print-directory destroy-client-console
	@make --no-print-directory destroy-client-secrets
	@make --no-print-directory destroy-clicks-connector-deploy-job
	@make --no-print-directory destroy-controlcenter
	@make --no-print-directory wait-for-controlcenter-destruction
	@make --no-print-directory destroy-connect
	@make --no-print-directory wait-for-connect-destruction
	@make --no-print-directory destroy-schemaregistry
	@make --no-print-directory wait-for-schemaregistry-destruction
	@make --no-print-directory destroy-kafka
	@make --no-print-directory wait-for-kafka-destruction
	@make --no-print-directory destroy-zookeeper
	@make --no-print-directory wait-for-zookeeper-destruction
	@make --no-print-directory destroy-operator
	@make --no-print-directory wait-for-operator-destruction

run-replicator-demo:
	@make --no-print-directory run-base-demo SKIP_CLICKS=true SKIP_CLIENT_CONSOLE=true
	@make --no-print-directory deploy-stock-trades-connector
	@make --no-print-directory deploy-replicator
	@make --no-print-directory wait-for-replicator
	@make --no-print-directory deploy-replicator-demo-helm

destroy-replicator-demo:
	@make --no-print-directory destroy-replicator
	@make --no-print-directory wait-for-replicator-destruction
	@make --no-print-directory destroy-demo-helm
	@make --no-print-directory destroy-stock-trades-connector
	@make --no-print-directory destroy-base-demo

