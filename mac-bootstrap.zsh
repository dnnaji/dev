#!/bin/zsh

# Colors & Formatting
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

# Track setup progress 
TOTAL_STEPS=9
CURRENT_STEP=0

# Helper Functions
command_exists() { command -v "$1" &> /dev/null; }

print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "\n${BOLD}${PURPLE}[${CURRENT_STEP}/${TOTAL_STEPS}] $1 ${RESET}\n"
}

print_success() { echo "${GREEN}✓ $1${RESET}"; }
print_info() { echo "${BLUE}ℹ $1${RESET}"; }
print_warning() { echo "${YELLOW}⚠ $1${RESET}"; }
print_error() { echo "${RED}✗ $1${RESET}" >&2; }

install_package() {
    local package_name=$1
    echo "${CYAN}→ Installing ${BOLD}$package_name${RESET}${CYAN}...${RESET}"
    if brew list "$package_name" &>/dev/null; then
        print_warning "$package_name is already installed."
    else
        brew install "$package_name" && print_success "$package_name installed!"
    fi
}

# Config Variables
ENABLE_CHEZMOI=false  # Set to false to skip the Chezmoi step

# Welcome message
echo "${BOLD}${BLUE}┌────────────────────────────────────────┐${RESET}"
echo "${BOLD}${BLUE}│   Macbook Fresh Installation Setup  │${RESET}"
echo "${BOLD}${BLUE}└────────────────────────────────────────┘${RESET}\n"
echo "${YELLOW}This script will guide you through ${BOLD}${TOTAL_STEPS}${RESET}${YELLOW} setup steps${RESET}"

# Step 1: Install Xcode Command Line Tools
print_step "Installing Xcode Command Line Tools"
if ! xcode-select -p &> /dev/null; then
    print_info "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    print_info "Please follow the prompts to complete the installation."
else
    print_success "Xcode Command Line Tools are already installed."
fi

# Step 2: Install Homebrew
print_step "Installing Homebrew"
if ! command_exists brew; then
    print_info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    if command_exists brew; then
        # Add Homebrew to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
        print_success "Homebrew installed successfully!"
    else
        print_error "Homebrew installation failed. Please install manually."
        exit 1
    fi
else
    print_success "Homebrew is already installed."
fi

# Step 3: Install essential packages directly
print_step "Installing Essential Packages"
install_package "git"
install_package "gh"
install_package "chezmoi"
install_package "fish"
install_package "bitwarden-cli"

# Step 4: Set Fish as the default shell
print_step "Configuring Fish as Default Shell"
if command_exists fish; then
    fish_path=$(which fish)
    if [[ "$SHELL" != "$fish_path" ]]; then
        print_info "Setting Fish as the default shell..."
        chsh -s "$fish_path"
        print_success "Fish is now your default shell."
    else
        print_success "Fish is already the default shell."
    fi
else
    print_error "Error: Fish shell not found. Installation may have failed."
    exit 1
fi

# Step 5: Generate a new SSH key
print_step "Generating SSH Key"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    print_info "No ED25519 SSH key found. Generating a new one..."
    echo -n "Enter your email for the SSH key: "
    read email
    echo -n "Enter a secure passphrase for the SSH key: "
    read -s passphrase
    echo
    ssh-keygen -t ed25519 -C "$email" -N "$passphrase" -f ~/.ssh/id_ed25519
    print_success "SSH key generated successfully."
else
    print_success "SSH key already exists at ~/.ssh/id_ed25519."
fi

# Step 6: Add SSH key to ssh-agent
print_step "Adding SSH Key to ssh-agent"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
print_success "SSH key added to ssh-agent."

# Step 7: Authenticate GitHub CLI
print_step "Authenticating GitHub CLI"
if command_exists gh; then
    if ! gh auth status &> /dev/null; then
        print_info "GitHub CLI not authenticated. Logging in..."
        gh auth login
        print_success "GitHub CLI authenticated successfully."
    else
        print_success "GitHub CLI is already authenticated."
    fi
else
    print_error "Error: GitHub CLI (gh) not found. Installation failed."
    exit 1
fi

# Step 8: Upload SSH key to GitHub
print_step "Uploading SSH Key to GitHub"
print_info "Setting SSH key title for GitHub..."
echo -n "Enter SSH key title [MacBook Setup Key]: "
read ssh_key_title
ssh_key_title=${ssh_key_title:-"MacBook Setup Key"}
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$ssh_key_title"
print_success "SSH key uploaded to GitHub with title: $ssh_key_title"

# Step 9: Initialize Chezmoi and apply dot files (conditional)
print_step "Setting Up Dot Files with Chezmoi"
if [ "$ENABLE_CHEZMOI" = true ]; then
    if command_exists chezmoi; then
        print_info "Setting up dotfiles with Chezmoi..."
        echo -n "Enter your dot files repository URL: "
        read repo_url
        print_info "Initializing Chezmoi with $repo_url..."
        chezmoi init --apply "$repo_url"
        print_success "Dot files applied successfully."
    else
        print_error "Error: Chezmoi not found. Installation failed."
        exit 1
    fi
else
    print_warning "Chezmoi step is disabled (ENABLE_CHEZMOI=false)."
fi

# Completion message
echo "\n${BOLD}${GREEN}✅ Setup Complete! [${CURRENT_STEP}/${TOTAL_STEPS}]${RESET}"
echo "${GREEN}${BOLD}✨ Your MacBook Air is now set up with:${RESET}"
echo "  ${CYAN}• Fish as the default shell${RESET}"
echo "  ${CYAN}• Essential development tools${RESET}"
echo "  ${CYAN}• SSH keys configured${RESET}"
if [ "$ENABLE_CHEZMOI" = true ]; then
    echo "  ${CYAN}• Dot files applied with Chezmoi${RESET}"
fi
echo "\n${YELLOW}${BOLD}Tip:${RESET}${YELLOW} Restart your terminal or run '${BOLD}fish${RESET}${YELLOW}' to switch shells.${RESET}"