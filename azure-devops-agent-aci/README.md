# Azure DevOps Agent - Azure Container Instances (ACI)

Linux-based Azure DevOps agent image designed for Azure Container Instances. This image includes comprehensive tooling based on the Ubuntu 24.04 GitHub Actions runner specification.

## Base Image

- **OS**: Ubuntu 24.04 LTS
- **Architecture**: linux/amd64

## Environment Variables

### Required

- `AZP_URL` - The URL of your Azure DevOps organization (e.g., `https://dev.azure.com/your-org`)
- `AZP_TOKEN` - Personal Access Token (PAT) with Agent Pools (read, manage) scope

### Optional

- `AZP_AGENT_NAME` - Specific name for the agent (default: hostname)
- `AZP_POOL` - Agent pool name (default: `Default`)
- `AZP_WORK` - Working directory for builds (default: `_work`)
- `AZP_TOKEN_FILE` - Path to file containing PAT token (alternative to `AZP_TOKEN`)

## Building the Image

### Local Build

```bash
cd azure-devops-agent-aci
docker build -t azure-devops-agent-aci:latest .
```

### Build with ACR Tasks

```bash
az acr build \
  --registry <your-registry-name> \
  --image azure-devops-agent-aci:latest \
  --file azure-devops-agent-aci/Dockerfile \
  .
```

## Running the Container

### Docker Run

```bash
docker run -e AZP_URL="<Azure DevOps instance>" \
           -e AZP_TOKEN="<Personal Access Token>" \
           -e AZP_POOL="<Agent Pool Name>" \
           -e AZP_AGENT_NAME="<Agent Name>" \
           azure-devops-agent-aci:latest
```

### Azure Container Instances

```bash
az container create \
  --resource-group <resource-group> \
  --name <container-name> \
  --image <registry>.azurecr.io/azure-devops-agent-aci:latest \
  --environment-variables \
    AZP_URL=<Azure DevOps URL> \
    AZP_TOKEN=<PAT Token> \
    AZP_POOL=<Pool Name> \
  --cpu 2 \
  --memory 4
```

## Installed Tools

This image includes 100+ tools. See the main [README.md](../README.md) for the complete list.

### Key Highlights

- **Node.js**: v16, v18, v20, v22
- **Python**: 3.8, 3.9, 3.10, 3.11, 3.12, 3.13
- **Go**: 1.23.1
- **Java**: JDK 8, 11, 17, 21
- **.NET**: SDK 6.0, 7.0, 8.0, 9.0
- **Docker**: Docker CE with Buildx and Compose plugins
- **Terraform**, **Pulumi**, **Ansible**
- **Azure CLI**, **AWS CLI**, **Google Cloud SDK**
- **kubectl**, **Helm**, **kind**

## Agent Behavior

- The agent runs in **ephemeral mode** (`--once` flag)
- After completing a job, the agent automatically deregisters and the container exits
- Designed for scale-to-zero scenarios with Azure Container Instances
- Includes 30-second startup delay for private vnet scenarios

## Security Considerations

1. **Token Management**: The agent removes the administrative token after configuration
2. **Environment Variables**: Sensitive tokens are unset after use
3. **Cleanup**: Agent automatically deregisters on termination

## Troubleshooting

### Agent Not Appearing in Pool

- Verify `AZP_URL` is correct and accessible
- Check PAT token has correct permissions (Agent Pools: read, manage)
- Ensure the specified pool exists
- Check container logs for connection errors

### Build Failures

- Verify all required tools are installed in the image
- Check working directory permissions
- Review Azure DevOps pipeline logs for specific errors

## Development

To add additional tools, modify the `Dockerfile` and rebuild the image.

## License

MIT License - see the repository LICENSE file for details.
