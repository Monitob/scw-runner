#!/bin/bash
#
# install.sh - Install scw-runner locally
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Monitob/scw-runner/main/install.sh | bash
# Or: ./install.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${SCW_RUNNER_INSTALL_DIR:-$HOME/.local/bin}"
SCRIPTS_DIR="${SCW_RUNNER_SCRIPTS_DIR:-$HOME/.local/share/scw-runner}"

# Print functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running in CI or non-interactive mode
is_non_interactive() {
    [ -n "$CI" ] || [ -n "$NONINTERACTIVE" ] || ! [ -t 0 ]
}

# Prompt for confirmation
prompt() {
    if is_non_interactive; then
        return 0
    fi
    read -p "$1 [Y/n] " confirm
    if [ -z "$confirm" ] || [ "$confirm" = "Y" ] || [ "$confirm" = "y" ]; then
        return 0
    fi
    return 1
}

# Detect container runtime
detect_container_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

# Install Podman
install_podman() {
    print_info "Installing Podman..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                sudo apt-get update
                sudo apt-get install -y podman
                ;;
            fedora|rhel|centlos|rocky|almalinux)
                sudo dnf install -y podman
                ;;
            opensuse|suse|opensuse-tumbleweed)
                sudo zypper install -y podman
                ;;
            arch|manjaro|endeavouros)
                sudo pacman -S --noconfirm podman
                ;;
            *)
                print_warning "Unknown distribution: $ID"
                print_info "Please install Podman manually: https://podman.io/docs/installation"
                return 1
                ;;
        esac
    else
        print_warning "Cannot detect distribution. Please install Podman manually."
        return 1
    fi

    print_success "Podman installed"
}

# Install Docker
install_docker() {
    print_info "Installing Docker..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                curl -fsSL https://get.docker.com | sh
                ;;
            fedora|rhel|centlos|rocky|almalinux)
                curl -fsSL https://get.docker.com | sh
                ;;
            *)
                print_warning "Unknown distribution: $ID"
                print_info "Please install Docker manually: https://docs.docker.com/get-docker/"
                return 1
                ;;
        esac
    else
        print_warning "Cannot detect distribution. Please install Docker manually."
        return 1
    fi

    print_success "Docker installed"

    # Add user to docker group (Linux only)
    if command -v groupadd &> /dev/null && [ "$(id -u)" -ne 0 ]; then
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        print_info "Added user to docker group (log out and back in for changes to take effect)"
    fi
}

# Create directories
create_directories() {
    print_info "Creating directories..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SCRIPTS_DIR"

    print_success "Directories created"
}

# Download scripts
download_scripts() {
    print_info "Downloading scw-runner scripts..."

    local base_url="https://raw.githubusercontent.com/Monitob/scw-runner/main"

    curl -fsSL "$base_url/run-scw.sh" -o "$SCRIPTS_DIR/run-scw.sh"
    curl -fsSL "$base_url/.env.example" -o "$SCRIPTS_DIR/.env.example"

    chmod +x "$SCRIPTS_DIR/run-scw.sh"

    print_success "Scripts downloaded"
}

# Create wrapper script
create_wrapper() {
    print_info "Creating wrapper script in $INSTALL_DIR..."

    cat > "$INSTALL_DIR/scw-runner" << 'EOF'
#!/bin/bash
# scw-runner wrapper script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../share/scw-runner/run-scw.sh" "$@"
EOF

    # Update wrapper with actual paths
    sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$(dirname "$INSTALL_DIR")\"|" "$INSTALL_DIR/scw-runner"
    sed -i "s|exec.*|exec \"\$SCRIPT_DIR/share/scw-runner/run-scw.sh\" \"\$@\"|" "$INSTALL_DIR/scw-runner"

    chmod +x "$INSTALL_DIR/scw-runner"

    print_success "Wrapper script created"
}

# Setup shell configuration
setup_shell_config() {
    print_info "Setting up shell configuration..."

    local shell_rc=""
    local export_line="export PATH=\"$INSTALL_DIR:\$PATH\""

    # Detect shell and appropriate rc file
    if [ -n "$ZSH_VERSION" ] || [ -n "$ZSH_NAME" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi

    # Add to PATH if not already present
    if [ -f "$shell_rc" ] && ! grep -q "$INSTALL_DIR" "$shell_rc"; then
        echo "" >> "$shell_rc"
        echo "# scw-runner" >> "$shell_rc"
        echo "$export_line" >> "$shell_rc"
        print_info "Added scw-runner to PATH in $shell_rc"
        print_info "Run 'source $shell_rc' or restart your terminal to use scw-runner"
    elif ! grep -q "$INSTALL_DIR" "$HOME/.profile" 2>/dev/null; then
        echo "" >> "$HOME/.profile"
        echo "# scw-runner" >> "$HOME/.profile"
        echo "$export_line" >> "$HOME/.profile"
    fi

    # Export PATH for current session
    export PATH="$INSTALL_DIR:$PATH"

    print_success "Shell configuration updated"
}

# Create example .env file
setup_env_example() {
    print_info "Creating example environment file..."

    local env_file="$SCRIPTS_DIR/.env.example"

    if [ ! -f "$env_file" ]; then
        cat > "$env_file" << 'EOF'
# Scaleway CLI Configuration
# Copy to .env and fill in your credentials

SCW_ACCESS_KEY=SCWXXXXXXXXXXXXXXXXX
SCW_SECRET_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SCW_DEFAULT_ORGANIZATION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SCW_DEFAULT_REGION=fr-par
SCW_DEFAULT_ZONE=fr-par-1
EOF
    fi

    print_success "Example environment file created at $env_file"
}

# Main installation
main() {
    echo ""
    echo "========================================"
    echo "       scw-runner Installation"
    echo "========================================"
    echo ""

    # Check for container runtime
    local runtime
    runtime=$(detect_container_runtime)

    if [ -z "$runtime" ]; then
        print_warning "No container runtime found (Podman or Docker)"

        if prompt "Would you like to install Podman?"; then
            install_podman || {
                print_warning "Podman installation failed. Trying Docker..."
                install_docker || {
                    print_error "Failed to install container runtime. Please install manually and re-run."
                    exit 1
                }
            }
        else
            print_info "Skipping container runtime installation."
            print_info "Please install Podman or Docker manually before using scw-runner."
        fi
    else
        print_success "Found container runtime: $runtime"
    fi

    # Create directories and download scripts
    create_directories
    download_scripts
    create_wrapper
    setup_shell_config
    setup_env_example

    # Summary
    echo ""
    echo "========================================"
    echo "          Installation Complete"
    echo "========================================"
    echo ""
    print_success "scw-runner installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: source ~/.bashrc  (or restart terminal)"
    echo "  2. Copy and edit: cp $SCRIPTS_DIR/.env.example $SCRIPTS_DIR/.env"
    echo "  3. Run: scw-runner version"
    echo ""
    echo "Or use directly: $SCRIPTS_DIR/run-scw.sh [command]"
    echo ""

    # Show version if available
    if command -v scw-runner &> /dev/null; then
        echo "Testing installation..."
        scw-runner version 2>/dev/null || print_info "Run 'source ~/.bashrc' to enable scw-runner command"
    fi
}

# Run installation
main "$@"
