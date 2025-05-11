#!/bin/bash

# Function to print usage
print_usage() {
  echo "Usage: $0 [-i image] [-l latest_image]"
  echo "  -i image              Docker image with tag (e.g., docker.io/username/repo:tag)"
  echo "  -l latest_image       Latest version of the Docker image (optional)"
}

# Default values
LATEST_IMAGE=""

# Parse command line arguments
while getopts 'i:l:' flag; do
  case "${flag}" in
    i) IMAGE="${OPTARG}" ;;
    l) LATEST_IMAGE="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

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

echo "Pushing Docker image: $IMAGE"
docker push "$IMAGE"

# Push latest tag if it exists and is different
if [ "$IMAGE" != "$LATEST_IMAGE" ]; then
  echo "Pushing latest tag: $LATEST_IMAGE"
  docker push "$LATEST_IMAGE"
fi