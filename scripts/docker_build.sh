#!/bin/bash

# Function to print usage
print_usage() {
  echo "Usage: $0 [-i image] [-l latest_image] [-p architecture] [-b use_buildpack] [-f dockerfile] [-c context] [-- build_args]"
  echo "  -i image           Docker image with tag (e.g., docker.io/username/repo:tag)"
  echo "  -l latest_image    Latest version of the Docker image (optional)"
  echo "  -p platform        Target platform architecture (linux/amd64, linux/arm64, ...)"
  echo "  -b                 Use buildpack instead of direct Docker build (optional)"
  echo "  -f dockerfile      Path to Dockerfile (default: Dockerfile)"
  echo "  -c context         Docker build context directory (default: .)"
  echo "  --                 Everything after this is passed as build args to docker build"
}

# Default values
ARCH="linux/amd64"
USE_BUILDPACK=false
LATEST_IMAGE=""
BUILD_ARGS=""
DOCKERFILE="Dockerfile"
CONTEXT="."

# Parse command line arguments
while getopts 'i:l:p:bf:c:' flag; do
  case "${flag}" in
    i) IMAGE="${OPTARG}" ;;
    l) LATEST_IMAGE="${OPTARG}" ;;
    p) ARCH="${OPTARG}" ;;
    b) USE_BUILDPACK=true ;;
    f) DOCKERFILE="${OPTARG}" ;;
    c) CONTEXT="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Shift past the parsed options
shift $((OPTIND-1))

# Process build args - convert each arg to "--build-arg ARG"
BUILD_ARGS=""
for arg in "$@"; do
  if [ -n "$arg" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg $arg"
  fi
done
# Trim leading space if any
BUILD_ARGS="${BUILD_ARGS# }"

# Check if IMAGE is provided
if [ -z "$IMAGE" ]; then
  echo "Error: Image name is required"
  print_usage
  exit 1
fi

# If latest image not provided, derive from base image
if [ -z "$LATEST_IMAGE" ]; then
  LATEST_IMAGE=$(echo $IMAGE | sed -e 's/\:.*$/:latest/g')
fi

# Display arguments
echo "Platform: $ARCH"
echo "Image: $IMAGE"
echo "Latest: $LATEST_IMAGE"
echo "Dockerfile: $DOCKERFILE"
echo "Context: $CONTEXT"
echo "Using Buildpack: $USE_BUILDPACK"
if [ -n "$BUILD_ARGS" ]; then
  echo "Build Args: $BUILD_ARGS"
fi

if [ "$USE_BUILDPACK" = true ]; then
  echo "Building with buildpack..."
  pack build "$IMAGE" \
    --builder paketobuildpacks/builder:base \
    --path "$CONTEXT" \
    --env BP_DOCKERFILE="$DOCKERFILE" \
    --env BP_PLATFORM_API="$ARCH"

  # Tag latest if needed
  if [ "$IMAGE" != "$LATEST_IMAGE" ]; then
    docker tag "$IMAGE" "$LATEST_IMAGE"
  fi
else
  echo "Building with Docker..."
  if [ -n "$BUILD_ARGS" ]; then
    docker build --progress=plain \
      --platform "$ARCH" -f "$DOCKERFILE" -t "$IMAGE" -t "$LATEST_IMAGE" $BUILD_ARGS "$CONTEXT"
  else
    docker build --progress=plain \
      --platform "$ARCH" -f "$DOCKERFILE" -t "$IMAGE" -t "$LATEST_IMAGE" "$CONTEXT"
  fi
fi