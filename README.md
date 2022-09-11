# Explore Buildx

This repository explores building Docker images via [Docker Buildx](https://docs.docker.com/build/buildx/), and is forked from https://github.com/snyk-labs/nodejs-docker-best-practices

Specifically, we explore the cache options available in Buildx:

- [inline](#inline-cache)
- [local](#local-cache)
- [registry](#registry-cache)

We run the same commands below on a CircleCI pipeline.
See [.circleci/config.yml](.circleci/config.yml).

You can explore [the built images here](#output).

## Prerequisites

It is recommended to set up a builder instance for Docker Buildx operations.

As such, we want to do the following before building any image:

1. Set up [a Docker context](https://docs.docker.com/engine/reference/commandline/context_create/)
2. Create [a Docker builder instance using the context](https://docs.docker.com/engine/reference/commandline/buildx_create/) (in this case, using a `docker-container` [driver](https://docs.docker.com/engine/reference/commandline/buildx_create/#driver))

## Inline Cache

Inline cache is likely the most common or popular strategy for many developers.

This saves and retrieves the layers' cache within the published image's repository itself (e.g., in Docker Hub).

```shell
docker buildx build --progress=plain \
    --tag="docker.io/kelvintaywl/snyk-node:latest" \
    --cache-from="type=registry,ref=docker.io/kelvintaywl/snyk-node:latest" \
    --cache-to=type=inline \
    # --output=type=registry is the same as --push
    --output=type=registry \
    --file=Dockerfile \
    .
```

## Local Cache

Local cache saves the layers' cache to a location on the Docker client.

This option may not be ideal in CI, since builds are ephemeral.
However, depending on the CI providers, this option is possible if you can attach and save the cached layers to an external store between builds.

In CircleCI, we can achieve this via [the cache feature](https://circleci.com/docs/persist-data#caching), for example.

```shell
docker buildx build --progress=plain \
    --tag="docker.io/kelvintaywl/snyk-node-multistage:local-cache-1234567" \
    --cache-from="type=local,src=/tmp/dockercache" \
    # mode=max saves all layers from all stages
    --cache-to="type=local,mode=max,dest=/tmp/dockercache" \
    --output=type=docker \
    --file=Dockerfile.multistage \
    .

# we should see the image above listed
docker image ls

docker image push docker.io/kelvintaywl/snyk-node-multistage:local-cache-1234567"
```

## Registry Cache

Registry cache saves the layers' cache to a Docker image registry.

Think of it as using Docker Hub as a cache destination itself for example.

This is very similar to Inline cache strategy.
However, Inline cache will save the cache within the same repo on your Docker registry.
For Registry cache, this can be a completely different repo or even a different Docker registry (e.g., Quay, AWS ECR, etc).


```shell
docker buildx build --progress=plain \
    --tag="docker.io/kelvintaywl/snyk-node-multistage:registry-cache-1234567" \
    # saves the cache in the same repo space,
    # BUT we use the `cache` tag to avoid conflicts
    --cache-from="type=registry,ref=docker.io/kelvintaywl/snyk-node-multistage:cache" \
    # mode=max saves all layers from all stages
    --cache-to="type=registry,mode=max,ref=docker.io/kelvintaywl/snyk-node-multistage:cache" \
    --output=type=docker \
    --file=Dockerfile.multistage \
    .

# we should see the image above listed
docker image ls

docker image push docker.io/kelvintaywl/snyk-node-multistage:registry-cache-1234567"
```

## Output

In the commands above, we have published the images to the following:

| Strategy | Dockerfile | Repository | Tag |
| --- | --- |  --- | --- |
| inline | Dockerfile | [docker.io/kelvintaywl/snyk-node](https://hub.docker.com/repository/docker/kelvintaywl/snyk-node) | latest |
| local | Dockerfile.multistage | [docker.io/kelvintaywl/snyk-node-multistage](https://hub.docker.com/repository/docker/kelvintaywl/snyk-node-multistage) | local-cache-* |
| registry | Dockerfile.multistage | [docker.io/kelvintaywl/snyk-node-multistage](https://hub.docker.com/repository/docker/kelvintaywl/snyk-node-multistage) | registry-cache-* |


We can also test the built images:

```console
$ docker container run -p 3000:3000 --detach docker.io/kelvintaywl/snyk-node:latest

$ curl -s http://localhost:3000 | jq .
{
  "hello": "world"
}
```
