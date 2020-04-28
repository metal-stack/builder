FROM golang:1.14.2-buster as builder

ENV COMMONDIR=/common \
    VERSION_GO_SWAGGER=0.19.0 \
    VERSION_GOLANGCI_LINT=1.25.1 \
    PROTOC_VERSION=3.11.4

# swagger and required packages
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        apt-transport-https \
        apt-utils \
        make \
        git \
        libpcap-dev \
        python-pip \
        python-setuptools \
        software-properties-common \
        unzip \
 && curl -fsSL https://github.com/go-swagger/go-swagger/releases/download/v${VERSION_GO_SWAGGER}/swagger_linux_amd64 > /usr/bin/swagger \
 && chmod +x /usr/bin/swagger

# protoc
RUN curl -fsSLO https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip \
 && unzip "protoc-$PROTOC_VERSION-linux-x86_64.zip" -d protoc \
 && chmod -R o+rx protoc/ \
 && mv protoc/bin/* /usr/local/bin/ \
 && mv protoc/include/* /usr/local/include/ \
 && go get -u github.com/golang/protobuf/protoc-gen-go

# docker-make
RUN curl -fLsS https://download.docker.com/linux/debian/gpg > docker.key \
 && apt-key add docker.key \
 && rm -f docker.key \
 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" \
 && apt-get update \
 && apt-get install --yes --no-install-recommends docker-ce \
 && pip install pip --upgrade \
 && pip install --extra-index-url https://pypi.fi-ts.io docker-make \
 && mkdir -p /etc/docker-make
COPY registries.yaml /etc/docker-make/registries.yaml

# mc
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc \
 && chmod +x mc \
 && mv mc /bin/mc

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
