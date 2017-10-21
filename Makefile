.PHONY: install build test
BUMP_VERSION := $(GOPATH)/bin/bump_version
GODOCDOC := $(GOPATH)/bin/godocdoc
MEGACHECK := $(GOPATH)/bin/megacheck

BAZEL_VERSION := 0.7.0
BAZEL_DEB := bazel_$(BAZEL_VERSION)_amd64.deb

install-travis:
	wget "https://storage.googleapis.com/bazel-apt/pool/jdk1.8/b/bazel/$(BAZEL_DEB)"
	sudo dpkg --force-all -i $(BAZEL_DEB)
	sudo apt-get install moreutils -y

install:
	go get ./...
	go install ./...

build:
	bazel build //...

$(MEGACHECK):
	go get honnef.co/go/tools/cmd/megacheck

vet: $(MEGACHECK)
	$(MEGACHECK) ./...
	go vet ./...

test: vet
	bazel test --test_output=errors //...

race-test:
	bazel test --test_output=errors --features=race //...

ci:
	bazel test --noshow_progress \
		--noshow_loading_progress \
		--experimental_repository_cache="$$HOME/.bzrepos" \
		--test_output=errors \
		--features=race //...

$(BUMP_VERSION):
	go get github.com/Shyp/bump_version

release: test | $(BUMP_VERSION)
	$(BUMP_VERSION) minor types.go

docs: $(GODOCDOC)
	$(GODOCDOC)
