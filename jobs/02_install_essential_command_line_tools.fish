#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Installing Essential Command Line Tools"

if not command_exists brew
    print_error "Homebrew not found. Please run the bootstrap script first."
    exit 1
end

# Install essential command line tools
print_info "Installing essential command line tools..."
set essential_tools git gh chezmoi jq fzf zoxide bat eza fd ripgrep expect

for tool in $essential_tools
    if not command_exists $tool
        print_info "Installing $tool..."
        brew install $tool
        print_success "$tool installed."
    else
        print_success "$tool is already installed."
    end
end 

# Configure tools
print_info "Configuring installed tools..."

# Configure zoxide
if command_exists zoxide
    print_info "Configuring zoxide..."
    
    # Create the conf.d directory if it doesn't exist
    if not test -d "$HOME/.config/fish/conf.d"
        mkdir -p "$HOME/.config/fish/conf.d"
    end
    
    # Add zoxide init to fish config if not already there
    if not test -f "$HOME/.config/fish/conf.d/zoxide.fish"
        zoxide init fish > "$HOME/.config/fish/conf.d/zoxide.fish"
        print_success "zoxide configured."
    else
        print_success "zoxide is already configured."
    end
end

# Configure fzf
if command_exists fzf
    print_info "Configuring fzf..."
    
    # Create the conf.d directory if it doesn't exist
    if not test -d "$HOME/.config/fish/conf.d"
        mkdir -p "$HOME/.config/fish/conf.d"
    end
    
    # Install fzf fish integration if needed
    set fzf_fish_path (brew --prefix)/opt/fzf/shell/key-bindings.fish
    if test -f $fzf_fish_path
        # Copy fzf key bindings to fish functions directory
        if not test -d "$HOME/.config/fish/functions"
            mkdir -p "$HOME/.config/fish/functions"
        end
        
        # Copy key-bindings.fish to the functions directory as fzf_key_bindings.fish
        cp $fzf_fish_path "$HOME/.config/fish/functions/fzf_key_bindings.fish"
        
        # Add fzf key bindings to Fish if not already configured
        if not test -f "$HOME/.config/fish/conf.d/fzf.fish"
            echo "# fzf.fish - Add fzf key bindings" > "$HOME/.config/fish/conf.d/fzf.fish"
            echo "if command -q fzf" >> "$HOME/.config/fish/conf.d/fzf.fish"
            echo "    fzf_key_bindings" >> "$HOME/.config/fish/conf.d/fzf.fish"
            echo "end" >> "$HOME/.config/fish/conf.d/fzf.fish"
            print_success "fzf key bindings configured."
        else
            print_success "fzf is already configured."
        end
    else
        print_warning "fzf key-bindings.fish not found at $fzf_fish_path. Try running 'brew reinstall fzf'."
    end
end

# Configure bat (syntax highlighting for cat)
if command_exists bat
    print_info "Configuring bat..."
    
    # Create bat config directory if it doesn't exist
    if not test -d "$HOME/.config/bat"
        mkdir -p "$HOME/.config/bat"
    end
    
    # Create a basic config file if it doesn't exist
    if not test -f "$HOME/.config/bat/config"
        echo "# Bat Configuration File" > "$HOME/.config/bat/config"
        echo "--theme=\"Monokai Extended\"" >> "$HOME/.config/bat/config"
        echo "--style=\"numbers,changes,header\"" >> "$HOME/.config/bat/config"
        echo "--map-syntax \"*.fish:Fish\"" >> "$HOME/.config/bat/config"
        print_success "bat configured."
    else
        print_success "bat is already configured."
    end
end

# Configure eza (modern ls replacement - successor to exa)
if command_exists eza
    print_info "Configuring eza aliases..."
    
    # Create the conf.d directory if it doesn't exist
    if not test -d "$HOME/.config/fish/conf.d"
        mkdir -p "$HOME/.config/fish/conf.d"
    end
    
    # Add eza aliases if not already configured
    if not test -f "$HOME/.config/fish/conf.d/eza.fish"
        echo "# eza.fish - Better ls commands" > "$HOME/.config/fish/conf.d/eza.fish"
        echo "if command -q eza" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "    alias ls='eza'" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "    alias ll='eza -l -g --icons'" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "    alias la='eza -a --icons'" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "    alias lt='eza --tree --icons'" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "    alias lla='eza -la --icons'" >> "$HOME/.config/fish/conf.d/eza.fish"
        echo "end" >> "$HOME/.config/fish/conf.d/eza.fish"
        print_success "eza aliases configured."
    else
        print_success "eza is already configured."
    end
    
    # Remove old exa config if it exists
    if test -f "$HOME/.config/fish/conf.d/exa.fish"
        print_info "Removing old exa configuration..."
        rm "$HOME/.config/fish/conf.d/exa.fish"
        print_success "Old exa configuration removed."
    end
end

print_success "Essential CLI tools setup complete!"