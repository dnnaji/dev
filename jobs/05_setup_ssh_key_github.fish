#!/usr/bin/env fish

# This job script is part of the fresh MacBook Air M4 setup. It is intended to be run after initial bootstrap steps via bootstrap.zsh and run.fish.

# Logging functions
function print_step; echo "=== $argv ==="; end
function print_info; echo "INFO: $argv"; end
function print_success; echo "SUCCESS: $argv"; end
function print_warning; echo "WARNING: $argv"; end
function print_error; echo "ERROR: $argv"; end

function check_dependencies
    for cmd in fzf gh openssl
        if not command -q $cmd
            print_error "$cmd is required but not installed."
            exit 1
        end
    end
    if not command -q bw
        print_warning "Bitwarden CLI (bw) not found; using OpenSSL for passphrase."
    end
end

# Function to generate an SSH key
function generate_ssh_key
    print_step "Generate SSH Key"
    set key_filename "id_ed25519"
    set key_path "$HOME/.ssh/$key_filename"
    print_info "Using default key name: $key_filename"

    if not test -f "$key_path"
        print_info "No SSH key found at $key_path. Generating a new one..."

        if not set -q INITIAL_EMAIL
            if command -q git; and git config --get user.email > /dev/null 2>&1
                set INITIAL_EMAIL (git config --get user.email)
                print_info "Using email from git config: $INITIAL_EMAIL"
            else
                set INITIAL_EMAIL "user@example.com"
                print_warning "Using default email. Set INITIAL_EMAIL for a real address."
            end
        end
        set ssh_email $INITIAL_EMAIL

        if command -q bw
            print_info "Generating secure passphrase with Bitwarden..."
            set passphrase (bw generate -luns --length 64 2> /dev/null)
        else
            print_info "Generating passphrase with OpenSSL..."
            set passphrase (openssl rand -base64 48)
        end
        
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$ssh_email" -N "$passphrase" -f "$key_path" > /dev/null 2>&1
        if test $status -ne 0
            print_error "SSH key generation failed"
            return 1
        end
        
        security add-generic-password -a "$USER" -s "SSH: $key_path" -w "$passphrase" -T "/usr/bin/ssh-add"
        print_success "SSH key passphrase stored in macOS Keychain"
        print_success "SSH key generated successfully at $key_path"
    else
        print_success "SSH key already exists at $key_path."
    end

    set -g __ssh_key_path $key_path
    set -g __ssh_key_filename $key_filename
    set -g __ssh_key_passphrase $passphrase
end

# Function to add the SSH key to the agent automatically using the stored passphrase
function add_ssh_key_to_agent
    print_step "Add SSH Key to ssh-agent"
    eval (ssh-agent -c)

    if test ! -f "$HOME/.ssh/config"; or not grep -q "UseKeychain" "$HOME/.ssh/config"
        print_info "Configuring SSH to use macOS Keychain..."
        mkdir -p "$HOME/.ssh"
        printf "Host *\n  UseKeychain yes\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/%s\n" $__ssh_key_filename >> "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        print_success "SSH configured to use macOS Keychain."
    end

    if ssh-add -l | grep -q "$__ssh_key_path" 2>/dev/null
        print_success "SSH key already in agent."
        return 0
    end

    print_info "Adding SSH key to agent..."
    
    # Check if expect is available
    if not command -q expect
        print_warning "The 'expect' utility is not installed. Using standard ssh-add method."
        ssh-add "$__ssh_key_path" 2>/dev/null
        if test $status -eq 0
            print_success "SSH key added to ssh-agent."
        else
            print_warning "Failed to add SSH key. Run 'ssh-add $__ssh_key_path' manually if needed."
            return 1
        end
    else
        # Create temporary expect script to automate passphrase entry
        set -l expect_script (mktemp)
        chmod 700 $expect_script
        
        echo '#!/usr/bin/expect -f
set timeout 10
set key_path [lindex $argv 0]
set passphrase [lindex $argv 1]

