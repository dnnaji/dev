#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Setting up Git Configuration"

if not command_exists git
    print_error "Git not found. Please run the Homebrew setup first."
    exit 1
end

# Set Git email
set current_email (git config --global user.email || echo "")
if test -z "$current_email"
    if not set -q user_email
        set user_email (read_input "Enter your email for Git" "")
    end
    git config --global user.email "$user_email"
    print_success "Git email set to: $user_email"
else
    print_success "Git email already configured: $current_email"
    if confirm "Would you like to update your Git email?"
        set new_email (read_input "Enter your new email for Git" "$current_email")
        git config --global user.email "$new_email"
        print_success "Git email updated to: $new_email"
    end
end

# Set Git name
set current_name (git config --global user.name || echo "")
if test -z "$current_name"
    set git_name (read_input "Enter your name for Git" "")
    git config --global user.name "$git_name"
    print_success "Git name set to: $git_name"
else
    print_success "Git name already configured: $current_name"
    if confirm "Would you like to update your Git name?"
        set new_name (read_input "Enter your new name for Git" "$current_name")
        git config --global user.name "$new_name"
        print_success "Git name updated to: $new_name"
    end
end

# Set additional Git configs
git config --global init.defaultBranch main
git config --global pull.rebase false
print_success "Git default configurations set (main branch, merge strategy)" 