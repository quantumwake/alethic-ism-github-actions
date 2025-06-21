# Docker Build and Deploy GitHub Action

This GitHub Action automates the process of building, pushing, and deploying Docker images to Kubernetes. It handles versioning, Docker registry authentication, and Kubernetes deployment in a single workflow.

## Features

- 🐳 Automatic Docker image building and pushing
- 🔄 Version management (git tags or commit SHA)
- 🔐 Secure registry authentication
- 🚀 Kubernetes deployment support
- 📝 Automatic changelog generation for releases
- 🏷️ Latest tag support

## Usage

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: quantumwake/alethic-ism-github-actions@main
        with:
          # Required inputs
          image-name: 'your-username/your-repo'  # Format: username/repository
          registry-username: ${{ secrets.DOCKERHUB_USERNAME }}
          registry-token: ${{ secrets.DOCKERHUB_TOKEN }}  # Use access token, not password
          
          # Optional inputs
          registry: 'docker.io'  # Default Docker Hub registry
          k8s-config: 'your-k8s-config-command'  # Required only for Kubernetes deployment
          k8s-namespace: 'default'
          k8s-deployment: ''  # If not specified, will use {image-name}-deployment
          deployment-file: 'k8s/deployment.yaml'
          build-args: '--build-arg KEY=VALUE'
          tag: ''  # Optional, defaults to git tag or commit SHA
          create-github-release: 'false'
```

## Input Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `image-name` | Yes | - | Base image name (format: username/repository) |
| `registry-username` | Yes | - | Docker registry username |
| `registry-token` | Yes | - | Docker registry access token (not password) |
| `registry` | No | `docker.io` | Docker registry URL |
| `k8s-config` | No | `none` | Kubernetes config command or type |
| `k8s-namespace` | No | `default` | Kubernetes namespace |
| `k8s-deployment` | No | - | Kubernetes deployment name (defaults to {image-name}-deployment) |
| `deployment-file` | No | `k8s/deployment.yaml` | Path to Kubernetes deployment template |
| `build-args` | No | `''` | Extra arguments for docker build |
| `tag` | No | - | Image tag (defaults to git tag or commit SHA) |
| `create-github-release` | No | `false` | Create GitHub release for tags |

## Important Notes

### Docker Registry Authentication
- Use a Docker Hub access token instead of your password
- The token needs push permissions to your repository
- For Docker Hub, the registry should be `docker.io`

### Version Management
- If a git tag is present, it will be used as the image tag
- Otherwise, the short commit SHA will be used
- The `latest` tag is always pushed alongside the versioned tag

### Kubernetes Deployment
- Set `k8s-config` to enable Kubernetes deployment
- The deployment name defaults to `{image-name}-deployment`
- Make sure your Kubernetes config has proper permissions

### GitHub Releases
- Set `create-github-release: 'true'` to create releases
- Only creates releases for git tags
- Automatically generates changelog from commit messages

## Outputs

| Output | Description |
|--------|-------------|
| `image` | Full Docker image name with tag |

## Example Workflow

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: quantumwake/alethic-ism-github-actions@main
        with:
          image-name: 'quantumwake/myapp'
          registry-username: ${{ secrets.DOCKERHUB_USERNAME }}
          registry-token: ${{ secrets.DOCKERHUB_TOKEN }}
          k8s-config: 'echo "${{ secrets.KUBE_CONFIG }}" > kubeconfig.yaml && export KUBECONFIG=kubeconfig.yaml'
          k8s-namespace: 'production'
          create-github-release: 'true'
```

## Security Considerations

1. Never use your Docker Hub password in workflows
2. Use repository secrets for sensitive information
3. Ensure your Docker Hub token has minimal required permissions
4. Regularly rotate your access tokens

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Verify your Docker Hub token has push permissions
   - Check if the image name matches your Docker Hub username
   - Ensure the registry URL is correct

2. **Kubernetes Deployment Fails**
   - Verify your k8s-config command
   - Check namespace permissions
   - Ensure deployment template is valid

3. **Script Permission Issues**
   - Make sure the shell scripts in the action are executable
   - Check if the action has proper permissions

## License

[Add your license information here]