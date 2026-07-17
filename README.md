# scw-runner

Cross-platform scripts to run the [Scaleway CLI](https://github.com/scaleway/scaleway-cli) via Podman or Docker, using environment variables for configuration.

## Prerequisites

- **Podman** (recommended) or **Docker** installed on your system
- Scaleway credentials (access key, secret key, organization ID)

## Quick Start

### Linux/macOS

```bash
# Clone the repository
git clone https://github.com/Monitob/scw-runner.git
cd scw-runner

# Make the script executable
chmod +x run-scw.sh

# Set your credentials
export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export SCW_DEFAULT_ORGANIZATION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export SCW_DEFAULT_REGION="fr-par"

# Run a command
./run-scw.sh instance list
```

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/Monitob/scw-runner.git
cd scw-runner

# Set your credentials
$env:SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
$env:SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$env:SCW_DEFAULT_ORGANIZATION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$env:SCW_DEFAULT_REGION="fr-par"

# Run a command
.\run-scw.ps1 instance list
```

### Windows (Command Prompt)

```cmd
REM Clone the repository
git clone https://github.com/Monitob/scw-runner.git
cd scw-runner

REM Set your credentials
set SCW_ACCESS_KEY=SCWXXXXXXXXXXXXXXXXX
set SCW_SECRET_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
set SCW_DEFAULT_ORGANIZATION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
set SCW_DEFAULT_REGION=fr-par

REM Run a command
run-scw.bat instance list
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SCW_ACCESS_KEY` | Your Scaleway access key | Yes (for API calls) |
| `SCW_SECRET_KEY` | Your Scaleway secret key | Yes (for API calls) |
| `SCW_DEFAULT_ORGANIZATION_ID` | Default organization ID | Yes (for API calls) |
| `SCW_DEFAULT_REGION` | Default region (e.g., `fr-par`, `nl-ams`) | No |
| `SCW_DEFAULT_ZONE` | Default zone (e.g., `fr-par-1`) | No |
| `SCW_PROFILE` | Configuration profile name | No |
| `SCW_CONFIG_PATH` | Path to config file | No |
| `SCW_RUNNER_IMAGE` | Container image (default: `scaleway/cli:latest`) | No |
| `SCW_RUNNER_RUNTIME` | Force runtime: `podman` or `docker` | No |

## Using a .env File

Instead of exporting variables each time, use a `.env` file:

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your credentials
# (never commit this file - it's in .gitignore!)

# Load and run (Linux/macOS with bash)
source .env && ./run-scw.sh instance list

# Or use export (works in any shell)
set -a && source .env && set +a && ./run-scw.sh instance list
```

## Example Commands

```bash
# Check CLI version
./run-scw.sh version

# List all instances
./run-scw.sh instance list

# Create a new instance
./run-scw.sh instance server create name=my-server type=DEV1-S image=ubuntu-focal

# Start/stop an instance
./run-scw.sh instance server start my-server
./run-scw.sh instance server stop my-server

# Interactive configuration (creates config file)
./run-scw.sh init

# Object Storage - list buckets
./run-scw.sh object bucket list

# Databases - list instances
./run-scw.sh rdb instance list

# Kubernetes - list clusters
./run-scw.sh k8s cluster list
```

## How It Works

The scripts:

1. **Detect container runtime** - Checks for Podman first (recommended), then Docker
2. **Run the container** - Executes `scaleway/cli:latest` with your arguments
3. **Pass credentials** - Forwards `SCW_*` environment variables securely
4. **Mount workspace** - Your current directory is mounted to `/workspace` in the container
5. **Forward commands** - All arguments are passed directly to the `scw` CLI

## Security Notes

- ⚠️ **Never commit `.env`** - It contains your credentials
- ⚠️ **Add `.env` to `.gitignore`** - Already included in this repo
- ✅ Credentials are passed as environment variables, not stored in the container
- ✅ Container is ephemeral (`--rm` flag) - no data persists after running
- ✅ No credentials are hardcoded in the scripts

## Troubleshooting

### "Neither podman nor docker found"
Install Podman or Docker:
- **Podman**: https://podman.io/docs/installation
- **Docker**: https://docs.docker.com/get-docker/

### "Authentication failed"
Verify your credentials:
```bash
./run-scw.sh account ssh-key list
```

### Force a specific runtime
```bash
export SCW_RUNNER_RUNTIME=docker  # or podman
./run-scw.sh instance list
```

### Use a specific CLI version
```bash
export SCW_RUNNER_IMAGE=scaleway/cli:2.20.0
./run-scw.sh version
```

## Container Image

Uses the official Scaleway CLI image: [scaleway/cli](https://hub.docker.com/r/scaleway/cli)

## License

MIT - See [LICENSE](LICENSE) file for details.
