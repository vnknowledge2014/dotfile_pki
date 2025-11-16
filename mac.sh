#!/usr/bin/env bash

# macOS Development Environment Setup
# Auto-install Homebrew, Zsh, Oh-My-Zsh, mas-cli, ASDF, and programming languages

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

detect_shell_config() {
    local shell_type=$(detect_shell)
    if [[ "$shell_type" == "zsh" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bash_profile"
    fi
}

# Install Homebrew
install_homebrew() {
    print_info "Checking Homebrew..."
    if command -v brew &> /dev/null; then
        print_success "Homebrew already installed"
        brew update
    else
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $(detect_shell_config)
        else
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $(detect_shell_config)
        fi
        print_success "Homebrew installed"
    fi
    echo
}

# Install Oh-My-Zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh-My-Zsh already installed"
    else
        print_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh-My-Zsh installed"
    fi
    echo
}

# Install certificates
setup_certificates() {
    [[ ! -d "./certs" ]] && return
    
    print_info "Installing certificates..."
    for cert in ./certs/*.{cer,crt,pem}; do
        [[ -e "$cert" ]] || continue
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert"
    done
    
    local shell_config=$(detect_shell_config)
    grep -q "CERTIFICATE CONFIGURATION" "$shell_config" 2>/dev/null || cat >> "$shell_config" << 'EOF'

# CERTIFICATE CONFIGURATION
export SSL_CERT_FILE="/etc/ssl/cert.pem"
export SSL_CERT_DIR="/etc/ssl/certs"
export REQUESTS_CA_BUNDLE="/etc/ssl/cert.pem"
export CURL_CA_BUNDLE="/etc/ssl/cert.pem"
export BUN_CA_BUNDLE_PATH="/etc/ssl/cert.pem"
export DENO_CERT="/etc/ssl/cert.pem"
EOF
    print_success "Certificates configured"
    echo
}

# Install fonts
install_fonts() {
    [[ ! -d "./fonts" ]] && return
    
    print_info "Installing fonts..."
    for font_zip in ./fonts/*.zip; do
        [[ -e "$font_zip" ]] || continue
        unzip -oq "$font_zip" -d ~/Library/Fonts/
    done
    print_success "Fonts installed"
    echo
}

# Setup tmux configuration
setup_tmux() {
    [[ ! -f "./tmux-config/.tmux.conf" ]] && return
    
    print_info "Configuring tmux..."
    mkdir -p ~/.config/tmux
    cp ./tmux-config/.tmux.conf ~/.config/tmux/.tmux.conf
    ln -sf ~/.config/tmux/.tmux.conf ~/.tmux.conf
    print_success "tmux configured"
    echo
}

# Load brew-mas config
load_brew_mas_config() {
    local config_file="./brew-mas.json"
    if [[ ! -f "$config_file" ]]; then
        print_warning "brew-mas.json not found, skipping package installation"
        return 1
    fi
    
    declare -ga brew_formulae
    declare -ga brew_casks
    declare -gA mas_apps
    
    while IFS= read -r formula; do
        brew_formulae+=("$formula")
    done < <(jq -r '.brew.formulae[]' "$config_file" 2>/dev/null || true)
    
    while IFS= read -r cask; do
        brew_casks+=("$cask")
    done < <(jq -r '.brew.casks[]' "$config_file" 2>/dev/null || true)
    
    while IFS='=' read -r key value; do
        mas_apps["$key"]="$value"
    done < <(jq -r '.mas | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)
}

# Install Homebrew packages
install_brew_packages() {
    print_info "Installing Homebrew packages..."
    
    local formulae_to_install=()
    for formula in "${brew_formulae[@]}"; do
        brew list "$formula" &>/dev/null || formulae_to_install+=("$formula")
    done
    [[ ${#formulae_to_install[@]} -gt 0 ]] && brew install "${formulae_to_install[@]}"
    
    local casks_to_install=()
    for cask in "${brew_casks[@]}"; do
        brew list --cask "$cask" &>/dev/null || casks_to_install+=("$cask")
    done
    [[ ${#casks_to_install[@]} -gt 0 ]] && brew install --cask "${casks_to_install[@]}"
    
    print_success "Homebrew packages installed"
    echo
}

# Install Mac App Store apps
# install_mas_apps() {
#     print_info "Installing Mac App Store apps..."
#     for app_id in "${!mas_apps[@]}"; do
#         mas list | grep -q "$app_id" || mas install "$app_id"
#     done
#     print_success "Mac App Store apps installed"
#     echo
# }

# Load plugins config
load_config() {
    local config_file="./plugins.json"
    if [[ ! -f "$config_file" ]]; then
        print_error "plugins.json not found"
        exit 1
    fi
    
    declare -gA plugins
    declare -ga manual_version_plugins
    declare -gA recommended_versions
    
    while IFS='=' read -r key value; do
        plugins["$key"]="$value"
    done < <(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$config_file")
    
    while IFS= read -r plugin; do
        manual_version_plugins+=("$plugin")
    done < <(jq -r '.special_handling.manual_version[]' "$config_file")
    
    while IFS='=' read -r key value; do
        recommended_versions["$key"]="$value"
    done < <(jq -r '.special_handling.recommended_versions | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)
}

# Configure ASDF
configure_asdf() {
    local shell_config=$(detect_shell_config)
    grep -q "ASDF Configuration" "$shell_config" 2>/dev/null || cat >> "$shell_config" << 'EOF'

# ASDF Configuration
. $(brew --prefix asdf)/libexec/asdf.sh
EOF
    source "$shell_config" 2>/dev/null || true
}

# Add ASDF plugin
add_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    
    asdf plugin list | grep -q "^$plugin_name$" && return 0
    
    [[ -n "$plugin_url" ]] && asdf plugin add "$plugin_name" "$plugin_url" || asdf plugin add "$plugin_name"
}

# Install latest version
install_latest() {
    local plugin_name=$1
    local version=""
    
    local needs_manual=false
    for manual_plugin in "${manual_version_plugins[@]}"; do
        if [[ "$plugin_name" == "$manual_plugin" ]]; then
            needs_manual=true
            break
        fi
    done
    
    if [[ "$needs_manual" == "true" ]]; then
        print_info "Available versions for $plugin_name:"
        asdf list all "$plugin_name" || return 1
        
        local prompt="Enter version for $plugin_name"
        if [[ -n "${recommended_versions[$plugin_name]}" ]]; then
            prompt="$prompt (recommended: ${recommended_versions[$plugin_name]})"
        fi
        read -p "$prompt: " version
        
        if [[ -z "$version" ]]; then
            print_error "Version cannot be empty"
            return 1
        fi
    else
        version=$(asdf latest "$plugin_name")
        if [[ -z "$version" ]]; then
            print_error "Cannot get latest version of $plugin_name"
            return 1
        fi
    fi
    
    print_info "Installing $plugin_name version $version..."
    if asdf install "$plugin_name" "$version"; then
        asdf global "$plugin_name" "$version"
        print_success "Installed $plugin_name $version"
    else
        print_error "Failed to install $plugin_name"
        return 1
    fi
}

# Configure tools with SSL certificates
configure_tools() {
    npm config set cafile /etc/ssl/cert.pem 2>/dev/null || true
    git config --global http.sslCAInfo /etc/ssl/cert.pem 2>/dev/null || true
    mkdir -p ~/.config/pip && echo -e "[global]\ncert = /etc/ssl/cert.pem" > ~/.config/pip/pip.conf
}

# Set Zsh as default shell
set_default_shell() {
    [[ "$SHELL" == *"zsh"* ]] && return
    print_info "Setting Zsh as default shell..."
    chsh -s $(which zsh)
    print_success "Zsh set as default"
}

# Main
main() {
    print_info "=== macOS Development Environment Setup ==="
    echo
    
    install_homebrew
    
    # Install packages from brew-mas.json
    load_brew_mas_config && install_brew_packages # && install_mas_apps
    
    set_default_shell
    install_oh_my_zsh
    
    setup_certificates
    install_fonts
    setup_tmux
    
    configure_asdf
    load_config
    
    print_info "Installing ASDF plugins and languages..."
    for plugin in "${!plugins[@]}"; do
        add_plugin "$plugin" "${plugins[$plugin]}"
    done
    
    for plugin in "${!plugins[@]}"; do
        install_latest "$plugin"
    done
    
    configure_tools
    
    print_success "Setup complete! Run 'asdf list' to see installed versions"
    print_info "Restart terminal or run: exec zsh"
}

main "$@"
