#!/usr/bin/env pwsh
#
# run-scw.ps1 - PowerShell wrapper to run Scaleway CLI via Podman/Docker
#
# Usage: .\run-scw.ps1 [scw arguments...]
# Example: .\run-scw.ps1 instance list
#
# Environment variables (set before running):
#   SCW_ACCESS_KEY                  - Your Scaleway access key
#   SCW_SECRET_KEY                  - Your Scaleway secret key
#   SCW_DEFAULT_ORGANIZATION_ID     - Default organization ID
#   SCW_DEFAULT_REGION              - Default region (e.g., fr-par)
#   SCW_DEFAULT_ZONE                - Default zone (e.g., fr-par-1)
#   SCW_PROFILE                     - Configuration profile name
#   SCW_CONFIG_PATH                 - Path to config file
#   SCW_RUNNER_IMAGE                - Container image (default: scaleway/cli:latest)
#   SCW_RUNNER_RUNTIME              - Force runtime: "podman" or "docker"
#

$ErrorActionPreference = "Stop"

# Detect container runtime
$Runtime = $null
if ($env:SCW_RUNNER_RUNTIME) {
    $Runtime = $env:SCW_RUNNER_RUNTIME
} elseif (Get-Command podman -ErrorAction SilentlyContinue) {
    $Runtime = "podman"
} elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    $Runtime = "docker"
}

if (-not $Runtime) {
    Write-Error "Error: Neither podman nor docker found. Please install one of them."
    Write-Error "  Set `$env:SCW_RUNNER_RUNTIME to force a specific runtime."
    exit 1
}

$Image = $env:SCW_RUNNER_IMAGE
if (-not $Image) {
    $Image = "scaleway/cli:latest"
}

# Build the run command arguments
$RunArgs = @(
    "run",
    "-i",
    "--rm"
)

# Pass through SCW_* environment variables if set
$ScwEnvVars = @(
    "SCW_ACCESS_KEY",
    "SCW_SECRET_KEY",
    "SCW_DEFAULT_ORGANIZATION_ID",
    "SCW_DEFAULT_REGION",
    "SCW_DEFAULT_ZONE",
    "SCW_PROFILE",
    "SCW_CONFIG_PATH"
)

foreach ($envVar in $ScwEnvVars) {
    if (Test-Path "env:$envVar") {
        $RunArgs += "-e"
        $RunArgs += $envVar
    }
}

# Mount current directory and set working directory
$RunArgs += "-v"
$RunArgs += "${PWD}:/workspace"
$RunArgs += "-w"
$RunArgs += "/workspace"

$RunArgs += $Image
$RunArgs += $args

# Execute the container
& $Runtime @RunArgs
