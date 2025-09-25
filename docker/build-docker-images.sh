#!/usr/bin/env bash
set -euo pipefail

# Build script for Timeboost Contracts Docker images
# Supports multi-architecture builds for CI and local development

usage() {
    >&2 cat <<"EOF"
Usage:

  build-docker-images [--image image] [--platform platform]
  build-docker-images clean

Build timeboost-contracts docker images for multiple architectures.

- The script supports building all images (the default) or one specific image
- By default builds for both linux/amd64 and linux/arm64 (multi-arch)
- Use --platform to build for specific architecture only

Examples:

  # build for all supported platforms
  build-docker-images

  # build for specific platform (CI)
  build-docker-images --platform linux/amd64

  # build for Apple Silicon only
  build-docker-images --platform linux/arm64

  # clean the build artifacts
  build-docker-images clean
EOF
}

# Default values
docker_build_args=""
image=""
platform=""
clean=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -i|--image)
      if [[ -n "${image:-}" ]]; then
        >&2 echo "Error: --image option specified multiple times"
        >&2 echo ""
        usage
        exit 1
      fi
      image="$2"
      shift 2
      ;;
    -p|--platform)
      if [[ -n "${platform:-}" ]]; then
        >&2 echo "Error: --platform option specified multiple times"
        >&2 echo ""
        usage
        exit 1
      fi
      platform="$2"
      shift 2
      ;;
    clean)
      clean="true"
      shift
      ;;
    *)
      >&2 echo "Error: Unknown option '$1'"
      >&2 echo ""
      usage
      exit 1
      ;;
  esac
done

# Handle clean command
if [[ "${clean:-}" == "true" ]]; then
  echo "Cleaning Docker build artifacts..."
  docker system prune -f
  docker builder prune -f
  echo "Clean complete!"
  exit 0
fi

# Set default platform if not specified
if [[ -z "${platform:-}" ]]; then
  platform="linux/amd64,linux/arm64"
fi

# Set default image if not specified
if [[ -z "${image:-}" ]]; then
  image="all"
fi

echo "Building Docker images..."
echo "Image: ${image}"
echo "Platform: ${platform}"
echo ""

build_base_image() {
  if [[ "$platform" == *","* ]]; then
    echo "Multi-platform build for: ${platform}"
  else
    echo "Single platform build for: ${platform}"
  fi

  echo "Building base image(s)..."

  docker buildx build \
      --platform "${platform}" \
      --file "Dockerfile.dev" \
      --tag "timeboost-contracts:latest" \
      --load \
      ..
  
  echo "Base image built successfully"
  echo ""
}

# Build the single image (all services use the same image)
build_base_image

echo "Build complete!"
echo ""
echo "To test the images:"
echo "  docker-compose up -d anvil"
echo "  docker-compose run --rm dev script/deploy.sh"
