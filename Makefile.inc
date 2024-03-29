.ONESHELL:
SHA := $(shell git rev-parse --short=8 HEAD)
GITVERSION := $(shell git describe --long --all)
BUILDDATE := $(shell GO111MODULE=off go run ${COMMONDIR}/time.go)
VERSION := $(or ${VERSION},$(shell git describe --tags --exact-match 2> /dev/null || git symbolic-ref -q --short HEAD || git rev-parse --short HEAD))
CGO_ENABLED := $(or ${CGO_ENABLED},0)
GO := go
GOSRC = $(shell find . -not \( -path vendor -prune \) -type f -name '*.go')
SWAGGERSPEC := "swagger.json"
SWAGGERTARGET := "./"

PLATFORMS := linux/amd64 windows/amd64 darwin/amd64 darwin/arm64
temp = $(subst /, ,$@)
os = $(word 1, $(temp))
arch = $(word 2, $(temp))

export GO111MODULE := on
export CGO_ENABLED

ifeq ($(CGO_ENABLED),1)
	LINKMODE := -linkmode external -extldflags '-static -s -w'
endif

LINKMODE := $(LINKMODE) \
		 -X 'github.com/metal-stack/v.Version=$(VERSION)' \
		 -X 'github.com/metal-stack/v.Revision=$(GITVERSION)' \
		 -X 'github.com/metal-stack/v.GitSHA1=$(SHA)' \
		 -X 'github.com/metal-stack/v.BuildDate=$(BUILDDATE)'

.PHONY: all
all:: bin/$(BINARY);

bin/$(BINARY): test $(GOSRC)
	$(info CGO_ENABLED="$(CGO_ENABLED)")
	$(GO) build \
		-tags netgo \
		-ldflags \
		"$(LINKMODE)" \
		-o bin/$(BINARY) \
		$(MAINMODULE)

$(PLATFORMS): test $(GOSRC)
	$(info CGO_ENABLED="$(CGO_ENABLED)")
	GOOS=$(os) GOARCH=$(arch) \
	$(GO) build \
		-tags netgo \
		-ldflags \
		"$(LINKMODE)" \
		-o bin/$(BINARY)-$(os)-$(arch) \
		$(MAINMODULE)

.PHONY: platforms $(PLATFORMS)
platforms: $(PLATFORMS)

.PHONY: release
release:: ;

.PHONY: clean
clean::
	rm -rf bin/$(BINARY)*

.PHONY: up
up:
	docker-compose up --build

.PHONY: vendor
vendor:
	$(GO) mod vendor

.PHONY: tidy
tidy:
	$(GO) mod tidy

.PHONY: test
test:
	CGO_ENABLED=1 $(GO) test -cover ./...

.PHONY: test-ci
test-ci:
	CGO_ENABLED=1 $(GO) test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out | tail -n 1

.PHONY: test-integration
test-integration:
	CGO_ENABLED=1 $(GO) test -tags=integration -p 1 -cover ./...

.PHONY: swaggergenerate
swaggergenerate:
	echo $(SWAGGERSPEC)
ifeq ($(CI),true)
	echo "running swagger directly because in CI"
	GO111MODULE=off swagger generate client -f $(SWAGGERSPEC) -t $(SWAGGERTARGET) --skip-validation
else ifeq ($(IN_BUILDER),true)
	echo "running swagger directly because in Builder"
	GO111MODULE=off swagger generate client -f $(SWAGGERSPEC) -t $(SWAGGERTARGET) --skip-validation
else
	echo "running swagger from builder because not in CI or Builder"
	GO111MODULE=off docker run -it --user $$(id -u):$$(id -g) --rm -v ${PWD}:/work metalstack/builder swagger generate client -f $(SWAGGERSPEC) -t $(SWAGGERTARGET) --skip-validation
endif

# Static code analysis
.PHONY: check
check: test golint

.PHONY: golint
golint: golangci

.PHONY: golangcicheck
golangcicheck:
	@/bin/bash -c "type -P golangci-lint;" 2>/dev/null || (echo "golangci-lint is required but not available in current PATH. Install: https://github.com/golangci/golangci-lint#install"; exit 1)

.PHONY: golangci
golangci: golangcicheck
	golangci-lint run

.PHONY: gofmt
gofmt:
	$(GO) fmt ./...

.PHONY: moduleupdate
moduleupdate:
	go list -u -m -json all | docker run -i psampaz/go-mod-outdated -update -direct
