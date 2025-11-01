#!/bin/bash
set -e

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

# Determine authentication method based on environment variables
if [ -n "$AZURE_CLIENT_ID" ] && [ -n "$AZURE_TENANT_ID" ] && [ -n "$AZURE_CLIENT_SECRET" ]; then
  echo "Using Service Principal authentication"
  AUTH_TYPE="SP"
  
  # Validate all SP credentials are present
  if [ -z "$AZURE_CLIENT_ID" ]; then
    echo 1>&2 "error: missing AZURE_CLIENT_ID environment variable"
    exit 1
  fi
  if [ -z "$AZURE_TENANT_ID" ]; then
    echo 1>&2 "error: missing AZURE_TENANT_ID environment variable"
    exit 1
  fi
  if [ -z "$AZURE_CLIENT_SECRET" ]; then
    echo 1>&2 "error: missing AZURE_CLIENT_SECRET environment variable"
    exit 1
  fi
else
  echo "Using PAT authentication"
  AUTH_TYPE="PAT"
  
  if [ -z "$AZP_TOKEN_FILE" ]; then
    if [ -z "$AZP_TOKEN" ]; then
      echo 1>&2 "error: missing AZP_TOKEN environment variable"
      exit 1
    fi

    AZP_TOKEN_FILE=/azp/.token
    echo -n $AZP_TOKEN > "$AZP_TOKEN_FILE"
  fi

  unset AZP_TOKEN
fi

if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

rm -rf /azp/agent
mkdir /azp/agent
cd /azp/agent

export AGENT_ALLOW_RUNASROOT="1"

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    if [ "$AUTH_TYPE" = "SP" ]; then
      # Service Principal cleanup - agent will use managed identity
      ./config.sh remove --unattended \
        --auth SP
    else
      # PAT cleanup
      ./config.sh remove --unattended \
        --auth PAT \
        --token $(cat "$AZP_TOKEN_FILE")
    fi
  fi
}

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# Let the agent ignore the SP secret and GitHub token env variables to prevent them from being visible in Azure DevOps
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE,AZURE_CLIENT_SECRET,AZP_GITHUB_TOKEN

# ACI in private vnet require time to get access to Internet
sleep 30

print_header "1. Determining matching Azure Pipelines agent..."

# Get the latest agent download URL from GitHub releases
# Use AZP_GITHUB_TOKEN env var if provided to avoid rate limits (60/hr unauthenticated, 5000/hr authenticated)
echo "Getting latest agent version from GitHub..."

if [ -n "$AZP_GITHUB_TOKEN" ]; then
  echo "Using authenticated GitHub API request..."
  GITHUB_RELEASE=$(curl -s -H "Authorization: token ${AZP_GITHUB_TOKEN}" \
    https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest)
else
  echo "Using unauthenticated GitHub API request (60 requests/hour limit)..."
  GITHUB_RELEASE=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest)
fi

# Extract the Linux x64 download URL from the release body markdown
AZP_AGENTPACKAGE_URL=$(echo "$GITHUB_RELEASE" | jq -r '.body' | grep -oP 'Linux x64\s+\|\s+\[.*?\]\(\K[^)]+' | head -1)

if [ -z "$AZP_AGENTPACKAGE_URL" ] || [ "$AZP_AGENTPACKAGE_URL" = "null" ]; then
  echo 1>&2 "error: failed to get agent download URL from GitHub"
  exit 1
fi

# Extract version from URL for logging
AGENT_VERSION=$(echo "$AZP_AGENTPACKAGE_URL" | grep -oP 'agent/\K[0-9.]+')
echo "Latest agent version: ${AGENT_VERSION}"
echo "Download URL: ${AZP_AGENTPACKAGE_URL}"

if [ -z "$AZP_AGENTPACKAGE_URL" -o "$AZP_AGENTPACKAGE_URL" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and installing Azure Pipelines agent..."

curl -LsS $AZP_AGENTPACKAGE_URL | tar -xz & wait $!

source ./env.sh

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

print_header "3. Configuring Azure Pipelines agent..."

if [ "$AUTH_TYPE" = "SP" ]; then
  # Service Principal authentication with client secret
  ./config.sh --unattended \
    --agent "${AZP_AGENT_NAME:-$(hostname)}" \
    --url "$AZP_URL" \
    --auth SP \
    --clientid "$AZURE_CLIENT_ID" \
    --clientsecret "$AZURE_CLIENT_SECRET" \
    --tenantid "$AZURE_TENANT_ID" \
    --pool "${AZP_POOL:-Default}" \
    --work "${AZP_WORK:-_work}" \
    --replace \
    --acceptTeeEula & wait $!
else
  # PAT authentication
  ./config.sh --unattended \
    --agent "${AZP_AGENT_NAME:-$(hostname)}" \
    --url "$AZP_URL" \
    --auth PAT \
    --token $(cat "$AZP_TOKEN_FILE") \
    --pool "${AZP_POOL:-Default}" \
    --work "${AZP_WORK:-_work}" \
    --replace \
    --acceptTeeEula & wait $!
  
  # remove the administrative token before accepting work
  rm $AZP_TOKEN_FILE
fi

print_header "4. Running Azure Pipelines agent..."

# `exec` the node runtime so it's aware of TERM and INT signals
# AgentService.js understands how to handle agent self-update and restart
exec ./externals/node/bin/node ./bin/AgentService.js interactive --once
