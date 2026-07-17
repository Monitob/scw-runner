#!/bin/bash
#
# run-scw.sh - Cross-platform wrapper to run Scaleway CLI via Podman/Docker
#
# Usage: ./run-scw.sh [scw arguments...]
# Example: ./run-scw.sh instance list
#
# Environment variables:
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

set -e

# Detect container runtime
get_container_runtime() {
    if [ -n "$SCW_RUNNER_RUNTIME" ]; then
        echo "$SCW_RUNNER_RUNTIME"
        return
    fi
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

# Main function
main() {
    local runtime
    runtime=$(get_container_runtime)

    if [ -z "$runtime" ]; then
        echo "Error: Neither podman nor docker found. Please install one of them." >&2
        echo "  Set SCW_RUNNER_RUNTIME to force a specific runtime." >&2
        exit 1
    fi

    local image="${SCW_RUNNER_IMAGE:-scaleway/cli:latest}"

    # Build podman/docker run arguments
    local run_args=(-i --rm)

    # Pass through SCW_* environment variables if set
    local env_vars=(
        SCW_ACCESS_KEY
        SCW_SECRET_KEY
        SCW_DEFAULT_ORGANIZATION_ID
        SCW_DEFAULT_REGION
        SCW_DEFAULT_ZONE
        SCW_PROFILE
        SCW_CONFIG_PATH
    )

    for env_var in "${env_vars[@]}"; do
        if [ -n "${!env_var+x}" ]; then
            run_args+=(-e "$env_var")
        fi
    done

    # Mount current directory and set working directory
    run_args+=(-v "${PWD}:/workspace" -w /workspace)

    # Add image and command arguments
    run_args+=("$image" "$@")

    # Execute the container
    "$runtime" "${run_args[@]}"
}

main "$@"
