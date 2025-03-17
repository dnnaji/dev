#!/usr/bin/env fish

# Load utilities if not already loaded
if not set -q color_blue
    source ../lib/utils.fish
end

print_step "Programming Languages Installation"

if not command_exists brew
    print_error "Homebrew not found. Please run the Homebrew setup first."
    exit 1
end

# Function to install and configure a language
function setup_language
    set -l lang_name $argv[1]
    set -l brew_packages $argv[2..-1]
    
    print_info "Setting up $lang_name..."
    
    # Ask user if they want to install this language
    if gum confirm --selected.background=2 --selected.foreground=0 "Install $lang_name and its tools?"
        # Install the language and tools
        for package in $brew_packages
            if not brew list $package &>/dev/null
                print_info "Installing $package..."
                gum spin --spinner minidot --title "Installing $package..." -- brew install $package
                if test $status -eq 0
                    print_success "$package installed successfully."
                else
                    print_error "Failed to install $package."
                    return 1
                end
            else
                print_success "$package is already installed."
            end
        end
        
        # Run language-specific post-installation steps
        switch $lang_name
            case "Node.js"
                setup_nodejs
            case "Ruby"
                setup_ruby
            case "Go"
                setup_go
        end
        
        print_success "$lang_name setup complete!"
    else
        print_info "Skipping $lang_name installation."
    end
    
    return 0
end

# Node.js specific setup
function setup_nodejs
    # Create default npm global directory
    set npm_dir ~/.npm-global
    if not test -d $npm_dir
        print_info "Creating npm global directory..."
        mkdir -p $npm_dir
        npm config set prefix $npm_dir
        
        # Update PATH in fish config
        set fish_path_conf ~/.config/fish/conf.d/npm_path.fish
        echo "set -gx PATH $npm_dir/bin \$PATH" > $fish_path_conf
        
        print_success "Created npm global directory and updated PATH."
    end
    
    # Install commonly used global packages
    set -l npm_packages "typescript" "ts-node" "eslint" "prettier"
    
    print_info "Would you like to install these common Node.js packages?"
    echo (set_color yellow)"$npm_packages"(set_color normal)
    
    if gum confirm --selected.background=2 --selected.foreground=0
        print_info "Installing global npm packages..."
        gum spin --spinner minidot --title "Installing global npm packages..." -- npm install -g $npm_packages
        print_success "Global npm packages installed."
    end
    
    # Set up n as Node.js version manager
    if command_exists n
        print_info "Setting up n as Node.js version manager..."
        
        # Create n prefix directory
        set n_prefix ~/.n
        if not test -d $n_prefix
            mkdir -p $n_prefix
        end
        
        # Configure n in fish config
        set n_conf_path ~/.config/fish/conf.d/n.fish
        echo "# n (Node.js version manager) configuration" > $n_conf_path
        echo "set -gx N_PREFIX $n_prefix" >> $n_conf_path
        echo "set -gx PATH \$N_PREFIX/bin \$PATH" >> $n_conf_path
        
        print_success "n configured successfully."
        
        # Install latest LTS Node.js version
        print_info "Installing latest LTS Node.js version..."
        gum spin --spinner minidot --title "Installing Node.js LTS..." -- n lts
        print_success "Node.js LTS installed."
    end
end

# Ruby specific setup
function setup_ruby
    if command_exists rbenv
        print_info "Setting up rbenv Ruby environment..."
        
        # Initialize rbenv in fish config
        set rbenv_conf_path ~/.config/fish/conf.d/rbenv.fish
        echo "# rbenv initialization" > $rbenv_conf_path
        echo "status --is-interactive; and source (rbenv init -|psub)" >> $rbenv_conf_path
        
        # Install latest stable Ruby
        print_info "Installing latest stable Ruby version..."
        set latest_ruby (rbenv install -l | grep -v - | tail -1 | tr -d ' ')
        gum spin --spinner minidot --title "Installing Ruby $latest_ruby..." -- rbenv install $latest_ruby
        rbenv global $latest_ruby
        
        # Install common gems
        set -l gems "bundler" "pry" "rubocop"
        print_info "Installing common Ruby gems..."
        gum spin --spinner minidot --title "Installing Ruby gems..." -- gem install $gems
        
        print_success "Ruby environment setup complete."
    end
end

# Go specific setup
function setup_go
    print_info "Setting up Go environment..."
    
    # Create Go workspace directories
    set go_path $HOME/go
    set go_dirs "bin" "pkg" "src"
    
    for dir in $go_dirs
        set full_path $go_path/$dir
        if not test -d $full_path
            mkdir -p $full_path
        end
    end
    
    # Configure GOPATH in fish config
    set go_conf_path ~/.config/fish/conf.d/go.fish
    echo "# Go configuration" > $go_conf_path
    echo "set -gx GOPATH $go_path" >> $go_conf_path
    echo "set -gx PATH \$GOPATH/bin \$PATH" >> $go_conf_path
    
    # Install common Go tools
    set -l go_tools "golang.org/x/tools/cmd/goimports@latest" "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    
    print_info "Installing common Go tools..."
    for tool in $go_tools
        gum spin --spinner minidot --title "Installing $tool..." -- go install $tool
    end
    
    print_success "Go environment setup complete."
end

# Install gum if not already installed (for interactive prompts)
if not command_exists gum
    print_info "Installing gum for interactive prompts..."
    brew install gum
    print_success "gum installed successfully."
else
    print_success "gum is already installed."
end

# Setup Node.js, Deno, and n (Node version manager)
setup_language "Node.js" "node" "deno" "n"

# Setup Ruby with rbenv and ruby-build
setup_language "Ruby" "ruby" "rbenv" "ruby-build"

# Setup Go
setup_language "Go" "go"

print_success "Programming languages installation complete!"
print_info "Remember to restart your terminal or run 'source ~/.config/fish/config.fish' to apply all changes." 