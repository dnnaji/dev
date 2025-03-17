#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Setting up Homebrew"

if not command_exists brew
    print_error "Homebrew not found. Please run the bootstrap script first."
    exit 1
end

# Update Homebrew
print_info "Updating Homebrew..."
brew update

# Add Homebrew to fish shell
if not test -f ~/.config/fish/conf.d/homebrew.fish
    print_info "Adding Homebrew to fish configuration..."
    mkdir -p ~/.config/fish/conf.d
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' > ~/.config/fish/conf.d/homebrew.fish
    chmod +x ~/.config/fish/conf.d/homebrew.fish
    print_success "Homebrew configured with fish."
else
    print_success "Homebrew is already configured with fish."
end 