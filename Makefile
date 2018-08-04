.PHONY: install build test
BUMP_VERSION := $(GOPATH)/bin/bump_version
GODOCDOC := $(GOPATH)/bin/godocdoc
MEGACHECK := $(GOPATH)/bin/megacheck

install:
	go get ./...
	go install ./...

$(MEGACHECK):
	go get honnef.co/go/tools/cmd/megacheck

vet: $(MEGACHECK)
	$(MEGACHECK) ./...
	go vet ./...

test: vet
	go test ./...

race-test:
	go test -race ./...

$(BUMP_VERSION):
	go get github.com/kevinburke/bump_version

release: test | $(BUMP_VERSION)
	$(BUMP_VERSION) minor types.go

docs: $(GODOCDOC)
	$(GODOCDOC)
