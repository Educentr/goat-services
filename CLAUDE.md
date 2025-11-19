# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**goat-services** is a Go library that provides testcontainer runners for integration testing. It's designed to work with the GOAT testing framework but can be used standalone. The library wraps testcontainers-go to provide pre-configured service containers.

**Key Design Principle**: This package is intentionally dependency-free from GOAT to avoid circular dependencies. Service registration happens in user code, not in this library.

## Module Structure

Each service is implemented as a separate package with a consistent pattern:

- **Service packages**: `psql/`, `redis/`, `clickhouse/`, `s3/`, `minio/`, `jaeger/`, `victoriametrics/`, `xray/`, `singbox/`
- **Common utilities**: `common/` - Shared code including Docker proxy image substitution
- Each service package exports:
  - `Run(ctx context.Context, opts ...testcontainers.ContainerCustomizer) (*Env, error)` - Main entrypoint
  - `Env` struct - Contains container reference and connection details specific to that service

## Architecture Patterns

### Service Implementation Pattern

Every service follows this structure:

1. **Env struct**: Embeds `testcontainers.Container` and adds service-specific connection details (host, port, credentials, etc.)
2. **Run function**:
   - Accepts `testcontainers.ContainerCustomizer` options for flexibility
   - Sets default image via `common.DockerProxy()`
   - Applies custom options from caller
   - Sets up wait strategies if not provided
   - Starts the container
   - Populates and returns the `Env` struct
3. **Helper methods**: Some services provide client constructors (e.g., `psql.Env.SQL()`, `s3.Env.GetS3Client()`)

### Docker Proxy Support

The `common/` package provides image substitution via the `DOCKER_PROXY` environment variable:

- `DockerProxy(image)` - Returns proxied image path if `DOCKER_PROXY` is set
- `ImageSubstitutors()` - Returns testcontainers image substitutor slice
- Strips common prefixes (`docker.io/`, `ghcr.io/`) before joining with proxy URL

This allows running tests in environments with private registries without modifying code.

## Common Development Commands

### Build and Test
```bash
make build          # Verify compilation of all packages
make test           # Run all tests with race detection (5min timeout)
make test-short     # Run tests with -short flag (faster)
```

### Code Quality
```bash
make fmt            # Format code with gofmt
make vet            # Run go vet
make lint           # Run golangci-lint (installs if needed)
make check          # Run fmt, vet, and lint together
```

### Dependencies
```bash
make tidy           # Run go mod tidy
make deps           # Download dependencies
make update         # Update all dependencies
```

### Coverage
```bash
make coverage       # Generate coverage report (creates coverage.html)
```

### Verification
```bash
make verify         # Run tidy, build, and test in sequence
```

### Run a Single Test
```bash
go test -v -race ./psql -run TestSpecificFunction
```

## Working with Services

### Adding a New Service

1. Create a new package directory (e.g., `newservice/`)
2. Implement the standard pattern:
   ```go
   package newservice

   type Env struct {
       testcontainers.Container
       // Add connection details
   }

   func Run(ctx context.Context, opts ...testcontainers.ContainerCustomizer) (*Env, error) {
       // Implement following the pattern in psql/redis
   }
   ```
3. Use `common.DockerProxy()` for the default image
4. Use `common.ImageSubstitutors()` in container request
5. Set appropriate wait strategies
6. Update README.md with the new service

### Modifying Existing Services

- Service contracts (Env struct fields, Run signature) should remain stable
- Default images can be updated but consider backward compatibility
- Wait strategies should be conservative (long timeouts are better than flaky tests)
- Always test with `DOCKER_PROXY` set to ensure proxy support works

## Version and Releases

- Current version: v0.1.0
- This is a library meant to be imported via Go modules
- Use semantic versioning for releases
- Tag releases following `vX.Y.Z` format

## Testing Notes

- Tests may require Docker to be running
- Tests use testcontainers which pull images - first run will be slower
- Test timeout is set to 300s (5 minutes) to accommodate container startup
- Use `-short` flag to skip tests that require containers
