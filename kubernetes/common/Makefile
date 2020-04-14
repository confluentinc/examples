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

OPERATOR_DOWNLOAD_PATH := $(COMMON_MKFILE_DIR)cp/operator/confluent-operator-$(OPERATOR_BUNDLE_VERSION).tar.gz
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

get-helm-bundle: #_ Download the Confluent Operator Helm bundle locally in preparation for installation
ifeq (,$(wildcard $(OPERATOR_DOWNLOAD_PATH)))
	@mkdir -p $(dir $(OPERATOR_DOWNLOAD_PATH))
	@echo "downloading Confluent Operator to $(OPERATOR_DOWNLOAD_PATH)"
	@curl -s https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-$(OPERATOR_HELM_CHART_VERSION).tar.gz --output $(OPERATOR_DOWNLOAD_PATH)
endif
ifeq (,$(wildcard $(OPERATOR_PATH)))
	@mkdir -p $(dir $(OPERATOR_DOWNLOAD_PATH))$(OPERATOR_HELM_CHART_VERSION)/
	@echo "Extracting operator to $(OPERATOR_PATH)"
	@tar xf $(OPERATOR_DOWNLOAD_PATH) -C $(OPERATOR_PATH)
endif
	@$(call echo_pass,Confluent Platform Operator helm bundle ready at: $(OPERATOR_PATH))

init: check-dependencies get-helm-bundle #_ Initializes the common dependencies @echo
	@$(call echo_pass,common initialization complete)

