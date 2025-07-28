#!/usr/bin/env bash

# NST-AI Installation Script
# This script automatically detects OS, installs dependencies, and sets up NST-AI
# Usage: curl -fsSL https://raw.githubusercontent.com/AryanVBW/NST-Ai/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="redhat"
        elif [ -f /etc/arch-release ]; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        DISTRO="windows"
    else
        OS="unknown"
        DISTRO="unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Python on different systems
install_python() {
    print_status "Installing Python..."
    
    case $DISTRO in
        "debian")
            sudo apt update
            sudo apt install -y python3 python3-pip python3-venv git curl
            ;;
        "redhat")
            sudo yum update -y
            sudo yum install -y python3 python3-pip git curl
            ;;
        "arch")
            sudo pacman -Sy --noconfirm python python-pip git curl
            ;;
        "macos")
            if command_exists brew; then
                brew install python git
            else
                print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
                exit 1
            fi
            ;;
        "windows")
            print_error "Windows detected. Please install Python manually from https://python.org"
            exit 1
            ;;
        *)
            print_error "Unsupported distribution. Please install Python 3.8+ manually."
            exit 1
            ;;
    esac
}

# Install Node.js and npm
install_nodejs() {
    print_status "Installing Node.js..."
    
    case $DISTRO in
        "debian")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "redhat")
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs npm
            ;;
        "arch")
            sudo pacman -S --noconfirm nodejs npm
            ;;
        "macos")
            if command_exists brew; then
                brew install node
            else
                print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
                exit 1
            fi
            ;;
        "windows")
            print_error "Windows detected. Please install Node.js manually from https://nodejs.org"
            exit 1
            ;;
        *)
            print_error "Unsupported distribution. Please install Node.js manually."
            exit 1
            ;;
    esac
}

# Setup NST-AI
setup_nst_ai() {
    print_status "Setting up NST-AI..."
    
    # Set installation directory
    INSTALL_DIR="$HOME/.nst-ai"
    
    # Remove existing installation if present
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Existing NST-AI installation found. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    print_status "Cloning NST-AI repository..."
    git clone https://github.com/AryanVBW/NST-Ai.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Create Python virtual environment
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    pip install --upgrade pip
    pip install -r backend/requirements.txt
    
    # Install Node.js dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Build frontend
    print_status "Building frontend..."
    npm run build
    
    print_success "NST-AI setup completed!"
}

# Create global command
create_global_command() {
    print_status "Creating global nst-ai command..."
    
    # Create the nst-ai script
    cat > "$HOME/.nst-ai/nst-ai" << 'EOF'
#!/usr/bin/env bash

# NST-AI Launcher Script
NST_AI_DIR="$HOME/.nst-ai"

if [ ! -d "$NST_AI_DIR" ]; then
    echo "Error: NST-AI not found. Please run the installation script first."
    exit 1
fi

cd "$NST_AI_DIR"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Error: Virtual environment not found. Please reinstall NST-AI."
    exit 1
fi

# Activate virtual environment and start NST-AI
source venv/bin/activate
cd backend

echo "Starting NST-AI..."
echo "Access the interface at: http://localhost:8080"
echo "Press Ctrl+C to stop the server"

./start.sh
EOF

    # Make the script executable
    chmod +x "$HOME/.nst-ai/nst-ai"
    
    # Add to PATH
    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # Add NST-AI to PATH if not already present
    if ! grep -q "$HOME/.nst-ai" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# NST-AI" >> "$SHELL_RC"
        echo "export PATH=\"\$HOME/.nst-ai:\$PATH\"" >> "$SHELL_RC"
        print_success "Added NST-AI to PATH in $SHELL_RC"
    fi
    
    # Create symlink for immediate use
    if [ -w "/usr/local/bin" ]; then
        ln -sf "$HOME/.nst-ai/nst-ai" "/usr/local/bin/nst-ai"
        print_success "Created global symlink in /usr/local/bin"
    else
        print_warning "Cannot create global symlink. You may need to restart your terminal or run 'source $SHELL_RC'"
    fi
}

# Create uninstall script
create_uninstall_script() {
    cat > "$HOME/.nst-ai/uninstall.sh" << 'EOF'
#!/usr/bin/env bash

echo "Uninstalling NST-AI..."

# Remove installation directory
rm -rf "$HOME/.nst-ai"

# Remove from PATH in shell config files
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc_file" ]; then
        sed -i.bak '/# NST-AI/,+1d' "$rc_file" 2>/dev/null || true
    fi
done

# Remove global symlink
if [ -L "/usr/local/bin/nst-ai" ]; then
    rm -f "/usr/local/bin/nst-ai"
fi

echo "NST-AI has been uninstalled successfully."
echo "You may need to restart your terminal for PATH changes to take effect."
EOF

    chmod +x "$HOME/.nst-ai/uninstall.sh"
}

# Main installation function
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                            NST-AI Installation Script                        ║"
    echo "║                                                                              ║"
    echo "║                    🔥GitHub:    github.com/AryanVBW                          ║"
    echo "║                    🌐Site:     portfolio.aryanvbw.live                       ║"
    echo "║                    💖Instagram: Aryan_Technolog1es                           ║"
    echo "║                    📧Email:   vivek.aryanvbw@gmail.com                       ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    print_status "Starting NST-AI installation..."
    
    # Detect operating system
    detect_os
    print_status "Detected OS: $OS ($DISTRO)"
    
    # Check for Python
    if ! command_exists python3; then
        install_python
    else
        print_success "Python3 is already installed"
    fi
    
    # Check for Node.js
    if ! command_exists node; then
        install_nodejs
    else
        print_success "Node.js is already installed"
    fi
    
    # Check for Git
    if ! command_exists git; then
        print_error "Git is required but not installed. Please install Git first."
        exit 1
    else
        print_success "Git is available"
    fi
    
    # Setup NST-AI
    setup_nst_ai
    
    # Create global command
    create_global_command
    
    # Create uninstall script
    create_uninstall_script
    
    echo ""
    print_success "🎉 NST-AI installation completed successfully!"
    echo ""
    echo "To start NST-AI, run:"
    echo "  nst-ai"
    echo ""
    echo "Or if the command is not found, restart your terminal and try again, or run:"
    echo "  source ~/.bashrc  # or ~/.zshrc depending on your shell"
    echo "  nst-ai"
    echo ""
    echo "To uninstall NST-AI, run:"
    echo "  ~/.nst-ai/uninstall.sh"
    echo ""
    echo "The web interface will be available at: http://localhost:8080"
    echo ""
}

# Run main function
main "$@"