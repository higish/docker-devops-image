# Docker DevOps Images for PERS CI/CD

This repository contains container image Dockerfiles and scripts used to build Azure DevOps Agent container images for the PERS infrastructure deployment pipelines.

## Repository Structure

```
docker-devops-image/
├── azure-devops-agent-aci/    # Azure Container Instance agents
│   ├── Dockerfile
│   └── start.sh
├── azure-devops-agent-aca/    # Azure Container Apps agents
│   ├── Dockerfile
│   └── start.sh
├── README.md
└── .dockerignore
```

## Image Types

### Azure DevOps Agent - ACI (Azure Container Instances)

Linux-based Azure DevOps agent image designed for Azure Container Instances. Includes comprehensive tooling based on the Ubuntu 24.04 GitHub Actions runner specification.

**Location:** `azure-devops-agent-aci/`

**Environment Variables:**
- `AZP_URL`: The URL of the Azure DevOps organization
- `AZP_TOKEN`: PAT token for authentication
- `AZP_POOL`: Agent pool name (default: "Default")
- `AZP_AGENT_NAME`: Agent name
- `AZP_WORK`: Working directory (default: "_work")

**Build:**
```bash
cd azure-devops-agent-aci
docker build -t YOUR_IMAGE_NAME:YOUR_IMAGE_TAG .
```

**Push:**
```bash
docker push YOUR_IMAGE_NAME:YOUR_IMAGE_TAG
```

### Azure DevOps Agent - ACA (Azure Container Apps)

Linux-based Azure DevOps agent image optimized for Azure Container Apps with dynamic scaling capabilities.

**Location:** `azure-devops-agent-aca/`

**Build:**
```bash
cd azure-devops-agent-aca
docker build -t YOUR_IMAGE_NAME:YOUR_IMAGE_TAG .
```

## Included Tools

All images are based on Ubuntu 24.04 LTS and include the comprehensive toolset from the GitHub Actions runner-images specification:

### Language Runtimes
- **Node.js**: v16, v18, v20, v22 (via nvm)
- **Python**: 3.8, 3.9, 3.10, 3.11, 3.12, 3.13 (via deadsnakes PPA)
- **Go**: Latest stable version
- **Java**: JDK 8, 11, 17, 21
- **.NET SDK**: 6.0, 7.0, 8.0, 9.0
- **Ruby**: Latest stable version
- **PHP**: Latest stable version

### Container Tools
- Docker CE (with Docker-in-Docker support)
- kubectl (Kubernetes CLI)
- Helm
- kind (Kubernetes in Docker)
- Azure Container Registry (ACR) CLI tools

### Infrastructure as Code
- Terraform
- Pulumi
- Ansible
- Azure Bicep

### Cloud CLIs
- Azure CLI (az)
- AWS CLI (aws)
- Google Cloud SDK (gcloud)

### Build Tools
- GNU Make
- CMake
- Gradle
- Maven
- MSBuild

### Version Control & DevOps
- Git
- Git LFS
- GitHub CLI (gh)
- Azure DevOps CLI
- jq, yq (YAML processor)

### Additional Tools
- curl, wget
- zip, unzip, tar
- vim, nano
- OpenSSL
- SSH client
- And 100+ more tools

## Azure Container Registry Integration

These images are designed to be built and stored in Azure Container Registry (ACR) using ACR Tasks:

```bash
az acr build \
  --registry <your-registry> \
  --image azure-devops-agent-aci:latest \
  --file azure-devops-agent-aci/Dockerfile \
  .
```

## Infrastructure Deployment

The Pulumi infrastructure code that deploys container instances using these images is located in the `pulumi-runners` repository.

## Credits

Repository structure and patterns inspired by [Azure Verified Modules - CI/CD Agents and Runners](https://github.com/Azure/avm-container-images-cicd-agents-and-runners).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
