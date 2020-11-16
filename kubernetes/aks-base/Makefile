# Having an impl (implementation) file included allows us to reuse the functions inside Makefile-impl but not have to redefine common targets like 'demo' below ones across other demos
include Makefile-impl

demo: ## Run the base GKE demo, deploys Confluent Platform into current Kubernetes cluster
	@make --no-print-directory gke-base-demo

destroy-demo: ## Destroy the base GKE demo and all Confluent Platform components
	@make --no-print-directory gke-base-destroy-demo

