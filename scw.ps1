#!/usr/bin/env pwsh
#
# scw.ps1 - Helper function to load .env and run Scaleway CLI via Podman
#
# Usage: .\scw.ps1 [scw arguments...]
# Example: .\scw.ps1 instance list
#

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

# Load .env file if it exists
$EnvFile = Join-Path $ScriptDir ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)\s*=\s*(.+)\s*$') {
            $varName = $matches[1].Trim()
            $varValue = $matches[2].Trim()
            # Remove surrounding quotes if present
            if ($varValue -match '^["''](.+)["'']$') {
                $varValue = $matches[1]
            }
            Set-Item -Path "env:$varName" -Value $varValue
        }
    }
}

# Execute run-scw.ps1 with all arguments
$RunScwPath = Join-Path $ScriptDir "run-scw.ps1"
& $RunScwPath @args