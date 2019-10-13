
THIS_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MKFILE_DIR := $(dir $(THIS_MKFILE_PATH))

include $(THIS_MKFILE_DIR)../common/Makefile

ccloud-check-dependencies: check-dependencies
	@$(call check-dependency,ccloud)

ccloud-base-validate: ccloud-check-dependencies check-dependencies
	@echo
	@$(call echo_pass,ccloud-base demo validation complete)
