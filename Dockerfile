FROM golang:1.13-buster as builder

ENV COMMONDIR=/common \
    VERSION_GO_SWAGGER=0.19.0 \
    VERSION_GOLANGCI_LINT=1.23.2 \
    PROTOC_VERSION=3.11.3

RUN apt-get update \
 && apt-get -y install make git libpcap-dev unzip \
 && curl -fsSL https://github.com/go-swagger/go-swagger/releases/download/v${VERSION_GO_SWAGGER}/swagger_linux_amd64 > /usr/bin/swagger \
 && chmod +x /usr/bin/swagger

RUN curl -fsSLO https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip \
 && unzip "protoc-$PROTOC_VERSION-linux-x86_64.zip" -d protoc \
 && mv protoc/bin/* /usr/local/bin/ \
 && mv protoc/include/* /usr/local/include/ \
 && go get -u github.com/golang/protobuf/protoc-gen-go

WORKDIR /common
COPY Makefile.inc /common/Makefile.inc
COPY time.go /common/time.go

WORKDIR /work

# Install dependencies
ONBUILD COPY go.mod .
ONBUILD RUN go mod download

# Build
ONBUILD COPY . .
ONBUILD RUN make release
