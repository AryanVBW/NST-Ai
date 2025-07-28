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

# Detect and clean existing installations
clean_existing_installations() {
    print_status "Checking for existing NST-AI installations..."
    
    # Check for existing installations
    local found_existing=false
    
    # Check pip installations
    if python3 -m pip show nst-ai >/dev/null 2>&1; then
        print_warning "Found existing pip installation of nst-ai. Removing..."
        python3 -m pip uninstall -y nst-ai
        found_existing=true
    fi
    
    # Check for global installations
    if command_exists nst-ai; then
        print_warning "Found existing nst-ai command. Will be replaced..."
        found_existing=true
    fi
    
    # Check for old virtual environments
    if [ -d "$HOME/.nst-ai" ]; then
        print_warning "Found existing NST-AI directory. Backing up and removing..."
        if [ -d "$HOME/.nst-ai-backup" ]; then
            rm -rf "$HOME/.nst-ai-backup"
        fi
        mv "$HOME/.nst-ai" "$HOME/.nst-ai-backup"
        found_existing=true
    fi
    
    if [ "$found_existing" = true ]; then
        print_success "Cleaned existing installations"
    else
        print_success "No existing installations found"
    fi
}

# Fix dependency conflicts
fix_dependency_conflicts() {
    print_status "Resolving dependency conflicts..."
    
    # Create a temporary requirements file with conflict resolution
    cat > "$INSTALL_DIR/backend/requirements_fixed.txt" << 'EOF'
# Core dependencies with resolved versions
numpy>=1.22.5,<2.0.0
scipy>=1.9.0
pandas>=1.5.0

# AI/ML dependencies
torch>=2.0.0
transformers>=4.30.0
sentence-transformers>=2.2.0

# Vector databases with compatible numpy versions
chromadb>=0.4.0,<0.6.0
qdrant-client>=1.7.0,<1.14.0
pgvector>=0.2.0,<0.4.0

# Document processing with numpy<2 compatibility
unstructured>=0.10.0,<0.16.0
langchain-community>=0.0.20,<0.3.0

# Web framework
fastapi>=0.100.0
uvicorn[standard]>=0.20.0

# Database
sqlalchemy>=2.0.0
alembic>=1.10.0

# Authentication
passlib[bcrypt]>=1.7.4
python-jose[cryptography]>=3.3.0

# File handling
python-multipart>=0.0.6
aiofiles>=23.0.0

# HTTP client
httpx>=0.24.0
requests>=2.28.0

# Utilities
python-dotenv>=1.0.0
pydantic>=2.0.0
pydantic-settings>=2.0.0
typing-extensions>=4.5.0
EOF
    
    print_success "Created conflict-resolved requirements file"
}

# Setup NST-AI with enhanced error handling
setup_nst_ai() {
    print_status "Setting up NST-AI..."
    
    # Set installation directory
    INSTALL_DIR="$HOME/.nst-ai"
    
    # Clean existing installations
    clean_existing_installations
    
    # Clone repository
    print_status "Cloning NST-AI repository..."
    if ! git clone https://github.com/AryanVBW/NST-Ai.git "$INSTALL_DIR"; then
        print_error "Failed to clone repository. Please check your internet connection."
        exit 1
    fi
    cd "$INSTALL_DIR"
    
    # Create Python virtual environment with descriptive name
    print_status "Creating Python virtual environment (nst-ai-env)..."
    if ! python3 -m venv nst-ai-env; then
        print_error "Failed to create virtual environment. Please check Python installation."
        exit 1
    fi
    
    # Activate virtual environment
    source nst-ai-env/bin/activate
    
    # Upgrade pip and install build tools
    print_status "Upgrading pip and installing build tools..."
    pip install --upgrade pip setuptools wheel
    
    # Fix dependency conflicts
    fix_dependency_conflicts
    
    # Install Python dependencies with conflict resolution
    print_status "Installing Python dependencies (this may take a while)..."
    
    # Try installing with the fixed requirements first
    if pip install -r backend/requirements_fixed.txt; then
        print_success "Dependencies installed successfully with conflict resolution"
    else
        print_warning "Fixed requirements failed, trying original with --force-reinstall..."
        
        # Fallback: try with force reinstall and no dependencies check
        if pip install --force-reinstall --no-deps -r backend/requirements.txt; then
            print_warning "Installed with --no-deps, some features may not work correctly"
        else
            print_error "Failed to install Python dependencies. Please check the error messages above."
            print_error "You may need to manually resolve dependency conflicts."
            exit 1
        fi
    fi
    
    # Install Node.js dependencies with legacy peer deps to handle conflicts
    print_status "Installing Node.js dependencies..."
    if ! npm install --legacy-peer-deps; then
        print_warning "Failed with legacy peer deps, trying with force..."
        if ! npm install --force; then
            print_error "Failed to install Node.js dependencies. Please check npm installation."
            print_error "You may need to manually run: cd ~/.nst-ai/frontend && npm install --legacy-peer-deps"
            exit 1
        fi
    fi
    
    # Build frontend
    print_status "Building frontend application..."
    if ! npm run build; then
        print_error "Failed to build frontend. Please check Node.js and npm installation."
        exit 1
    fi
    
    print_success "NST-AI setup completed successfully!"
}

