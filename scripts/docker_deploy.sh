#!/bin/bash

# Function to print usage
print_usage() {
  echo "Usage: $0 [-i image] [-f deployment_file] [-n namespace] [-d deployment_name]"
  echo "  -i image              Docker image with tag (e.g., docker.io/username/repo:tag)"
  echo "  -f deployment_file    Kubernetes deployment template file (default: k8s/deployment.yaml)"
  echo "  -n namespace          Kubernetes namespace (default: default)"
  echo "  -d deployment_name    Kubernetes deployment name (default: derived from image name)"
}

# Default values
DEPLOYMENT_FILE="k8s/deployment.yaml"
NAMESPACE="default"
DEPLOYMENT_NAME=""

# Parse command line arguments
while getopts 'i:f:n:d:' flag; do
  case "${flag}" in
    i) IMAGE="${OPTARG}" ;;
    f) DEPLOYMENT_FILE="${OPTARG}" ;;
    n) NAMESPACE="${OPTARG}" ;;
    d) DEPLOYMENT_NAME="${OPTARG}" ;;
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

# If deployment name not provided, derive from image name
if [ -z "$DEPLOYMENT_NAME" ]; then
  # Extract repo name from image (username/repo:tag -> repo)
  DEPLOYMENT_NAME=$(echo "$IMAGE" | sed -E 's|.*/([^/]+):[^:]+$|\1|')-deployment
  echo "Using derived deployment name: $DEPLOYMENT_NAME"
fi

# Check if deployment file exists
if [ ! -f "$DEPLOYMENT_FILE" ]; then
  echo "Error: Deployment file not found: $DEPLOYMENT_FILE"
  exit 1
fi

echo "Deploying image $IMAGE to Kubernetes"
echo "  - Namespace: $NAMESPACE"
echo "  - Deployment: $DEPLOYMENT_NAME"
echo "  - Template: $DEPLOYMENT_FILE"

# Create a temporary deployment file with the image substituted
TEMP_DEPLOYMENT_FILE=$(mktemp)
cat "$DEPLOYMENT_FILE" | sed "s|<IMAGE>|$IMAGE|g" > "$TEMP_DEPLOYMENT_FILE"

# Apply the deployment
kubectl apply -f "$TEMP_DEPLOYMENT_FILE" -n "$NAMESPACE"
RESULT=$?

# Clean up the temporary file
rm "$TEMP_DEPLOYMENT_FILE"

# Wait for rollout if applied successfully
if [ $RESULT -eq 0 ]; then
  echo "Waiting for rollout to complete..."
  kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
else
  echo "Deployment failed with exit code $RESULT"
  exit $RESULT
fi