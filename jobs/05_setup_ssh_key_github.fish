#!/usr/bin/env fish

# This job script is part of the fresh MacBook Air M4 setup. It is intended to be run after initial bootstrap steps via bootstrap.zsh and run.fish.

function generate_ssh_key
    print_step "Generate SSH Key"
    echo -n "Enter SSH key suffix (optional): "
    read key_suffix

    if test -z "$key_suffix"
        set key_filename "id_ed25519"
        print_info "Using default key name: $key_filename"
    else
        set key_filename "id_ed25519_$key_suffix"
        print_info "Using key name: $key_filename"
    end

    set key_path "$HOME/.ssh/$key_filename"

    if not test -f "$key_path"
        print_info "No SSH key found at $key_path. Generating a new one..."

        echo -n "Enter your email for the SSH key [$INITIAL_EMAIL]: "
        read ssh_email
        if test -z "$ssh_email"
            set ssh_email "$INITIAL_EMAIL"
        end
        
        print_info "Generating secure passphrase with Bitwarden..."
        set passphrase (bw generate -luns --length 128)
        print_info "Generated passphrase."
        
        mkdir -p "$HOME/.ssh"
        
        print_info "Creating SSH key with the generated passphrase..."
        ssh-keygen -t ed25519 -C "$ssh_email" -N "$passphrase" -f "$key_path"
        
        security add-generic-password -a "$USER" -s "SSH: $key_path" -w "$passphrase" -T "/usr/bin/ssh-add"
        print_success "SSH key passphrase stored in macOS Keychain"
        
        print_success "SSH key generated successfully at $key_path"
    else
        print_success "SSH key already exists at $key_path."
    end

    # Export variables for use in subsequent functions
    set -g __ssh_key_path $key_path
    set -g __ssh_key_filename $key_filename
end

function add_ssh_key_to_agent
    print_step "Add SSH Key to ssh-agent"
    eval (ssh-agent -s)

    # Configure SSH config file if missing UseKeychain
    if not test -f "$HOME/.ssh/config" or not grep -q "UseKeychain" "$HOME/.ssh/config"
        print_info "Configuring SSH to use macOS Keychain..."
        mkdir -p "$HOME/.ssh"
        # Append configuration using printf (Fish doesn't support bash heredoc)
        printf "Host *\n  UseKeychain yes\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/%s\n" $__ssh_key_filename >> "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        print_success "SSH configured to use macOS Keychain."
    end

    print_info "Adding SSH key to agent using stored Keychain passphrase..."
    set retrieved_passphrase (security find-generic-password -a "$USER" -s "SSH: $__ssh_key_path" -w 2>/dev/null)
    if test -n "$retrieved_passphrase"
        echo "$retrieved_passphrase" | ssh-add "$__ssh_key_path" >/dev/null 2>&1
        if test $status -eq 0
            print_success "SSH key added to ssh-agent using the Keychain passphrase."
        else
            print_warning "Failed to add SSH key using the retrieved Keychain passphrase; falling back to manual entry."
            ssh-add "$__ssh_key_path"
        end
    else
        print_warning "No passphrase found in Keychain; attempting to add SSH key without it."
        ssh-add "$__ssh_key_path"
    end
end

function authenticate_github_cli
    print_step "Authenticate GitHub CLI"
    if type -q gh
        if not gh auth status > /dev/null 2>&1
            print_info "GitHub CLI not authenticated. Logging in..."
            gh auth login
            print_success "GitHub CLI authenticated successfully."
        else
            print_success "GitHub CLI is already authenticated."
        end
    else
        print_error "Error: GitHub CLI (gh) not found. Installation failed."
        exit 1
    end
end

function upload_ssh_key_to_github
    print_step "Upload SSH Key to GitHub"
    print_info "Setting SSH key title for GitHub..."
    echo -n "Enter SSH key title [MacBook Setup Key]: "
    read ssh_key_title
    if test -z "$ssh_key_title"
        set ssh_key_title "MacBook Setup Key"
    end

    set pub_key (cat "$__ssh_key_path.pub" | cut -d ' ' -f 2)
    if gh ssh-key list 2>/dev/null | grep -q "$pub_key"
        print_warning "SSH key already exists on GitHub."
    else
        gh ssh-key add "$__ssh_key_path.pub" --title "$ssh_key_title"
        print_success "SSH key uploaded to GitHub with title: $ssh_key_title"
    end
end

# Main execution: call functions sequentially
generate_ssh_key
add_ssh_key_to_agent
authenticate_github_cli
upload_ssh_key_to_github
