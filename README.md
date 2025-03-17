# Simplified macOS Development Environment

A streamlined approach to setting up a complete macOS development environment with a single command.

## Features

- **One-Command Setup**: Get your entire development environment running with a single command
- **Zero Dependencies**: Starts with just Zsh (macOS default) and handles all other installations
- **Modular Design**: Choose to install only what you need
- **Homebrew-Based**: Uses Homebrew as the foundation for software installation
- **Dotfiles Management**: Automatically links configuration files using GNU Stow
- **Development Tools**: Sets up programming languages, editors, and developer tools

## Quick Start

To set up everything in one go:

```zsh
./preface.zsh
```

To preview what changes would be made without actually making them:

```zsh
./preface.zsh --dry-run
```

To see all available options:

```zsh
./preface.zsh --help
```

## How It Works

This setup process is divided into two stages:

1. **Preface Stage (Zsh)**: Runs on macOS's default shell to ensure core dependencies are installed:
   - Checks and installs Homebrew if needed
   - Checks and installs Fish shell if needed
   - Delegates to the main setup script

2. **Main Setup Stage (Fish)**: After dependencies are satisfied, uses Fish shell to:
   - Install all tools via Homebrew
   - Configure shells and environment
   - Link dotfiles with GNU Stow
   - Set up development tools

## Selective Installation

You can selectively install specific components:

```zsh
# Install only Homebrew packages
./preface.zsh homebrew

# Set up Fish shell
./preface.zsh shell

# Link dotfiles
./preface.zsh dotfiles

# Install development tools
./preface.zsh dev

# Set up Zsh (the macOS default)
./preface.zsh zsh
```

## Requirements

- macOS (10.15 Catalina or newer)
- Internet connection

## What Gets Installed

- **Homebrew**: Package manager for macOS
- **Fish Shell**: Modern shell with auto-suggestions and syntax highlighting
- **Development Tools**: Node.js, Rust, Neovim, tmux, and more
- **Configuration Files**: Shell configuration, editor settings, and terminal customizations

## Directory Structure

- `preface.zsh`: Main entry point (Zsh script for initial bootstrapping)
- `setup.fish`: Main setup script (Fish script for full installation)
- `runs/`: Contains installation scripts for specific tools
- `env/`: Contains dotfiles that are linked to your home directory

## Customization

Edit the `runs/Brewfile` to add or remove packages according to your preferences.

## License

MIT