# Create global command
create_global_command() {
    print_status "Creating global nst-ai command..."
    
    # Create the nst-ai script with enhanced error handling
    cat > "$HOME/.nst-ai/nst-ai" << 'EOF'
#!/usr/bin/env bash

# NST-AI Launcher Script with Enhanced Error Handling
NST_AI_DIR="$HOME/.nst-ai"

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

# Check if NST-AI directory exists
if [ ! -d "$NST_AI_DIR" ]; then
    print_error "NST-AI installation not found at $NST_AI_DIR"
    print_error "Please run the installation script first:"
    echo "curl -fsSL https://raw.githubusercontent.com/AryanVBW/NST-Ai/main/install.sh | bash"
    exit 1
fi

cd "$NST_AI_DIR"

# Check if virtual environment exists (new name)
if [ ! -d "nst-ai-env" ]; then
    print_error "Virtual environment 'nst-ai-env' not found."
    
    # Check for old venv name
    if [ -d "venv" ]; then
        print_warning "Found old virtual environment 'venv'. Migrating to 'nst-ai-env'..."
        mv venv nst-ai-env
        print_success "Migration completed"
    else
        print_error "No virtual environment found. Please reinstall NST-AI."
        exit 1
    fi
fi

# Check if backend directory exists
if [ ! -d "backend" ]; then
    print_error "Backend directory not found. Installation may be corrupted."
    exit 1
fi

# Check if start script exists
if [ ! -f "backend/start.sh" ]; then
    print_error "Start script not found. Installation may be corrupted."
    exit 1
fi

# Activate virtual environment
print_status "Activating NST-AI environment..."
if ! source nst-ai-env/bin/activate; then
    print_error "Failed to activate virtual environment."
    exit 1
fi

# Change to backend directory
cd backend

# Check for dependency conflicts before starting
print_status "Checking dependencies..."
if ! python -c "import numpy, fastapi, uvicorn" >/dev/null 2>&1; then
    print_warning "Some dependencies may be missing or incompatible."
    print_warning "Consider reinstalling NST-AI if you encounter issues."
fi

# Display startup information
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                               NST-AI Starting                                ║"
echo "║                                                                              ║"
echo "║  🌐 Web Interface: http://localhost:8080                                     ║"
echo "║  🛑 Stop Server: Press Ctrl+C                                               ║"
echo "║  📚 Documentation: https://docs.nst-ai.com                                   ║"
echo "║  🐛 Issues: https://github.com/AryanVBW/NST-Ai/issues                       ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

print_status "Starting NST-AI server..."

# Start the server with error handling
if ! ./start.sh; then
    print_error "Failed to start NST-AI server."
    print_error "Please check the error messages above."
    print_error "For troubleshooting, visit: https://github.com/AryanVBW/NST-Ai/issues"
    exit 1
fi
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

# NST-AI Uninstaller with Enhanced Cleanup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                            NST-AI Uninstaller                                ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

print_warning "This will completely remove NST-AI from your system."
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Uninstallation cancelled."
    exit 0
fi

print_status "Starting NST-AI uninstallation..."

# Stop any running NST-AI processes
print_status "Stopping any running NST-AI processes..."
if pgrep -f "nst-ai\|uvicorn.*nst_ai" > /dev/null; then
    pkill -f "nst-ai\|uvicorn.*nst_ai"
    print_success "Stopped running NST-AI processes"
else
    print_status "No running NST-AI processes found"
fi

# Remove the global command
if [ -f "/usr/local/bin/nst-ai" ]; then
    if sudo rm -f "/usr/local/bin/nst-ai" 2>/dev/null; then
        print_success "Removed global nst-ai command"
    else
        print_warning "Could not remove global command (may require manual removal)"
    fi
else
    print_status "Global nst-ai command not found"
fi

# Remove virtual environments (both old and new names)
if [ -d "$HOME/.nst-ai/nst-ai-env" ]; then
    print_status "Removing virtual environment 'nst-ai-env'..."
    rm -rf "$HOME/.nst-ai/nst-ai-env"
    print_success "Removed nst-ai-env virtual environment"
fi

if [ -d "$HOME/.nst-ai/venv" ]; then
    print_status "Removing old virtual environment 'venv'..."
    rm -rf "$HOME/.nst-ai/venv"
    print_success "Removed old venv virtual environment"
fi

# Remove from PATH in shell config files
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc_file" ]; then
        sed -i.bak '/# NST-AI/,+1d' "$rc_file" 2>/dev/null || true
    fi
done

# Remove the installation directory
if [ -d "$HOME/.nst-ai" ]; then
    print_status "Removing NST-AI installation directory..."
    rm -rf "$HOME/.nst-ai"
    print_success "Removed NST-AI installation directory"
else
    print_warning "NST-AI installation directory not found"
fi

# Clean up any remaining cache or temporary files
print_status "Cleaning up cache and temporary files..."
if [ -d "$HOME/.cache/nst-ai" ]; then
    rm -rf "$HOME/.cache/nst-ai"
    print_success "Removed NST-AI cache"
fi

echo ""
print_success "NST-AI has been completely uninstalled from your system."
print_status "Thank you for using NST-AI!"
echo ""
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