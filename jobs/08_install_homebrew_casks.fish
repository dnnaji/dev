#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Homebrew Cask Package Manager"

if not command_exists brew
    print_error "Homebrew not found. Please run the Homebrew setup first."
    exit 1
end

# Set the path for the Brewfile dedicated to Homebrew Cask packages
set caskfile_path "./casks.brewfile"

if test -f $caskfile_path
    print_info "Found existing casks.brewfile at $caskfile_path"
    
    if confirm "Would you like to edit your casks.brewfile?"
        vim $caskfile_path
        # Ask about installation after editing
        if confirm "Would you like to install cask packages from your casks.brewfile?"
            print_info "Installing cask packages from casks.brewfile..."
            brew bundle --file=$caskfile_path
            print_success "Cask packages installed!"
        end
    else
        if confirm "Would you like to install cask packages from your casks.brewfile?"
            print_info "Installing cask packages from casks.brewfile..."
            brew bundle --file=$caskfile_path
            print_success "Cask packages installed!"
        end
    end
else
    print_info "No casks.brewfile found at $caskfile_path"
    if confirm "Would you like to create a new casks.brewfile?"
        touch $caskfile_path
        print_success "Created new casks.brewfile."
        
        if confirm "Would you like to edit your new casks.brewfile?"
            vim $caskfile_path
            if confirm "Would you like to install cask packages from your casks.brewfile?"
                print_info "Installing cask packages from casks.brewfile..."
                brew bundle --file=$caskfile_path
                print_success "Cask packages installed!"
            end
        end
    end
end 