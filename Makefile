SHELL := /bin/bash
.SHELLFLAGS = -e -c
.DEFAULT_GOAL := help
.ONESHELL:
.SILENT:

.PHONY: $(MAKECMDGOALS)

YAML_FILES := $(shell find . -not -path "*/node_modules/*" -not -path "**/helm-templates/**" -not -path "**/cluster-nodes/**/templates/**" -type f -name '*.yml')
JS_DIRS := $(shell find . -not -path "*/node_modules/*" -not -path "*/.*" -type f -name 'package.json' -exec dirname {} \;)

JS_EXEC ?= bun
JS_INSTALL ?= install

UNAME_S := $(shell uname -s)

.PHONY: $(MAKECMDGOALS)

run: ## Run the frontend
	bun run dev

fix: fix/js fix/md fix/yaml ## [all] Fix format and lint errors

format: format/js format/md format/python format/yaml ## [all] Format

fix/js: format/js fix/js/eslint ## [js] Fix
format/js:
	echo "[fix/format/js] begin"
	if ! [[ -d ./node_modules ]]; then \
		$(JS_EXEC) $(JS_INSTALL); \
	fi
	$(JS_EXEC) run fix:prettier
	echo "[fix/format/js] end"
fix/js/eslint:
	echo "[fix/js/eslint] begin"
	for dir in $(JS_DIRS); do \
		cd $${dir}; \
		if ! [[ -d ./node_modules ]]; then \
			$(JS_EXEC) $(JS_INSTALL); \
		fi; \
		$(JS_EXEC) run build; \
		$(JS_EXEC) run fix:eslint; \
		cd -; \
	done
	echo "[fix/js/eslint] end"

fix/md: format/md ## [md] Fix

format/md:
	echo "[fix/format/md] begin"
	if ! [[ -d ./node_modules ]]; then \
		$(JS_EXEC) $(JS_INSTALL); \
	fi
	$(JS_EXEC) run fix:md
	echo "[fix/format/md] end"

fix/yaml: format/yaml ## [yaml] Format
format/yaml:
	echo "[fix/format/yaml] begin"
	for file in $(YAML_FILES); do \
		yq -i -P $${file}; \
	done
	echo "[fix/format/yaml] end"

lint: lint/go lint/md lint/js lint/python lint/yaml ## [all] Lint
lint/md: ## [all] Lint MD
	if ! [[ -d ./node_modules ]]; then \
		$(JS_EXEC) $(JS_INSTALL); \
	fi
	$(JS_EXEC) run lint:md

lint/js: lint/js/format lint/js/eslint ## [all] Lint JS
	if ! [[ -d ./node_modules ]]; then \
		$(JS_EXEC) $(JS_INSTALL); \
	fi
	$(JS_EXEC) run lint
lint/js/eslint:
	echo "[lint/eslint/js] begin"
	for dir in $(JS_DIRS); do \
		cd $${dir}; \
		if ! [[ -d ./node_modules ]]; then \
			$(JS_EXEC) $(JS_INSTALL); \
		fi; \
		$(JS_EXEC) run build; \
		$(JS_EXEC) run lint:eslint; \
		cd -; \
	done
	echo "[lint/check/js] end"
lint/js/format:
	echo "[lint/format/js] begin"
	if ! [[ -d ./node_modules ]]; then \
		$(JS_EXEC) $(JS_INSTALL); \
	fi
	$(JS_EXEC) run lint:prettier
	echo "[lint/format/js] end"

lint/yaml: lint/yaml/format ## [all] Lint YAML
lint/yaml/format:
	echo "[lint/format/yaml] begin"
	for file in $(YAML_FILES); do \
		yq -P $${file} > /dev/null; \
	done
	echo "[lint/format/yaml] end"

setup: setup/js

setup/js : ## [js] Setup JS
	if command -v bun &> /dev/null; then \
		exit 0; \
	fi
	curl -fsSL https://bun.sh/install | bash
	bun install

.PHONY: help
help: ## Displays help info
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
