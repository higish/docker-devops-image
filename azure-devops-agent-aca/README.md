# Azure DevOps Agent - Azure Container Apps (ACA)

Linux-based Azure DevOps agent image optimized for Azure Container Apps with dynamic scaling capabilities. This image includes comprehensive tooling based on the Ubuntu 24.04 GitHub Actions runner specification.

## Base Image

- **OS**: Ubuntu 24.04 LTS
- **Architecture**: Supports linux/amd64 and linux/arm64 (configurable via TARGETARCH)

## Environment Variables

### Required

- `AZP_URL` - The URL of your Azure DevOps organization (e.g., `https://dev.azure.com/your-org`)
- `AZP_TOKEN` - Personal Access Token (PAT) with Agent Pools (read, manage) scope

### Optional

- `AZP_AGENT_NAME` - Specific name for the agent
- `AZP_AGENT_NAME_PREFIX` - Prefix for auto-generated agent names (default: `azure-devops-agent`)
- `AZP_RANDOM_AGENT_SUFFIX` - Add random suffix to agent name (default: `true`)
- `AZP_POOL` - Agent pool name (default: `Default`)
- `AZP_WORK` - Working directory for builds (default: `_work`)
- `AZP_TOKEN_FILE` - Path to file containing PAT token (alternative to `AZP_TOKEN`)
- `AZP_PLACEHOLDER` - Set to skip agent execution (for testing/placeholder scenarios)

## Building the Image

### Local Build

```bash
cd azure-devops-agent-aca
docker build -t azure-devops-agent-aca:latest .
```

### Multi-Architecture Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t azure-devops-agent-aca:latest \
  --push \
  .
```

### Build with ACR Tasks

```bash
az acr build \
  --registry <your-registry-name> \
  --image azure-devops-agent-aca:{{.Run.ID}} \
  --image azure-devops-agent-aca:latest \
  --file azure-devops-agent-aca/Dockerfile \
  .
```

## Running the Container

### Docker Run

```bash
docker run -e AZP_URL="<Azure DevOps instance>" \
           -e AZP_TOKEN="<Personal Access Token>" \
           -e AZP_POOL="<Agent Pool Name>" \
           -e AZP_AGENT_NAME_PREFIX="<Agent Name Prefix>" \
           azure-devops-agent-aca:latest
```

### Azure Container Apps

```yaml
properties:
  configuration:
    secrets:
      - name: azp-token
        value: <your-pat-token>
  template:
    containers:
      - name: azure-devops-agent
        image: <registry>.azurecr.io/azure-devops-agent-aca:latest
        env:
          - name: AZP_URL
            value: https://dev.azure.com/<your-org>
          - name: AZP_TOKEN
            secretRef: azp-token
          - name: AZP_POOL
            value: <pool-name>
          - name: AZP_AGENT_NAME_PREFIX
            value: aca-agent
    scale:
      minReplicas: 0
      maxReplicas: 10
      rules:
        - name: azure-pipelines-jobs
          custom:
            type: azure-pipelines
            metadata:
              poolName: <pool-name>
              targetPipelinesQueueLength: "1"
```

## Installed Tools

This image includes 100+ tools. See the main [README.md](../README.md) for the complete list.

### Key Highlights

- **Node.js**: v16, v18, v20, v22 (managed via nvm)
- **Python**: 3.8, 3.9, 3.10, 3.11, 3.12, 3.13
- **Go**: 1.23.1
- **Java**: JDK 8, 11, 17, 21 (managed via SDKMAN)
- **.NET**: SDK 6.0, 7.0, 8.0, 9.0
- **Docker**: Docker CE with Buildx and Compose plugins
- **Terraform**, **Pulumi**, **Ansible**
- **Azure CLI**, **AWS CLI**, **Google Cloud SDK**
- **kubectl**, **Helm**, **kind**
- **Ruby**, **PHP**, **Rust**

## Agent Behavior

- Supports **dynamic scaling** in Azure Container Apps
- Runs with `--once` flag for single job execution
- Auto-deregisters after job completion
- Supports graceful shutdown with cleanup on SIGTERM/SIGINT
- Random agent names by default for parallel scaling

## Container Apps Integration

This image is optimized for Azure Container Apps KEDA scaling:

1. **Scale to Zero**: Container Apps can scale to 0 when no jobs are queued
2. **Auto-scaling**: KEDA monitors the agent pool queue and scales containers
3. **Job Isolation**: Each container executes one job then terminates
4. **Dynamic Naming**: Random suffixes prevent naming conflicts during scale-up

## Security Considerations

1. **Token Management**: 
   - Use Container Apps secrets for `AZP_TOKEN`
   - Token is removed from environment after agent configuration
2. **Cleanup on Exit**: Agent deregisters gracefully on termination
3. **Retry Logic**: Cleanup process retries to ensure agent removal

## Troubleshooting

### Agent Not Scaling

- Verify KEDA scaler configuration
- Check agent pool has queued jobs
- Review Container Apps logs for connection errors
- Ensure PAT token has correct permissions

### Agents Not Deregistering

- Check cleanup logic is executing (look for "Cleanup" messages in logs)
- Verify agent has network access during shutdown
- Check for hanging processes preventing cleanup

### Build Failures

- Verify required tools are available in the image
- Check environment variable configuration
- Review Azure DevOps pipeline logs for specific errors

## Development

To add additional tools, modify the `Dockerfile` and rebuild the image. The image is designed to be customizable while maintaining compatibility with Azure Container Apps scaling.

## Performance Optimization

- **Layer Caching**: Dockerfile is organized to maximize layer reuse
- **Multi-stage Not Required**: All tools in single image for simplicity
- **Pre-installed Tools**: Avoids download time during pipeline execution

## License

MIT License - see the repository LICENSE file for details.
