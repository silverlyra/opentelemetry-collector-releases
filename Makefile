GO=$(shell which go)
OTELCOL_BUILDER_VERSION ?= 0.42.0
OTELCOL_BUILDER_DIR ?= ${HOME}/bin
OTELCOL_BUILDER ?= ${OTELCOL_BUILDER_DIR}/ocb

YQ_VERSION ?= 4.11.1
YQ_DIR ?= ${OTELCOL_BUILDER_DIR}
YQ ?= ${YQ_DIR}/yq

DISTRIBUTIONS ?= "otelcol,otelcol-contrib"

ci: check build
check: ensure-goreleaser-up-to-date

build: go ocb
	@./scripts/build.sh -d "${DISTRIBUTIONS}" -b ${OTELCOL_BUILDER} -g ${GO}

generate: generate-sources generate-goreleaser

generate-goreleaser: yq envsubst
	@./scripts/generate-goreleaser-config.sh -d "${DISTRIBUTIONS}" -y "${YQ}"

generate-sources: go ocb
	@./scripts/build.sh -d "${DISTRIBUTIONS}" -s true -b ${OTELCOL_BUILDER} -g ${GO}

goreleaser-verify:
	@goreleaser release --snapshot --rm-dist

ensure-goreleaser-up-to-date: generate-goreleaser
	@git diff -s --exit-code .goreleaser.yaml || (echo "Build failed: The goreleaser templates have changed but the .goreleaser.yaml hasn't. Run 'make generate-goreleaser' and update your PR." && exit 1)

ocb:
ifeq (, $(shell command -v ocb 2>/dev/null))
	@{ \
	set -e ;\
	os=$$(uname | tr A-Z a-z) ;\
	machine=$$(uname -m) ;\
	[ "$${machine}" != x86 ] || machine=386 ;\
	[ "$${machine}" != x86_64 ] || machine=amd64 ;\
	echo "Installing ocb ($${os}/$${machine}) at $(OTELCOL_BUILDER_DIR)";\
	mkdir -p $(OTELCOL_BUILDER_DIR) ;\
	curl -sLo $(OTELCOL_BUILDER) "https://github.com/open-telemetry/opentelemetry-collector/releases/download/v$(OTELCOL_BUILDER_VERSION)/ocb_$(OTELCOL_BUILDER_VERSION)_$${os}_$${machine}" ;\
	chmod +x $(OTELCOL_BUILDER) ;\
	}
else
OTELCOL_BUILDER=$(shell command -v ocb)
endif

go:
ifeq (, $(shell command -v go 2>/dev/null))
$(error go command not found. Please install golang. https://go.dev/doc/install )
endif

envsubst:
ifeq (, $(shell command -v envsubst 2>/dev/null))
$(error envsubst command not found. Please install gettext. )
endif

yq:
ifeq (, $(shell command -v yq 2>/dev/null ))
	@{ \
	set -e ;\
	os=$$(uname | tr A-Z a-z) ;\
	machine=$$(uname -m) ;\
	[ "$${machine}" != x86 ] || machine=386 ;\
	[ "$${machine}" != x86_64 ] || machine=amd64 ;\
	echo "Installing yq ($${os}/$${machine}) at $(YQ_DIR)";\
	mkdir -p $(YQ_DIR) ;\
	curl -sLo $(YQ) https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_$${os}_$${machine} ;\
	chmod +x $(YQ) ;\
	}
else
YQ=$(shell which yq)
endif
