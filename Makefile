.PHONY: install build test
BUMP_VERSION := $(GOPATH)/bin/bump_version
GODOCDOC := $(GOPATH)/bin/godocdoc
MEGACHECK := $(GOPATH)/bin/megacheck

BAZEL_VERSION := 0.7.0
BAZEL_DEB := bazel_$(BAZEL_VERSION)_amd64.deb

install-travis:
	echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
	curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
	sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/bazel.list" \
		-o Dir::Etc::sourceparts="-" \
		-o APT::Get::List-Cleanup="0"
	sudo apt-get install openjdk-8-jdk bazel

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
	bazel test --noshow_progress --noshow_loading_progress --test_output=errors \
		--features=race //...

$(BUMP_VERSION):
	go get github.com/Shyp/bump_version

release: test | $(BUMP_VERSION)
	$(BUMP_VERSION) minor types.go

docs: $(GODOCDOC)
	$(GODOCDOC)
