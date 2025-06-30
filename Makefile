SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := help

# excutable definitions
INSTALLER_BIN =brew
CONTAINER_BIN =docker
YQ_BIN        =yq -r 

.PHONY: all help

# Target tags for pushing to
REGISTRY_HOST=ghcr.io
IMAGE_USERNAME=haisamido
IMAGE_NAME=nos3-base
IMAGE_TAG=dev
DOCKERFILE=Dockerfile

IMAGE_URI=${REGISTRY_HOST}/${IMAGE_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}

nos3-base-build: ## build nos3-base from nos3-64 (Look at Dockerfile)
	$(call print_message,33,Building ${IMAGE_URI} ...)
	${CONTAINER_BIN} build --file ${DOCKERFILE} -t ${IMAGE_URI} .

nos3-base-push: nos3-base-build ## push nos3-base (build runs first)
	${CONTAINER_BIN} push ${IMAGE_URI} 

#------------------------------------------------------------------------------
define print_header
	@printf '%*s\n' "$(TERM_WIDTH)" '' | tr ' ' '-'
	@printf '%-*s\n' "$(TERM_WIDTH)" "$(1)"
	@printf '%*s\n' "$(TERM_WIDTH)" '' | tr ' ' '-'
endef

define print_message
	@printf "\033[$(1)m$(2)\033[0m\n"
endef
#------------------------------------------------------------------------------

#---
RESET  = \033[0m
PURPLE = \033[0;35m
GREEN  = \033[0;32m
LINE   = $(PURPLE)----------------------------------------------------------------------------------------$(RESET)

help:
	@echo
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "# Makefile targets                                                                       "
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------------"
	@echo 
	@printf "\033[37m%-30s\033[0m %s\n" "#-target-----------------------description-----------------------------------------------"
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo 

print-%  : ; @echo $* = $($*)