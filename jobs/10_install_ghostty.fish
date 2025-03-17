#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Installing and Setting up Ghostty"

if not command_exists brew
    print_error "Homebrew not found. Please run the Homebrew setup first."
    exit 1
end

# Check if Ghostty is already installed
if not test -d "/Applications/Ghostty.app"
    print_info "Installing Ghostty..."
    brew install --cask ghostty
    print_success "Ghostty installed successfully."
else
    print_success "Ghostty is already installed."
end

# Set up Ghostty configuration
set -l config_dir "$HOME/.config/ghostty"
if not test -d $config_dir
    print_info "Creating Ghostty configuration directory..."
    mkdir -p $config_dir
    print_success "Created Ghostty configuration directory."
else
    print_success "Ghostty configuration directory already exists."
end

# Create basic configuration if it doesn't exist
set -l config_file "$config_dir/config"
if not test -f $config_file
    print_info "Creating basic Ghostty configuration..."
    echo "# Ghostty configuration" > $config_file
    echo "font-family = JetBrains Mono" >> $config_file
    echo "font-size = 14" >> $config_file
    echo "window-theme = dark" >> $config_file
    echo "window-decoration = false" >> $config_file
    echo "window-padding-x = 10" >> $config_file
    echo "window-padding-y = 10" >> $config_file
    
    # Theme settings
    echo "" >> $config_file
    echo "# Theme" >> $config_file
    echo "theme = rose-pine" >> $config_file
    echo "background-opacity = 0.95" >> $config_file
    echo "background = #150d29" >> $config_file
    echo "cursor-invert-fg-bg = true" >> $config_file
    echo "cursor-style = block" >> $config_file
    echo "shell-integration-features = no-cursor" >> $config_file
    
    # Ligature settings
    echo "" >> $config_file
    echo "# Disable ligatures" >> $config_file
    echo "font-feature = -calt" >> $config_file
    echo "font-feature = -liga" >> $config_file
    echo "font-feature = -dlig" >> $config_file
    
    print_success "Created basic Ghostty configuration."
else
    print_success "Ghostty configuration already exists."
end

print_success "Ghostty setup complete!"
print_info "You can now launch Ghostty from your Applications folder." 