spawn ssh-add $key_path
expect "Enter passphrase for $key_path:"
send "$passphrase\r"
expect {
    "Identity added" {
        exit 0
    }
    "Bad passphrase" {
        puts "Error: Incorrect passphrase"
        exit 1
    }
    timeout {
        puts "Error: Timed out waiting for response"
        exit 1
    }
}
' > $expect_script
        
        # Run the expect script with passphrase
        if set -q __ssh_key_passphrase
            expect $expect_script "$__ssh_key_path" "$__ssh_key_passphrase" >/dev/null 2>&1
            set -l status_code $status
            # Remove the temporary script
            rm $expect_script
            
            if test $status_code -eq 0
                print_success "SSH key added to ssh-agent using expect."
            else
                print_warning "Failed to add SSH key with expect. Trying to retrieve from keychain..."
                
                # Try to get passphrase from keychain
                set -l keychain_passphrase (security find-generic-password -a "$USER" -s "SSH: $__ssh_key_path" -w 2>/dev/null)
                if test $status -eq 0
                    # Create a new expect script for the keychain passphrase
                    set -l expect_script (mktemp)
                    chmod 700 $expect_script
                    
                    echo '#!/usr/bin/expect -f
set timeout 10
set key_path [lindex $argv 0]
set passphrase [lindex $argv 1]

spawn ssh-add $key_path
expect "Enter passphrase for $key_path:"
send "$passphrase\r"
expect {
    "Identity added" {
        exit 0
    }
    "Bad passphrase" {
        puts "Error: Incorrect passphrase"
        exit 1
    }
    timeout {
        puts "Error: Timed out waiting for response"
        exit 1
    }
}
' > $expect_script
                    
                    expect $expect_script "$__ssh_key_path" "$keychain_passphrase" >/dev/null 2>&1
                    set status_code $status
                    rm $expect_script
                    
                    if test $status_code -eq 0
                        print_success "SSH key added to ssh-agent using keychain passphrase."
                    else
                        print_warning "Failed to add SSH key. Run 'ssh-add $__ssh_key_path' manually if needed."
                        return 1
                    end
                else
                    print_warning "Failed to retrieve passphrase from keychain. Run 'ssh-add $__ssh_key_path' manually if needed."
                    return 1
                end
            end
        else
            rm $expect_script
            print_warning "SSH key passphrase not available. Run 'ssh-add $__ssh_key_path' manually if needed."
            return 1
        end
    end
end

# Function to authenticate GitHub CLI automatically
function authenticate_github_cli
    print_step "Authenticate GitHub CLI"
    if not command -q gh
        print_error "GitHub CLI (gh) not found. Please install it first."
        return 1
    end
    
    if gh auth status >/dev/null 2>&1
        print_success "GitHub CLI is already authenticated."
    else
        print_warning "GitHub CLI not authenticated."
        print_info "Run 'gh auth login' manually. See https://cli.github.com/manual/gh_auth_login for help."
        return 1
    end
end

# Function to upload SSH key to GitHub without prompting
function upload_ssh_key_to_github
    print_step "Upload SSH Key to GitHub"
    if not gh auth status >/dev/null 2>&1
        print_warning "Skipping SSH key upload: Not authenticated with GitHub CLI."
        return 1
    end
    
    set ssh_key_title "MacBook Setup Key from "(hostname -s)" ("(date +%Y-%m-%d)")"
    set pub_key_path "$__ssh_key_path.pub"
    if not test -f "$pub_key_path"
        print_error "Public key file not found: $pub_key_path"
        return 1
    end

    gh ssh-key add "$pub_key_path" --title "$ssh_key_title" 2>/dev/null
    if test $status -eq 0
        print_success "SSH key uploaded to GitHub with title: $ssh_key_title"
    else
        print_warning "SSH key upload failed; it may already exist or there was an error."
        return 1
    end
end

function main
    check_dependencies
    set options "Generate SSH Key" "Add SSH Key to Agent" "Authenticate GitHub CLI" "Upload SSH Key to GitHub"
    
    if not command -q fzf
        print_warning "fzf not found. Running all steps sequentially."
        set selected $options
    else
        set selected (printf "%s\n" $options | fzf --multi --header="Select setup steps")
    end

    set sorted_steps
    for opt in "Generate SSH Key" "Add SSH Key to Agent" "Authenticate GitHub CLI" "Upload SSH Key to GitHub"
        if contains $opt $selected
            set -a sorted_steps $opt
        end
    end

    for choice in $sorted_steps
        switch $choice
            case "Generate SSH Key"; generate_ssh_key
            case "Add SSH Key to Agent"; add_ssh_key_to_agent
            case "Authenticate GitHub CLI"; authenticate_github_cli
            case "Upload SSH Key to GitHub"; upload_ssh_key_to_github
        end
    end
end

main
