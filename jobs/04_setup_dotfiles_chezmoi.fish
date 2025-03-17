#!/usr/bin/env fish

# This job script sets up dotfiles using Chezmoi on a fresh MacBook Air setup.
# It is intended to be run after SSH key and basic tool setups.

# Check if chezmoi is installed; if not, install via Homebrew
if not command_exists chezmoi
    print_info "Chezmoi not found. Installing Chezmoi..."
    brew install chezmoi
    if test $status -eq 0
        print_success "Chezmoi installed successfully."
    else
        print_error "Chezmoi installation failed."
        exit 1
    end
else
    print_info "Chezmoi is already installed."
end

# Prompt for dotfiles repository URL if not already set
if not set -q DOTFILES_REPO
    set -l repo (read_input "Enter your dotfiles repository URL (or leave blank to skip):" "")
    if test -z "$repo"
        print_warning "No dotfiles repository provided. Skipping Chezmoi initialization."
        exit 0
    else
        set -g DOTFILES_REPO $repo
    end
end

# Initialize Chezmoi if not already initialized
if not test -d "$HOME/.local/share/chezmoi"
    print_info "Initializing Chezmoi with repository $DOTFILES_REPO..."
    chezmoi init --apply $DOTFILES_REPO
    if test $status -eq 0
        print_success "Chezmoi dotfiles applied successfully."
    else
        print_error "Chezmoi dotfiles application failed."
        exit 1
    end
else
    print_info "Chezmoi is already initialized. Running chezmoi apply..."
    chezmoi apply
    if test $status -eq 0
        print_success "Chezmoi dotfiles applied successfully."
    else
        print_error "Chezmoi dotfiles application failed."
        exit 1
    end
end
