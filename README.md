# Docker Build and Deploy Action

A reusable GitHub Action to build, push, and deploy Docker images to Kubernetes.

## Setup Instructions

### 1. Create a dedicated repository for this action

```bash
# Clone the repository into a new directory
mkdir -p ~/Development/quantumwake/docker-build-deploy-action
cp -r templates/* ~/Development/quantumwake/docker-build-deploy-action/
cd ~/Development/quantumwake/docker-build-deploy-action

# Initialize git repository and commit
git init
git add .
git commit -m "Initial commit for Docker build and deploy action"

# Create GitHub repository and push
# Replace YOUR_USERNAME with your GitHub username
gh repo create docker-build-deploy-action --public --source=. --push
```

### 2. Reference the action in your projects

In each project, create a GitHub workflow file (`.github/workflows/build-deploy.yml`):

```yaml
name: Build and Deploy

on:
  push:
    tags: [ "v*" ]
  pull_request:
    branches: [ "main" ]

permissions:
  contents: write  # Needed for creating releases

jobs:
  build-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Build, Push, and Deploy Docker Image
        uses: quantumwake/docker-build-deploy-action@main
        with:
          # Required inputs
          image-name: 'your-username/your-repo'  # Replace with your image name
          registry-username: ${{ vars.DOCKERHUB_USERNAME }}
          registry-token: ${{ secrets.DOCKERHUB_TOKEN }}
          
          # Optional inputs with defaults shown
          registry: 'docker.io'  # Docker registry to use
          k8s-config: 'none'  # Set to command that loads Kubernetes config
          k8s-namespace: 'default'  # Kubernetes namespace
          k8s-deployment: 'your-repo-deployment'  # K8s deployment name
          deployment-file: 'k8s/deployment.yaml'  # Path to deployment template
          build-args: ''  # Additional build arguments
          create-github-release: 'true'  # Create GitHub release for tags
```

## Configuration Options

### Required Inputs

- `image-name`: Base image name (e.g., username/repository)
- `registry-username`: Docker registry username
- `registry-token`: Docker registry token

### Optional Inputs

- `registry`: Docker registry to use (default: 'docker.io')
- `k8s-config`: Command to load Kubernetes config (default: 'none')
  - Example for DigitalOcean: `doctl kubernetes cluster kubeconfig save --expiry-seconds 600 your-cluster-name`
  - Set to 'none' to skip deployment steps
- `k8s-namespace`: Kubernetes namespace (default: 'default')
- `k8s-deployment`: Kubernetes deployment name (default: derived from image-name)
- `deployment-file`: Path to Kubernetes deployment template (default: 'k8s/deployment.yaml')
- `build-args`: Extra args for docker build
- `tag`: Image tag (defaults to git tag or short commit SHA)
- `create-github-release`: Create a GitHub release for tags (default: 'false')

## Examples

### Basic Docker Build and Push

```yaml
- name: Build and Push Docker Image
  uses: quantumwake/docker-build-deploy-action@main
  with:
    image-name: 'your-username/your-repo'
    registry-username: ${{ vars.DOCKERHUB_USERNAME }}
    registry-token: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Complete Build, Push, and Deploy to DigitalOcean Kubernetes

```yaml
- name: Build, Push, and Deploy
  uses: quantumwake/docker-build-deploy-action@main
  with:
    image-name: 'your-username/your-repo'
    registry-username: ${{ vars.DOCKERHUB_USERNAME }}
    registry-token: ${{ secrets.DOCKERHUB_TOKEN }}
    k8s-config: 'doctl kubernetes cluster kubeconfig save --expiry-seconds 600 your-cluster-name'
    k8s-namespace: 'your-namespace'
    create-github-release: 'true'
```

## Kubernetes Deployment Template

Your K8s deployment file (`k8s/deployment.yaml`) should include an `<IMAGE>` placeholder:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: your-app
  template:
    metadata:
      labels:
        app: your-app
    spec:
      containers:
      - name: your-app
        image: <IMAGE>  # This will be replaced with the actual image
        ports:
        - containerPort: 8080
```

## Security Considerations

1. Store credentials (registry tokens, K8s access tokens) as GitHub Secrets
2. Use GitHub Variables for non-sensitive configuration (usernames, namespaces)
3. Set appropriate permissions in your workflow file

## Customization

The action scripts support additional customization:

1. Multi-platform builds (`-p linux/arm64,linux/amd64`)
2. Buildpack support (`-b` flag)
3. Custom deployment operations

## Troubleshooting

If you encounter issues:

1. Check the action logs for detailed output
2. Verify your credentials are properly set in GitHub Secrets
3. Ensure your deployment template contains the `<IMAGE>` placeholder
4. For K8s deployment failures, check that your kubectl configuration is correct