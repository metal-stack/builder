FROM golang:1.20.5-buster as builder

ENV COMMONDIR=/common \
    IN_BUILDER=true \
    VERSION_GO_SWAGGER=0.30.5 \
    VERSION_GOLANGCI_LINT=1.53.2 \
    VERSION_JQ=1.6 \
    VERSION_PROTOC=3.20.1 \
    VERSION_DOCKER_MAKE=v0.3.6 \
    XDG_CACHE_HOME=/tmp/.cache

# golangci-lint
RUN curl -fsSLO https://github.com/golangci/golangci-lint/releases/download/v${VERSION_GOLANGCI_LINT}/golangci-lint-${VERSION_GOLANGCI_LINT}-linux-amd64.tar.gz \
 && tar --extract --file golangci-lint-${VERSION_GOLANGCI_LINT}-linux-amd64.tar.gz \
 && chmod +x golangci-lint-${VERSION_GOLANGCI_LINT}-linux-amd64/golangci-lint \
 && mv golangci-lint-${VERSION_GOLANGCI_LINT}-linux-amd64/golangci-lint /usr/bin \
 && rm -f golangci-lint-${VERSION_GOLANGCI_LINT}-linux-amd64.tar.gz

# swagger and required packages
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
    apt-transport-https \
    apt-utils \
    make \
    git \
    libpcap-dev \
    software-properties-common \
    unzip \
 && curl -fsSL https://github.com/go-swagger/go-swagger/releases/download/v${VERSION_GO_SWAGGER}/swagger_linux_amd64 > /usr/bin/swagger \
 && chmod +x /usr/bin/swagger

# jq
RUN curl -LSs https://github.com/stedolan/jq/releases/download/jq-${VERSION_JQ}/jq-linux64 -o /usr/local/bin/jq \
 && chmod +x /usr/local/bin/jq

# protoc
RUN curl -fsSLO https://github.com/protocolbuffers/protobuf/releases/download/v${VERSION_PROTOC}/protoc-${VERSION_PROTOC}-linux-x86_64.zip \
 && unzip "protoc-${VERSION_PROTOC}-linux-x86_64.zip" -d protoc \
 && chmod -R o+rx protoc/ \
 && mv protoc/bin/* /usr/local/bin/ \
 && mv protoc/include/* /usr/local/include/ \
 && go install github.com/golang/protobuf/protoc-gen-go@latest

# docker-make
RUN curl -fLsS https://download.docker.com/linux/debian/gpg > docker.key \
 && apt-key add docker.key \
 && rm -f docker.key \
 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" \
 && apt-get update \
 && apt-get install --yes --no-install-recommends docker-ce \
 && curl -fLsS https://github.com/fi-ts/docker-make/releases/download/${VERSION_DOCKER_MAKE}/docker-make-linux-amd64 > /usr/bin/docker-make \
 && chmod +x /usr/bin/docker-make \
 && mkdir -p /etc/docker-make
COPY registries.yaml /etc/docker-make/registries.yaml

WORKDIR /common
COPY Makefile.inc /common/Makefile.inc
COPY time.go /common/time.go

WORKDIR /work

# Install dependencies
ONBUILD COPY go.mod .
ONBUILD RUN go mod download

# Build
ONBUILD COPY . .
ONBUILD ARG CI
ONBUILD RUN make release
