#!/usr/bin/env pwsh
#
# install.ps1 - Install scw-runner locally (Windows PowerShell)
#
# Usage: iwr https://raw.githubusercontent.com/Monitob/scw-runner/main/install.ps1 | iex
# Or: .\install.ps1
#

param(
    [switch]$Force,
    [string]$InstallDir = "$env:USERPROFILE\scw-runner"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check for admin privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Detect container runtime
function Get-ContainerRuntime {
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        return "podman"
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        return "docker"
    } else {
        return $null
    }
}

# Check if Docker Desktop is installed
function Test-DockerDesktop {
    return Test-Path "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -or
           Test-Path "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
}

# Install Docker Desktop (requires admin and user interaction)
function Install-DockerDesktop {
    Write-Info "Docker Desktop installation requires manual download."
    Write-Info "Download from: https://www.docker.com/products/docker-desktop/"

    if ($Force) {
        return $false
    }

    $answer = Read-Host "Open Docker Desktop download page? [Y/n]"
    if ([string]::IsNullOrEmpty($answer) -or $answer -match '^[Yy]$') {
        Start-Process "https://www.docker.com/products/docker-desktop/"
        Write-Info "After installation, restart Docker Desktop and re-run this script."
    }

    return $false
}

# Install WSL2 (for Docker/Podman on Windows)
function Install-WSL2 {
    Write-Info "WSL2 is recommended for running containers on Windows."

    if ($Force) {
        return
    }

    $answer = Read-Host "Enable WSL2 and install Ubuntu? [Y/n]"
    if ([string]::IsNullOrEmpty($answer) -or $answer -match '^[Yy]$') {
        Write-Info "Enabling WSL..."
        wsl --install --no-launch

        Write-Info "WSL2 enabled. Restart your computer and re-run this script."
    }
}

# Create directories
function New-InstallDirectories {
    Write-Info "Creating directories..."

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $binDir = Join-Path $InstallDir "bin"
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    Write-Success "Directories created"
}

# Download scripts
function Invoke-DownloadScripts {
    Write-Info "Downloading scw-runner scripts..."

    $baseUrl = "https://raw.githubusercontent.com/Monitob/scw-runner/main"

    try {
        # Download run-scw.ps1
        $ps1Path = Join-Path $InstallDir "run-scw.ps1"
        Invoke-WebRequest -Uri "$baseUrl/run-scw.ps1" -OutFile $ps1Path -UseBasicParsing

        # Download .env.example
        $envPath = Join-Path $InstallDir ".env.example"
        Invoke-WebRequest -Uri "$baseUrl/.env.example" -OutFile $envPath -UseBasicParsing

        Write-Success "Scripts downloaded"
    } catch {
        Write-Error "Failed to download scripts: $_"
        throw
    }
}

# Add to PATH
function Add-ToPath {
    Write-Info "Adding scw-runner to PATH..."

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($currentPath -notlike "*$InstallDir*") {
        $newPath = $currentPath + ";" + $InstallDir
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "Added to PATH"
    } else {
        Write-Info "Already in PATH"
    }

    # Update current session
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "User")
}

# Create wrapper script
function New-WrapperScript {
    Write-Info "Creating wrapper script..."

    $wrapperPath = Join-Path $InstallDir "scw-runner.ps1"

    $wrapperContent = @"
#!/usr/bin/env pwsh
# scw-runner wrapper
& "$InstallDir\run-scw.ps1" `$args
"@

    Set-Content -Path $wrapperPath -Value $wrapperContent -Force

    Write-Success "Wrapper script created"
}

# Create example .env file
function New-EnvExample {
    Write-Info "Creating example environment file..."

    $envPath = Join-Path $InstallDir ".env.example"

    if (-not (Test-Path $envPath)) {
        $content = @"
# Scaleway CLI Configuration
# Copy to .env and fill in your credentials

SCW_ACCESS_KEY=SCWXXXXXXXXXXXXXXXXX
SCW_SECRET_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SCW_DEFAULT_ORGANIZATION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SCW_DEFAULT_REGION=fr-par
SCW_DEFAULT_ZONE=fr-par-1
"@
        Set-Content -Path $envPath -Value $content
    }

    Write-Success "Example environment file created"
}

# Create profile setup script
function New-ProfileSetup {
    Write-Info "Creating profile setup..."

    $profileSetup = @"
# scw-runner
`$env:Path += ";$InstallDir"
"@

    # Add to PowerShell profile if not already present
    if (Test-Path $PROFILE) {
        $profileContent = Get-Content $PROFILE -Raw
        if ($profileContent -notlike "*scw-runner*") {
            Add-Content -Path $PROFILE -Value "`n$profileSetup"
        }
    } else {
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
        Set-Content -Path $PROFILE -Value $profileSetup
    }

    Write-Success "Profile setup created"
}

# Main installation
function Main {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       scw-runner Installation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check for container runtime
    $runtime = Get-ContainerRuntime

    if (-not $runtime) {
        Write-Warning "No container runtime found (Podman or Docker)"

        if (Test-DockerDesktop) {
            Write-Info "Docker Desktop is installed but not running."
            Write-Info "Please start Docker Desktop and ensure it's running."

            if (-not $Force) {
                $answer = Read-Host "Start Docker Desktop now? [Y/n]"
                if ([string]::IsNullOrEmpty($answer) -or $answer -match '^[Yy]$') {
                    Start-Process "Docker Desktop"
                    Write-Info "Wait for Docker Desktop to start, then re-run this script."
                }
            }

            return
        }

        Write-Info "For Windows, Docker Desktop is recommended."
        Write-Info "Alternatively, use WSL2 with Podman or Docker."

        if (-not $Force) {
            $answer = Read-Host "Continue installation anyway? [Y/n]"
            if (-not ([string]::IsNullOrEmpty($answer) -or $answer -match '^[Yy]$')) {
                Write-Info "Installation cancelled. Install a container runtime first."
                return
            }
        }
    } else {
        Write-Success "Found container runtime: $runtime"
    }

    # Install
    New-InstallDirectories
    Invoke-DownloadScripts
    New-WrapperScript
    Add-ToPath
    New-EnvExample
    New-ProfileSetup

    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "          Installation Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Success "scw-runner installed successfully!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Restart PowerShell or run: Refresh-Env"
    Write-Host "  2. Copy and edit: Copy-Item $InstallDir\.env.example $InstallDir\.env"
    Write-Host "  3. Run: scw-runner version"
    Write-Host ""
    Write-Host "Or use directly: & '$InstallDir\run-scw.ps1' [command]"
    Write-Host ""

    # Test installation
    if (Get-Command scw-runner -ErrorAction SilentlyContinue) {
        Write-Info "Testing installation..."
        & scw-runner version 2>$null
    }
}

# Run installation
Main @PSBoundParameters
