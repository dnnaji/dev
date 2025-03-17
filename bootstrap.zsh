#!/bin/zsh

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Helper functions
print_info() { echo -e "${BLUE}ℹ ${RESET}$1"; }
print_success() { echo -e "${GREEN}✓ ${RESET}$1"; }
print_error() { echo -e "${RED}✗ ${RESET}$1" >&2; }
print_step() { echo -e "\n${BOLD}${BLUE}▶ $1${RESET}"; }

# Welcome message
echo -e "${BOLD}${BLUE}▶ MacBook Bootstrap - Initial Setup ${RESET}"
echo -e "${YELLOW}This script will install the minimum required tools${RESET}\n"

# 1. Install Xcode Command Line Tools (required for Git and Homebrew)
print_step "Installing Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please follow the prompts to complete Xcode installation."
    echo "Press any key when the installation is complete..."
    read -k 1
    if ! xcode-select -p >/dev/null 2>&1; then
        print_error "Xcode Command Line Tools installation failed."
        exit 1
    fi
    print_success "Xcode Command Line Tools installed successfully."
else
    print_success "Xcode Command Line Tools already installed."
fi

# 2. Install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed."
else
    print_success "Homebrew already installed."
fi

# 3. Install Fish shell and set as default
print_step "Installing Fish shell and setting as default"
if ! command -v fish >/dev/null 2>&1; then
    print_info "Installing Fish shell..."
    brew install fish
    print_success "Fish shell installed."
fi

if command -v fish >/dev/null 2>&1; then
    fish_path=$(which fish)
    
    # Ensure Fish is in /etc/shells
    if ! grep -q "$fish_path" /etc/shells; then
        print_info "Adding Fish to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
        print_success "Fish added to /etc/shells."
    fi

    if [[ "$SHELL" != "$fish_path" ]]; then
        print_info "Setting Fish as the default shell..."
        chsh -s "$fish_path"
        print_success "Fish is now your default shell."
    else
        print_success "Fish is already the default shell."
    fi
else
    print_error "Error: Fish shell installation failed."
    exit 1
fi

INSTALL_DIR=$(dirname "${(%):-%x}")

print_success "Initial bootstrap complete!"
print_info "To continue setup, run: fish run.fish"
echo ""
echo "You can customize the setup by editing the job files in $INSTALL_DIR/jobs/"

fish "$INSTALL_DIR/run.fish"