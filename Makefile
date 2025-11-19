# GOAT Services Makefile

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the module (verify compilation)
	@echo "Building goat-services..."
	go build -v ./...
	@echo "Build successful!"

.PHONY: test
test: ## Run tests
	@echo "Running tests..."
	go test -v -race -timeout=300s ./...

.PHONY: test-short
test-short: ## Run tests with short flag
	@echo "Running short tests..."
	go test -v -short -race ./...

.PHONY: coverage
coverage: ## Generate test coverage report
	@echo "Generating coverage report..."
	go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

.PHONY: tidy
tidy: ## Run go mod tidy
	@echo "Running go mod tidy..."
	go mod tidy
	@echo "Dependencies updated!"

.PHONY: fmt
fmt: ## Format code with gofmt
	@echo "Formatting code..."
	gofmt -s -w .
	@echo "Code formatted!"

.PHONY: vet
vet: ## Run go vet
	@echo "Running go vet..."
	go vet ./...
	@echo "Vet passed!"

.PHONY: lint
lint: ## Run golangci-lint
	@echo "Running golangci-lint..."
	@if ! command -v golangci-lint &> /dev/null; then \
		echo "golangci-lint not found. Installing..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.0; \
	fi
	golangci-lint run --timeout=5m

.PHONY: install-lint
install-lint: ## Install golangci-lint
	@echo "Installing golangci-lint v1.62.0..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.0
	@echo "golangci-lint installed!"

.PHONY: check
check: fmt vet lint ## Run all checks (fmt, vet, lint)
	@echo "All checks passed!"

.PHONY: clean
clean: ## Clean build artifacts and coverage files
	@echo "Cleaning..."
	rm -f coverage.out coverage.html
	go clean -cache -testcache -modcache
	@echo "Cleaned!"

.PHONY: deps
deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download
	@echo "Dependencies downloaded!"

.PHONY: verify
verify: tidy build test ## Verify module (tidy, build, test)
	@echo "Module verified!"

.PHONY: update
update: ## Update dependencies
	@echo "Updating dependencies..."
	go get -u ./...
	go mod tidy
	@echo "Dependencies updated!"

.DEFAULT_GOAL := help
