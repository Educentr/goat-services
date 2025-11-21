# GOAT Services

Service container runners for the GOAT (Go Application Testing) framework.

## Overview

This package provides ready-to-use service container runners built on [testcontainers-go](https://github.com/testcontainers/testcontainers-go). It's designed to work seamlessly with the [GOAT testing framework](https://github.com/Educentr/goat), but can also be used standalone.

**Important:** This package does NOT depend on GOAT to avoid circular dependencies. Service registration with GOAT is done in user code.

## Available Services

- **PostgreSQL** (`psql`) - PostgreSQL database
- **Redis** (`redis`) - Redis cache
- **ClickHouse** (`clickhouse`) - ClickHouse analytics database
- **S3** (`s3`) - S3-compatible storage via LocalStack
- **MinIO** (`minio`) - MinIO object storage
- **Jaeger** (`jaeger`) - Jaeger distributed tracing
- **VictoriaMetrics** (`victoriametrics`) - VictoriaMetrics time-series database
- **Xray** (`xray`) - Xray proxy server
- **Singbox** (`singbox`) - Singbox VPN proxy server

## Installation

```bash
go get github.com/Educentr/goat-services@latest
```

## Usage

### With GOAT Framework (Recommended)

Register the services you need in your test setup:

```go
package myapp_test

import (
    "testing"

    gtt "github.com/Educentr/goat"
    "github.com/Educentr/goat/services"

    "github.com/Educentr/goat-services/psql"
    "github.com/Educentr/goat-services/redis"
)

func init() {
    // Register services from goat-services (type-safe, no wrapper needed)
    services.MustRegisterServiceFuncTyped("postgres", psql.Run)
    services.MustRegisterServiceFuncTyped("redis", redis.Run)
}

func TestMain(m *testing.M) {
    // Create manager with registered services
    servicesMap := services.NewServicesMap("postgres", "redis")

    manager := services.NewManager(servicesMap, services.DefaultManagerConfig())

    // Create environment
    env := gtt.NewEnv(gtt.EnvConfig{}, manager)

    gtt.CallMain(env, m)
}

func TestExample(t *testing.T) {
    // Access services with type-safe getters
    pg, err := services.GetTyped[*psql.Env](env.Manager(), "postgres")
    require.NoError(t, err)

    // Use connection details
    connStr := fmt.Sprintf("host=%s port=%s", pg.DBHost, pg.DBPort)
}
```

### Register All Services at Once

```go
import (
    "github.com/Educentr/goat/services"

    "github.com/Educentr/goat-services/psql"
    "github.com/Educentr/goat-services/redis"
    "github.com/Educentr/goat-services/clickhouse"
    "github.com/Educentr/goat-services/s3"
    "github.com/Educentr/goat-services/minio"
    "github.com/Educentr/goat-services/jaeger"
    "github.com/Educentr/goat-services/victoriametrics"
    "github.com/Educentr/goat-services/xray"
    "github.com/Educentr/goat-services/singbox"
)

func init() {
    // Register all available services (type-safe)
    services.MustRegisterServiceFuncTyped("postgres", psql.Run)
    services.MustRegisterServiceFuncTyped("redis", redis.Run)
    services.MustRegisterServiceFuncTyped("clickhouse", clickhouse.Run)
    services.MustRegisterServiceFuncTyped("s3", s3.Run)
    services.MustRegisterServiceFuncTyped("minio", minio.Run)
    services.MustRegisterServiceFuncTyped("jaeger", jaeger.Run)
    services.MustRegisterServiceFuncTyped("victoriametrics", victoriametrics.Run)
    services.MustRegisterServiceFuncTyped("xray", xray.Run)
    services.MustRegisterServiceFuncTyped("singbox", singbox.Run)
}
```

### Using Builder Pattern

```go
import (
    "github.com/Educentr/goat/services"
    testcontainers "github.com/testcontainers/testcontainers-go"

    "github.com/Educentr/goat-services/psql"
    "github.com/Educentr/goat-services/redis"
)

func init() {
    services.MustRegisterServiceFuncTyped("postgres", psql.Run)
    services.MustRegisterServiceFuncTyped("redis", redis.Run)
}

func TestMain(m *testing.M) {
    // Use builder for advanced configuration
    manager := services.NewBuilder().
        WithService("postgres", testcontainers.WithImage("postgres:15")).
        WithService("redis", testcontainers.WithImage("redis:7")).
        Build()

    env := gtt.NewEnv(gtt.EnvConfig{}, manager)
    gtt.CallMain(env, m)
}
```

### Advanced Configuration with Fluent API

```go
import (
    "github.com/Educentr/goat/services"
    testcontainers "github.com/testcontainers/testcontainers-go"

    "github.com/Educentr/goat-services/psql"
    "github.com/Educentr/goat-services/redis"
    "github.com/Educentr/goat-services/clickhouse"
)

func init() {
    services.MustRegisterServiceFuncTyped("postgres", psql.Run)
    services.MustRegisterServiceFuncTyped("redis", redis.Run)
    services.MustRegisterServiceFuncTyped("clickhouse", clickhouse.Run)
}

func TestMain(m *testing.M) {
    // Configure services with priorities, options, and dependencies
    servicesMap := services.NewServicesMap("postgres", "redis", "clickhouse").
        WithPriority("postgres", 1).
        WithPriority("redis", 2).
        WithPriority("clickhouse", 3).
        WithOptions("postgres",
            testcontainers.WithImage("postgres:15"),
            testcontainers.WithEnv(map[string]string{
                "POSTGRES_MAX_CONNECTIONS": "200",
            }),
        ).
        WithDependencies("clickhouse", "postgres")

    manager := services.NewManager(servicesMap, services.DefaultManagerConfig())
    env := gtt.NewEnv(gtt.EnvConfig{}, manager)
    gtt.CallMain(env, m)
}
```

### Standalone Usage

Each service can be used independently without GOAT:

```go
package main

import (
    "context"

    "github.com/Educentr/goat-services/psql"
)

func main() {
    ctx := context.Background()

    // Run PostgreSQL container
    pg, err := psql.Run(ctx)
    if err != nil {
        panic(err)
    }
    defer pg.Terminate(ctx)

    // Use connection details
    println("Postgres is running at:", pg.DBHost, pg.DBPort)
}
```

### Custom Configuration

All services accept `testcontainers.ContainerCustomizer` options:

```go
import testcontainers "github.com/testcontainers/testcontainers-go"

// Custom image and environment
pg, err := psql.Run(ctx,
    testcontainers.WithImage("postgres:15"),
    testcontainers.WithEnv(map[string]string{
        "POSTGRES_MAX_CONNECTIONS": "200",
    }),
)
```

## Docker Image Proxy

All services support Docker image proxying via the `DOCKER_PROXY` environment variable:

```bash
export DOCKER_PROXY=your-registry.example.com
```

Images will be pulled from `your-registry.example.com/postgres:latest` instead of `docker.io/postgres:latest`.

## Module Structure

```
goat-services/
├── psql/           - PostgreSQL service
├── redis/          - Redis service
├── clickhouse/     - ClickHouse service
├── s3/             - S3/LocalStack service
├── minio/          - MinIO service
├── jaeger/         - Jaeger service
├── victoriametrics/ - VictoriaMetrics service
├── xray/           - Xray service
├── singbox/        - Singbox VPN service
├── common/         - Shared utilities
└── go.mod
```

## Why No Circular Dependency?

This package is designed to be dependency-free from GOAT. To use these services with GOAT:

1. Import both `goat` and `goat-services` in your test code
2. Register services using `services.RegisterServiceFunc()`
3. GOAT does not import goat-services
4. goat-services does not import goat

This keeps the dependency graph clean: `your-test-code` → `goat` + `goat-services` (no circular deps).

## License

MIT

## Related Projects

- [GOAT Framework](https://github.com/Educentr/goat) - Integration testing framework for Go
- [testcontainers-go](https://github.com/testcontainers/testcontainers-go) - Underlying container management

## Version

v0.3.0

## Changelog

### v0.3.0
- Updated examples to use new GOAT v0.4.0 API with `MustRegisterServiceFuncTyped`
- Simplified registration: no more manual type wrappers needed

### v0.2.0
- Updated examples to use new GOAT v0.3.0 API
- Removed deprecated `Enable()` and `WithServiceSimple()` usage
- Added examples of fluent configuration API

### v0.1.0
- Initial release with support for PostgreSQL, Redis, ClickHouse, S3, MinIO, Jaeger, VictoriaMetrics, Xray, and Singbox
