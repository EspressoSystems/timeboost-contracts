# Docker Setup

Run everything in Docker containers.

All commands need `cd docker` first.

## Setup

```bash
cd docker
cp docker.env.example docker.env
./build-docker-images.sh
```

## Usage

```bash
cd docker

# start blockchain
docker-compose up -d anvil

# deploy
docker-compose run --rm dev script/deploy.sh

# test
docker-compose run --rm dev forge test

# interactive shell
docker-compose run --rm dev bash

# stop
docker-compose down
```

## Troubleshooting

- **"exec format error"**: Use `docker-compose run` not `exec`
- **"Port 8545 in use"**: `pkill anvil`
- **"Build failed"**: `./build-docker-images.sh clean`


