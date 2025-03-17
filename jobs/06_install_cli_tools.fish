#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Homebrew CLI Tools and Utilities"

if not command_exists brew
    print_error "Homebrew not found. Please run the Homebrew setup first."
    exit 1
end

# Check for existing Brewfile
set brewfile_path "./cli.brewfile"

# Check for existing Brewfile
if test -f $brewfile_path
    print_info "Found existing cli.brewfile at $brewfile_path"
    
    if confirm "Would you like to edit your cli.brewfile? (CLI tools and utilities only, not casks)"
        print_info "Note: Please only include CLI tools using 'brew' commands. For GUI applications, use casks.brewfile instead."
        vim $brewfile_path
        # Default to asking about installation after editing
        if confirm "Would you like to install CLI packages from your cli.brewfile?"
            print_info "Installing CLI packages from cli.brewfile..."
            brew bundle --file=$brewfile_path
            print_success "CLI packages installed!"
        end
    else
        # Still ask about installation if the user didn't want to edit
        if confirm "Would you like to install CLI packages from your cli.brewfile?"
            print_info "Installing CLI packages from cli.brewfile..."
            brew bundle --file=$brewfile_path
            print_success "CLI packages installed!"
        end
    end
else
    print_info "No cli.brewfile found at $brewfile_path"
    if confirm "Would you like to create a new cli.brewfile for CLI tools and utilities?"
        touch $brewfile_path
        print_success "Created new cli.brewfile."
        
        print_info "cli.brewfile should contain only CLI tools and utilities using 'brew' commands."
        print_info "Example format:
# CLI tools
brew \"git\"
brew \"curl\"
brew \"fish\"
# Do NOT include cask applications here - use casks.brewfile instead
"
        
        if confirm "Would you like to edit your new cli.brewfile?"
            vim $brewfile_path
            # Default to asking about installation after creating and editing
            if confirm "Would you like to install CLI packages from your cli.brewfile?"
                print_info "Installing CLI packages from cli.brewfile..."
                brew bundle --file=$brewfile_path
                print_success "CLI packages installed!"
            end
        end
    end
end 