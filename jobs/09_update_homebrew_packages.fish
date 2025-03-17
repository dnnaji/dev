#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Setting up Brew Update Script"

if not command_exists brew
    print_error "Homebrew not found. Please run the Homebrew setup first."
    exit 1
end

# Install gum if not already installed
if not command_exists gum
    print_info "Installing gum..."
    brew install gum
    print_success "gum installed successfully."
else
    print_success "gum is already installed."
end

# Create ~/.config/bin directory if it doesn't exist
set config_bin_dir ~/.config/bin
if not test -d $config_bin_dir
    print_info "Creating ~/.config/bin directory..."
    mkdir -p $config_bin_dir
    print_success "Created ~/.config/bin directory."
else
    print_success "~/.config/bin directory already exists."
end

# Create the brew update script
set brew_script $config_bin_dir/b
print_info "Creating brew update script at $brew_script..."

echo '#!/usr/bin/env bash

gum style \
  --foreground 12 --border-foreground 12 --border double \
  --align center --width 50 --margin "1 0" --padding "1 2" \
  '"'"'██████╗ ██████╗ ███████╗██╗    ██╗
██╔══██╗██╔══██╗██╔════╝██║    ██║
██████╔╝██████╔╝█████╗  ██║ █╗ ██║
██╔══██╗██╔══██╗██╔══╝  ██║███╗██║
██████╔╝██║  ██║███████╗╚███╔███╔╝
╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝'"'"'

gum spin --show-output --spinner minidot --title "Updating brew..." -- brew update
printf "\n"

OUTDATED=$(gum spin --show-output --spinner minidot --title "Checking for outdated brew packages" -- brew outdated)

if [[ -n "$OUTDATED" ]]; then
  echo "$OUTDATED"
  gum confirm --selected.background=2 --selected.foreground=0 "Upgrade the outdated formulae above?" && brew upgrade
  printf "\n"
  brew cleanup --prune=all
  printf "\n"
else
  echo "All brew packages are up to date."
  printf "\n"
fi

gum spin --show-output --spinner minidot --title "Checking for brew issues..." -- brew doctor' > $brew_script

# Make the script executable
print_info "Making the script executable..."
chmod +x $brew_script
print_success "Script is now executable."

# Add to PATH if not already there
set fish_conf_dir ~/.config/fish
set fish_conf_path $fish_conf_dir/config.fish
set fish_path_conf $fish_conf_dir/conf.d/user_path.fish

# Check if the directory is already in PATH
if not string match -q "*$config_bin_dir*" $PATH
    print_info "Adding ~/.config/bin to your PATH..."
    
    # Create conf.d directory if it doesn't exist
    if not test -d $fish_conf_dir/conf.d
        mkdir -p $fish_conf_dir/conf.d
    end
    
    # Create or append to user_path.fish
    if not test -f $fish_path_conf
        echo '# User custom PATH additions' > $fish_path_conf
        echo 'set -gx PATH ~/.config/bin $PATH' >> $fish_path_conf
    else
        # Check if the path is already in the file
        if not grep -q "set -gx PATH ~/.config/bin" $fish_path_conf
            echo 'set -gx PATH ~/.config/bin $PATH' >> $fish_path_conf
        end
    end
    
    print_success "Added ~/.config/bin to your PATH."
    print_info "Run 'source $fish_path_conf' to apply the changes to your current session."
else
    print_success "~/.config/bin is already in your PATH."
end

print_success "Brew update script setup complete!"
print_info "You can now run 'b' to update your Homebrew packages." 