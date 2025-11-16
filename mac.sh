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
        
        # Add Homebrew to PATH
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

# Install Zsh
install_zsh() {
    print_info "Checking Zsh..."
    if command -v zsh &> /dev/null; then
        print_success "Zsh already installed: $(zsh --version)"
    else
        print_info "Installing Zsh..."
        brew install zsh
        print_success "Zsh installed"
    fi
    
    # Set Zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_info "Setting Zsh as default shell..."
        chsh -s $(which zsh)
        print_success "Zsh set as default shell"
    fi
    echo
}

# Install Oh-My-Zsh
install_oh_my_zsh() {
    print_info "Checking Oh-My-Zsh..."
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh-My-Zsh already installed"
    else
        print_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh-My-Zsh installed"
    fi
    echo
}

# Install mas-cli
install_mas() {
    print_info "Checking mas-cli..."
    if command -v mas &> /dev/null; then
        print_success "mas-cli already installed"
    else
        print_info "Installing mas-cli..."
        brew install mas
        print_success "mas-cli installed"
    fi
    echo
}

# Install certificates
setup_certificates() {
    print_info "Setting up certificates..."
    if [[ -d "./certs" ]]; then
        for cert in ./certs/*.{cer,crt,pem}; do
            [[ -e "$cert" ]] || continue
            print_info "Installing certificate: $(basename "$cert")"
            sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert"
        done
        print_success "Certificates installed"
        
        # Configure environment variables
        local shell_config=$(detect_shell_config)
        if ! grep -q "CERTIFICATE CONFIGURATION" "$shell_config" 2>/dev/null; then
            cat >> "$shell_config" << 'EOF'

# CERTIFICATE CONFIGURATION
export SSL_CERT_FILE="/etc/ssl/cert.pem"
export SSL_CERT_DIR="/etc/ssl/certs"
export REQUESTS_CA_BUNDLE="/etc/ssl/cert.pem"
export CURL_CA_BUNDLE="/etc/ssl/cert.pem"
export BUN_CA_BUNDLE_PATH="/etc/ssl/cert.pem"
export DENO_CERT="/etc/ssl/cert.pem"
EOF
            print_success "Certificate environment variables configured"
        fi
    else
        print_warning "No certs directory found, skipping certificate installation"
    fi
    echo
}

# Install fonts
install_fonts() {
    print_info "Installing fonts..."
    if [[ -d "./fonts" ]]; then
        for font_zip in ./fonts/*.zip; do
            [[ -e "$font_zip" ]] || continue
            print_info "Installing font: $(basename "$font_zip")"
            unzip -o "$font_zip" -d ~/Library/Fonts/
        done
        print_success "Fonts installed"
    else
        print_warning "No fonts directory found, skipping font installation"
    fi
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
    print_info "Installing Homebrew formulae..."
    for formula in "${brew_formulae[@]}"; do
        if brew list "$formula" &>/dev/null; then
            print_warning "$formula already installed"
        else
            print_info "Installing $formula..."
            brew install "$formula" && print_success "Installed $formula" || print_error "Failed to install $formula"
        fi
    done
    
    print_info "Installing Homebrew casks..."
    for cask in "${brew_casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            print_warning "$cask already installed"
        else
            print_info "Installing $cask..."
            brew install --cask "$cask" && print_success "Installed $cask" || print_error "Failed to install $cask"
        fi
    done
    echo
}

# Install Mac App Store apps
install_mas_apps() {
    print_info "Installing Mac App Store apps..."
    for app_id in "${!mas_apps[@]}"; do
        local app_name="${mas_apps[$app_id]}"
        if mas list | grep -q "$app_id"; then
            print_warning "$app_name already installed"
        else
            print_info "Installing $app_name (ID: $app_id)..."
            mas install "$app_id" && print_success "Installed $app_name" || print_error "Failed to install $app_name"
        fi
    done
    echo
}

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

# Install ASDF
install_asdf() {
    print_info "Checking ASDF..."
    if [[ -d "$HOME/.asdf" ]]; then
        print_success "ASDF already installed"
    else
        print_info "Installing ASDF..."
        brew install asdf
        
        local shell_config=$(detect_shell_config)
        if ! grep -q "ASDF Configuration" "$shell_config" 2>/dev/null; then
            cat >> "$shell_config" << 'EOF'

# ASDF Configuration
. $(brew --prefix asdf)/libexec/asdf.sh
EOF
            print_success "ASDF configured"
        fi
        
        source "$shell_config" 2>/dev/null || true
    fi
    echo
}

# Add ASDF plugin
add_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_info "Adding plugin: $plugin_name"
    
    if asdf plugin list | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name already exists"
        return 0
    fi
    
    if [[ -n "$plugin_url" ]]; then
        asdf plugin add "$plugin_name" "$plugin_url" || return 1
    else
        asdf plugin add "$plugin_name" || return 1
    fi
    print_success "Added plugin $plugin_name"
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
    print_info "Configuring tools with SSL certificates..."
    
    npm config set cafile /etc/ssl/cert.pem 2>/dev/null || true
    git config --global http.sslCAInfo /etc/ssl/cert.pem 2>/dev/null || true
    
    mkdir -p ~/.config/pip
    echo -e "[global]\ncert = /etc/ssl/cert.pem" > ~/.config/pip/pip.conf
    
    print_success "Tools configured"
    echo
}

# Main
main() {
    print_info "=== macOS Development Environment Setup ==="
    print_info "Shell: $(detect_shell)"
    print_info "Config: $(detect_shell_config)"
    echo
    
    # Install core tools
    install_homebrew
    brew install jq curl git
    
    install_zsh
    install_oh_my_zsh
    install_mas
    
    # Install packages from brew-mas.json
    if load_brew_mas_config; then
        install_brew_packages
        install_mas_apps
    fi
    
    # Setup certificates and fonts
    setup_certificates
    install_fonts
    
    # Install ASDF and languages
    install_asdf
    load_config
    
    print_info "Installing ASDF plugins and languages..."
    failed_plugins=()
    failed_installs=()
    
    for plugin in "${!plugins[@]}"; do
        add_plugin "$plugin" "${plugins[$plugin]}" || failed_plugins+=("$plugin")
    done
    
    for plugin in "${!plugins[@]}"; do
        [[ " ${failed_plugins[*]} " =~ " $plugin " ]] && continue
        install_latest "$plugin" || failed_installs+=("$plugin")
    done
    
    configure_tools
    
    echo
    print_info "=== SUMMARY ==="
    if [[ ${#failed_plugins[@]} -eq 0 && ${#failed_installs[@]} -eq 0 ]]; then
        print_success "All plugins and languages installed successfully!"
    else
        [[ ${#failed_plugins[@]} -gt 0 ]] && print_error "Failed plugins: ${failed_plugins[*]}"
        [[ ${#failed_installs[@]} -gt 0 ]] && print_error "Failed installs: ${failed_installs[*]}"
    fi
    
    echo
    print_info "Run 'asdf list' to see installed versions"
    print_info "Restart terminal or run: exec zsh"
}

main "$@"
