SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: all help

# Executable definitions docker|podman etc.
CONTAINER_BIN =docker

GIT_BRANCH=$(shell git branch --show-current)

# Target tags for pushing to
REGISTRY_HOST=ghcr.io
IMAGE_USERNAME=haisamido
IMAGE_NAME=nos3-base
IMAGE_TAG=${GIT_BRANCH}

IMAGE_URI=${REGISTRY_HOST}/${IMAGE_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}

#
DOCKERFILE=Dockerfile

GIT_TOKEN=${HOME}/.github.com/access_token

nos3-base-pull-prebuilt: ## pull pre-built nos3-base from remote
	${CONTAINER_BIN} pull ${IMAGE_URI}

nos3-base-build: ## build nos3-base from nos3-64 (Look at Dockerfile)
	$(call print_message,33,Building ${IMAGE_URI} via ${CONTAINER_BIN} ...)
	${CONTAINER_BIN} build --file ${DOCKERFILE} -t ${IMAGE_URI} .

nos3-base-push: | registry-login nos3-base-build ## push nos3-base (build runs first)
	@$(call print_message,33,Pushing ${IMAGE_URI} via ${CONTAINER_BIN} ...)
	${CONTAINER_BIN} push ${IMAGE_URI} 

registry-login: ## image registry-login
	@$(call print_message,33,Logging into ${REGISTRY_HOST} via ${CONTAINER_BIN} login ...)
	@cat ${GIT_TOKEN} | \
		${CONTAINER_BIN} login ${REGISTRY_HOST} -u ${IMAGE_USERNAME} --password-stdin

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

help: ## this help target
	@echo
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "# Makefile targets: make <TARGET>, e.g. make registry-login                                                                     "
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------------"
	@echo 
	@printf "\033[37m%-30s\033[0m %s\n" "#-target-----------------------description-----------------------------------------------"
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo 

print-%  : ; @echo $* = $($*)
