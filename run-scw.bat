@echo off
REM
REM run-scw.bat - Windows batch wrapper to run Scaleway CLI via Podman/Docker
REM
REM Usage: run-scw.bat [scw arguments...]
REM Example: run-scw.bat instance list
REM
REM Environment variables (set before running):
REM   SCW_ACCESS_KEY                  - Your Scaleway access key
REM   SCW_SECRET_KEY                  - Your Scaleway secret key
REM   SCW_DEFAULT_ORGANIZATION_ID     - Default organization ID
REM   SCW_DEFAULT_REGION              - Default region (e.g., fr-par)
REM   SCW_DEFAULT_ZONE                - Default zone (e.g., fr-par-1)
REM   SCW_PROFILE                     - Configuration profile name
REM   SCW_CONFIG_PATH                 - Path to config file
REM   SCW_RUNNER_IMAGE                - Container image (default: scaleway/cli:latest)
REM   SCW_RUNNER_RUNTIME              - Force runtime: "podman" or "docker"
REM

setlocal enabledelayedexpansion

REM Detect container runtime
set RUNTIME=
if not "%SCW_RUNNER_RUNTIME%"=="" set RUNTIME=%SCW_RUNNER_RUNTIME%

if "%RUNTIME%"=="" where podman >nul 2>&1 && set RUNTIME=podman
if "%RUNTIME%"=="" where docker >nul 2>&1 && set RUNTIME=docker

if "%RUNTIME%"=="" (
    echo Error: Neither podman nor docker found. Please install one of them. ^(>&2^)
    echo   Set SCW_RUNNER_RUNTIME to force a specific runtime. ^(>&2^)
    exit /b 1
)

set IMAGE=%SCW_RUNNER_IMAGE%
if "%IMAGE%"=="" set IMAGE=scaleway/cli:latest

REM Build the docker run command
set DOCKER_CMD=%RUNTIME% run -i --rm

REM Pass through SCW_* environment variables if set
if defined SCW_ACCESS_KEY set DOCKER_CMD=!DOCKER_CMD! -e SCW_ACCESS_KEY
if defined SCW_SECRET_KEY set DOCKER_CMD=!DOCKER_CMD! -e SCW_SECRET_KEY
if defined SCW_DEFAULT_ORGANIZATION_ID set DOCKER_CMD=!DOCKER_CMD! -e SCW_DEFAULT_ORGANIZATION_ID
if defined SCW_DEFAULT_REGION set DOCKER_CMD=!DOCKER_CMD! -e SCW_DEFAULT_REGION
if defined SCW_DEFAULT_ZONE set DOCKER_CMD=!DOCKER_CMD! -e SCW_DEFAULT_ZONE
if defined SCW_PROFILE set DOCKER_CMD=!DOCKER_CMD! -e SCW_PROFILE
if defined SCW_CONFIG_PATH set DOCKER_CMD=!DOCKER_CMD! -e SCW_CONFIG_PATH

REM Mount current directory and set working directory
set DOCKER_CMD=!DOCKER_CMD! -v "%CD%":/workspace -w /workspace

REM Add image and arguments
set DOCKER_CMD=!DOCKER_CMD! %IMAGE% %*

REM Execute
%DOCKER_CMD%
