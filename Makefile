.PHONY: all release-dirs release-build release-copy release-check release

DEPS := $(wildcard *.go)
BUILD_IMAGE := "app-build"
PRODUCTION_IMAGE := "app"
PRODUCTION_NAME := "app-production"
DEPLOY_ACCOUNT := "ehime"
export PROJECT_PATH = /go/src/github.com/ehime/docker-simple

DIST := dist
EXECUTABLE := app

TARGETS ?= linux darwin windows
PACKAGES ?= $(shell go list ./... | grep -v /vendor/)
SOURCES ?= $(shell find . -name "*.go" -type f)
TAGS ?=
LDFLAGS += -X 'main.Version=$(VERSION)'

ifneq ($(shell uname), Darwin)
	EXTLDFLAGS = -extldflags "-static" $(null)
else
	EXTLDFLAGS =
endif

ifneq ($(DRONE_TAG),)
	VERSION ?= $(DRONE_TAG)
else
	VERSION ?= $(shell git describe --tags --always || git rev-parse --short HEAD)
endif

all: build server

install:
	glide install

update:
	glide update

build:
	docker build -t $(BUILD_IMAGE) -f Dockerfile.build .
	docker run $(BUILD_IMAGE) > build.tar.gz
	docker build -t $(PRODUCTION_IMAGE) -f Dockerfile.dist .

server:
	-docker rm -f app-production
	-docker run -d -p 8088:8000 --name $(PRODUCTION_NAME) $(PRODUCTION_IMAGE)

docker_deploy:
ifeq ($(tag),)
	@echo "Usage: make $@ tag=<tag>"
	@exit 1
endif
	docker tag $(PRODUCTION_IMAGE):latest $(DEPLOY_ACCOUNT)/$(PRODUCTION_IMAGE):$(tag)
	docker push $(DEPLOY_ACCOUNT)/$(PRODUCTION_IMAGE):$(tag)

app: ${DEPS}
	GO15VENDOREXPERIMENT=1 go build

test:
	go test -v -cover

docker_compose_test: dist-clean
	docker-compose -f docker/docker-compose.yml config
	docker-compose -f docker/docker-compose.yml run golang-app-testing
	docker-compose -f docker/docker-compose.yml down

docker_test: dist-clean
	docker run --rm \
		-v $(PWD):$(PROJECT_PATH) \
		-w=$(PROJECT_PATH) \
		appleboy/golang-testing \
		sh -c "make install && coverage all"

release: release-dirs release-build release-copy release-check

release-dirs:
	mkdir -p $(DIST)/binaries $(DIST)/release

release-build:
	@which gox > /dev/null; if [ $$? -ne 0 ]; then \
		go get -u github.com/mitchellh/gox; \
	fi
	gox -os="$(TARGETS)" -arch="amd64 386" -tags="$(TAGS)" -ldflags="$(EXTLDFLAGS)-s -w $(LDFLAGS)" -output="$(DIST)/binaries/$(EXECUTABLE)-$(VERSION)-{{.OS}}-{{.Arch}}"

release-copy:
	$(foreach file,$(wildcard $(DIST)/binaries/$(EXECUTABLE)-*),cp $(file) $(DIST)/release/$(notdir $(file));)

release-check:
	cd $(DIST)/release; $(foreach file,$(wildcard $(DIST)/release/$(EXECUTABLE)-*),sha256sum $(notdir $(file)) > $(notdir $(file)).sha256;)

clean:
	-rm -rf .cover
	-rm -rf build.tar.gz

dist-clean: clean
	-docker rmi -f $(BUILD_IMAGE)
	-docker rm -f $(PRODUCTION_NAME)
	-docker rmi -f $(PRODUCTION_IMAGE)
	-docker-compose -f docker/docker-compose.yml down
