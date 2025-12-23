package kafka

import (
	"context"
	"strings"

	testcontainers "github.com/testcontainers/testcontainers-go"
	kafka "github.com/testcontainers/testcontainers-go/modules/kafka"

	common "github.com/Educentr/goat-services/common"
)

type (
	Env struct {
		testcontainers.Container
		Brokers     string
		BrokersHost string
		BrokersPort string
	}
)

var (
	defaultImage = common.DockerProxy("confluentinc/confluent-local:7.6.0")
)

func Run(ctx context.Context, opts ...testcontainers.ContainerCustomizer) (*Env, error) {
	req := testcontainers.GenericContainerRequest{
		ContainerRequest: testcontainers.ContainerRequest{
			ImageSubstitutors: common.ImageSubstitutors(),
		},
	}

	for _, e := range opts {
		_ = e.Customize(&req) //nolint:errcheck
	}

	image := defaultImage
	if req.Image != "" {
		image = req.Image
	}

	// Note: kafka.Run() from testcontainers-go/modules/kafka has its own
	// internal waiting logic. We don't override WaitingFor to avoid conflicts
	// with the multi-port confluent-local image (8082 REST proxy is slow to start).

	container, err := kafka.Run(ctx, image, opts...)
	if err != nil {
		return nil, err
	}

	brokers, err := container.Brokers(ctx)
	if err != nil {
		return nil, err
	}

	var env Env
	env.Container = container
	env.Brokers = strings.Join(brokers, ",")

	if len(brokers) > 0 {
		parts := strings.Split(brokers[0], ":")
		if len(parts) == 2 {
			env.BrokersHost = parts[0]
			env.BrokersPort = parts[1]
		}
	}

	return &env, nil
}
