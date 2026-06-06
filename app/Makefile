.PHONY: build run test fmt vet tidy lint clean

BINARY := quicknotes
ADDR   ?= :8080

build:
	go build -o $(BINARY) .

run: build
	ADDR=$(ADDR) ./$(BINARY)

docker-run:
	docker build -t quicknotes:local .
	docker run --rm -p 8080:8080 quicknotes:local

test:
	go test -race -count=1 ./...

fmt:
	gofmt -w .

vet:
	go vet ./...

tidy:
	go mod tidy

lint:
	golangci-lint run

clean:
	rm -f $(BINARY)
	rm -rf data/
