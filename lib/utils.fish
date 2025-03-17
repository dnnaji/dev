#!/usr/bin/env fish

# Print styling functions
function print_banner
    echo ""
    echo -e "\033[1;34m========================================\033[0m"
    echo -e "\033[1;34m    $argv    \033[0m"
    echo -e "\033[1;34m========================================\033[0m"
    echo ""
end

function print_step
    echo -e "\033[1;34m==> $argv\033[0m"
end

function print_info
    echo -e "\033[1;33m[INFO] $argv\033[0m"
end

function print_success
    echo -e "\033[1;32m[OK] $argv\033[0m"
end

function print_warning
    echo -e "\033[1;33m[WARNING] $argv\033[0m"
end

function print_error
    echo -e "\033[1;31m[ERROR] $argv\033[0m" >&2
end

# Input and validation functions
function read_input
    set prompt $argv[1]
    set default $argv[2]
    
    if test -n "$default"
        set prompt "$prompt [$default]"
    end
    
    read -P "$prompt: " response
    
    if test -z "$response" -a -n "$default"
        echo $default
    else
        echo $response
    end
end

function command_exists
    type -q $argv
    return $status
end

function confirm
    read -q "response? $argv (y/n) "
    echo ""
    if test "$response" = "y"
        return 0
    else
        return 1
    end
end

# File and directory helpers
function ensure_dir_exists
    set dir_path $argv[1]
    if not test -d $dir_path
        mkdir -p $dir_path
        and print_success "Created directory: $dir_path"
        or print_error "Failed to create directory: $dir_path"
    end
end

# Package management helpers
function brew_install
    set package_name $argv[1]
    
    if not command_exists brew
        print_error "Homebrew is not installed. Cannot install $package_name."
        return 1
    end
    
    if not command_exists $package_name
        print_info "Installing $package_name..."
        brew install $package_name
        
        if test $status -eq 0
            print_success "$package_name installed successfully."
            return 0
        else
            print_error "Failed to install $package_name."
            return 1
        end
    else
        print_info "$package_name is already installed."
        return 0
    end
end

function brew_cask_install
    set app_name $argv[1]
    
    if not command_exists brew
        print_error "Homebrew is not installed. Cannot install $app_name."
        return 1
    end
    
    print_info "Installing $app_name via Homebrew Cask..."
    brew install --cask $app_name
    
    if test $status -eq 0
        print_success "$app_name installed successfully."
        return 0
    else
        print_error "Failed to install $app_name."
        return 1
    end
end