
# Having an impl (implementation) file included allows us to reuse the functions inside Makefile-impl but not have to redefine common targets like 'demo' below ones across other demos
include Makefile-impl

demo: ## Run the Replicator aks->cc demo deploying a Confluent Platform into AKS and replicating to a cluster in Confluent Cloud
	@make --no-print-directory replicator-aks-cc-demo

destroy-demo: ## Destroy the Replicator Replicator aks->cc demo
	@make --no-print-directory replicator-aks-cc-destroy-demo

