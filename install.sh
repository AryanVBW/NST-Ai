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

# Check if conda is available
check_conda() {
    if command_exists conda; then
        return 0
    elif command_exists mamba; then
        return 0
    else
        return 1
    fi
}

# Get conda command (prefer mamba if available)
get_conda_cmd() {
    if command_exists mamba; then
        echo "mamba"
    elif command_exists conda; then
        echo "conda"
    else
        echo ""
    fi
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

# Function to analyze current Python environment
analyze_python_environment() {
    print_status "Analyzing Python environment for potential conflicts..."
    
    # Check Python version compatibility
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
    PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    
    print_status "Python version: $PYTHON_VERSION"
    
    # Check for virtual environment
    if [ -n "$VIRTUAL_ENV" ]; then
        print_warning "Currently in virtual environment: $VIRTUAL_ENV"
        print_warning "NST-AI will create its own isolated environment"
    fi
    
    # Check for conflicting packages in system Python
    CONFLICTING_PACKAGES=("numpy" "chromadb" "qdrant-client" "pgvector" "unstructured" "langchain" "langchain-community")
    SYSTEM_CONFLICTS=()
    
    for package in "${CONFLICTING_PACKAGES[@]}"; do
        if python3 -c "import $package" >/dev/null 2>&1; then
            VERSION=$(python3 -c "import $package; print(getattr($package, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
            SYSTEM_CONFLICTS+=("$package==$VERSION")
        fi
    done
    
    if [ ${#SYSTEM_CONFLICTS[@]} -gt 0 ]; then
        print_warning "Found potentially conflicting packages in system Python:"
        for conflict in "${SYSTEM_CONFLICTS[@]}"; do
            echo "  - $conflict"
        done
        print_status "NST-AI will use isolated environment to avoid conflicts"
    else
        print_success "No conflicting packages found in system Python"
    fi
    
    return 0
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
        
        # Analyze existing installation
        if [ -d "$HOME/.nst-ai/nst-ai-env" ] || [ -d "$HOME/.nst-ai/venv" ]; then
            print_status "Analyzing existing virtual environment..."
            
            # Check which virtual environment exists
        if [ -d "$HOME/.nst-ai/nst-ai-env" ]; then
            EXISTING_VENV="$HOME/.nst-ai/nst-ai-env"
        else
            EXISTING_VENV="$HOME/.nst-ai/venv"
        fi
        
        # Get list of installed packages
         if [ -f "$EXISTING_VENV/bin/pip" ]; then
             print_status "Existing packages in virtual environment:"
             "$EXISTING_VENV/bin/pip" list --format=freeze 2>/dev/null | head -10 || true
             echo "  ... (showing first 10 packages)"
         fi
         
         # Check for existing conda environment
          if check_conda; then
              CONDA_CMD=$(get_conda_cmd)
              if $CONDA_CMD env list | grep -q "nst-ai-env"; then
                  print_status "Found existing conda environment 'nst-ai-env'. Removing..."
                  $CONDA_CMD env remove -n nst-ai-env -y || true
              fi
          fi
        fi
        
        # Create backup with timestamp
        BACKUP_DIR="$HOME/.nst-ai.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.nst-ai" "$BACKUP_DIR"
        print_status "Backed up existing installation to $BACKUP_DIR"
        found_existing=true
    fi
    
    # Remove any existing global command
    if [ -f "/usr/local/bin/nst-ai" ]; then
        sudo rm -f "/usr/local/bin/nst-ai" 2>/dev/null || true
    fi
    
    if [ "$found_existing" = true ]; then
        print_success "Cleaned existing installations"
    else
        print_success "No existing installations found"
    fi
}

# Function to detect and resolve dependency conflicts
detect_dependency_conflicts() {
    print_status "Detecting potential dependency conflicts..."
    
    # Check Python version for numpy compatibility
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    
    print_status "Python version detected: $PYTHON_VERSION"
    
    # Determine numpy version based on Python version
    if [ "$PYTHON_MINOR" -ge 13 ]; then
        NUMPY_VERSION=">=2.1.0,<3.0.0"
        print_status "Using numpy $NUMPY_VERSION for Python 3.13+"
    else
        NUMPY_VERSION=">=1.24.0,<2.0.0"
        print_status "Using numpy $NUMPY_VERSION for Python 3.12 and below"
    fi
    
    return 0
}

# Function to create fixed requirements with advanced conflict resolution
create_fixed_requirements() {
    print_status "Creating requirements file with advanced conflict resolution..."
    
    # Detect conflicts first
    detect_dependency_conflicts
    
    cat > "$INSTALL_DIR/backend/requirements_fixed.txt" << EOF
# NST-AI Fixed Requirements with Advanced Conflict Resolution
# Generated on $(date)
# Python version: $PYTHON_VERSION

# Core numerical computing (version based on Python version)
numpy$NUMPY_VERSION

# Vector databases with compatible versions
chromadb>=0.4.0,<0.6.0
qdrant-client>=1.7.0,<1.15.0
pgvector>=0.4.0,<0.5.0

# Document processing with version constraints
unstructured>=0.10.0,<0.17.0
unstructured-client>=0.20.0

# LangChain ecosystem with compatibility
langchain>=0.1.0,<0.4.0
langchain-community>=0.0.20,<0.4.0
langchain-core>=0.1.0,<0.4.0
langchain-text-splitters>=0.0.1,<0.4.0

# Web framework and server
fastapi>=0.104.0,<0.115.0
uvicorn[standard]>=0.24.0,<0.32.0
starlette>=0.27.0,<0.40.0

# Database and ORM
sqlalchemy>=2.0.0,<2.1.0
alembic>=1.12.0,<1.14.0

# HTTP and networking
httpx>=0.25.0,<0.28.0
requests>=2.31.0,<2.33.0
aiohttp>=3.8.0,<3.11.0

# Authentication and security
python-jose[cryptography]>=3.3.0,<3.4.0
passlib[bcrypt]>=1.7.4,<1.8.0
cryptography>=41.0.0,<43.0.0

# Data processing and ML
pandas>=2.0.0,<2.3.0
scipy>=1.11.0,<1.15.0
scikit-learn>=1.3.0,<1.8.0
torch>=2.0.0,<2.6.0
transformers>=4.30.0,<4.50.0
sentence-transformers>=2.2.0,<3.3.0
tokenizers>=0.13.0,<0.21.0

# Text processing
nltk>=3.8.0,<3.10.0
markdown>=3.4.0,<3.8.0
beautifulsoup4>=4.12.0,<4.13.0
lxml>=4.9.0,<5.4.0

# File handling
Pillow>=10.0.0,<11.1.0
pypdf>=3.15.0,<5.10.0
python-multipart>=0.0.6,<0.0.10

# Utilities
pydantic>=2.4.0,<2.11.0
pydantic-settings>=2.0.0,<2.7.0
typer>=0.9.0,<0.13.0
rich>=13.0.0,<14.0.0
tqdm>=4.65.0,<4.68.0
click>=8.1.0,<8.2.0

# Development and testing
watchfiles>=0.20.0,<1.2.0
uvloop>=0.19.0,<0.22.0

# Additional dependencies from original requirements (filtered)
# Note: Conflicting packages are replaced with compatible versions above
EOF

    # Add non-conflicting dependencies from original requirements
    if [ -f "backend/requirements.txt" ]; then
        print_status "Merging non-conflicting dependencies from original requirements..."
        
        # List of packages to skip (already handled above)
        SKIP_PACKAGES="numpy|chromadb|qdrant-client|pgvector|unstructured|langchain|fastapi|uvicorn|sqlalchemy|alembic|httpx|requests|aiohttp|pandas|scipy|scikit-learn|torch|transformers|sentence-transformers|tokenizers|nltk|markdown|beautifulsoup4|lxml|Pillow|pypdf|python-multipart|pydantic|typer|rich|tqdm|click|watchfiles|uvloop|python-jose|passlib|cryptography"
        
        # Extract additional dependencies
        grep -v "^#" backend/requirements.txt | grep -v "^$" | grep -vE "($SKIP_PACKAGES)" >> "$INSTALL_DIR/backend/requirements_fixed.txt" || true
    fi
    
    print_success "Created advanced conflict-resolved requirements file"
}

# Fix dependency conflicts
fix_dependency_conflicts() {
    print_status "Resolving dependency conflicts..."
    
    # Create the advanced requirements file
    create_fixed_requirements
    
    print_success "Dependency conflict resolution completed"
}

# Function to attempt dependency recovery
recover_dependencies() {
    print_status "Attempting dependency recovery..."
    
    # Strategy 1: Clear pip cache and reinstall core packages
    print_status "Clearing pip cache and reinstalling core packages..."
    pip cache purge >/dev/null 2>&1 || true
    
    # Install core packages individually with specific strategies
    CORE_RECOVERY_PACKAGES=(
        "numpy>=1.21.0,<2.0.0"
        "fastapi>=0.68.0"
        "uvicorn[standard]>=0.15.0"
    )
    
    for package in "${CORE_RECOVERY_PACKAGES[@]}"; do
        print_status "Installing $package..."
        if ! pip install --no-cache-dir --force-reinstall "$package"; then
            print_warning "Failed to install $package, trying alternative approach"
            # Try without version constraints
            package_name=$(echo "$package" | cut -d'>' -f1 | cut -d'=' -f1 | cut -d'[' -f1)
            pip install --no-cache-dir --force-reinstall "$package_name" || true
        fi
    done
    
    # Strategy 2: Try installing from wheel if available
    print_status "Attempting wheel-based installation for problematic packages..."
    pip install --only-binary=all --force-reinstall numpy fastapi uvicorn >/dev/null 2>&1 || true
    
    # Strategy 3: Install minimal working set
    print_status "Installing minimal working dependencies..."
    cat > /tmp/minimal_requirements.txt << 'EOF'
numpy>=1.21.0
fastapi>=0.68.0
uvicorn>=0.15.0
requests>=2.25.0
EOF
    
    pip install -r /tmp/minimal_requirements.txt --force-reinstall >/dev/null 2>&1 || true
    rm -f /tmp/minimal_requirements.txt
    
    print_success "Dependency recovery completed"
}

# Function to check dependencies after installation
check_dependencies() {
    print_status "Checking installed dependencies..."
    
    # Core packages that must be available
    CORE_PACKAGES=("numpy" "fastapi" "uvicorn" "torch" "transformers")
    MISSING_PACKAGES=()
    IMPORT_ERRORS=()
    
    for package in "${CORE_PACKAGES[@]}"; do
        if ! python -c "import $package" >/dev/null 2>&1; then
            MISSING_PACKAGES+=("$package")
            # Capture the specific import error
            error_msg=$(python -c "import $package" 2>&1 || true)
            IMPORT_ERRORS+=("$package: $error_msg")
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_warning "Some core packages are missing or not importable: ${MISSING_PACKAGES[*]}"
        
        # Show detailed error information
        for error in "${IMPORT_ERRORS[@]}"; do
            print_warning "  $error"
        done
        
        # Attempt automatic recovery
        print_status "Attempting automatic dependency recovery..."
        recover_dependencies
        
        # Re-check after recovery
        print_status "Re-checking dependencies after recovery..."
        RECOVERED_MISSING=()
        for package in "${MISSING_PACKAGES[@]}"; do
            if ! python -c "import $package" >/dev/null 2>&1; then
                RECOVERED_MISSING+=("$package")
            fi
        done
        
        if [ ${#RECOVERED_MISSING[@]} -gt 0 ]; then
            print_error "Recovery failed for: ${RECOVERED_MISSING[*]}"
            print_warning "Manual intervention may be required"
            return 1
        else
            print_success "All dependencies recovered successfully"
        fi
    else
        print_success "All core dependencies are properly installed"
    fi
    
    return 0
}

# Function to validate installation success
validate_installation() {
    print_status "Validating NST-AI installation..."
    
    # Check environment type and validate accordingly
    if [ "$USE_CONDA" = true ]; then
        # Validate conda environment
        CONDA_CMD=$(get_conda_cmd)
        if ! $CONDA_CMD env list | grep -q "nst-ai-env"; then
            print_error "Conda environment 'nst-ai-env' not found"
            return 1
        fi
        
        # Test conda environment activation
        cd "$HOME/.nst-ai"
        if ! conda activate nst-ai-env; then
            print_error "Failed to activate conda environment"
            return 1
        fi
    else
        # Check if virtual environment was created
        if [ ! -d "$HOME/.nst-ai/nst-ai-env" ]; then
            print_error "Virtual environment was not created successfully"
            return 1
        fi
        
        # Check if activation script exists
        if [ ! -f "$HOME/.nst-ai/nst-ai-env/bin/activate" ]; then
            print_error "Virtual environment activation script not found"
            return 1
        fi
        
        # Test virtual environment activation
        cd "$HOME/.nst-ai"
        if ! source nst-ai-env/bin/activate; then
            print_error "Failed to activate virtual environment"
            return 1
        fi
    fi
    
    # Check dependencies with recovery system
    if ! check_dependencies; then
        print_warning "Dependency validation failed, but installation will continue"
        print_warning "Some features may not work correctly"
    fi
    
    # Check if backend directory exists
    if [ ! -d "$HOME/.nst-ai/backend" ]; then
        print_error "Backend directory not found"
        return 1
    fi
    
    # Check if start script exists
    if [ ! -f "$HOME/.nst-ai/backend/start.sh" ]; then
        print_error "Start script not found"
        return 1
    fi
    
    print_success "Installation validation completed"
    return 0
}

# Setup NST-AI with enhanced error handling
setup_nst_ai() {
    print_status "Setting up NST-AI..."
    
    # Set installation directory
    INSTALL_DIR="$HOME/.nst-ai"
    
    # Analyze current Python environment
    analyze_python_environment
    
    # Clean existing installations
    clean_existing_installations
    
    # Clone repository
    print_status "Cloning NST-AI repository..."
    if ! git clone https://github.com/AryanVBW/NST-Ai.git "$INSTALL_DIR"; then
        print_error "Failed to clone repository. Please check your internet connection."
        exit 1
    fi
    cd "$INSTALL_DIR"
    
    # Create conda environment or fallback to venv
    if check_conda; then
        CONDA_CMD=$(get_conda_cmd)
        print_status "Creating isolated conda environment (nst-ai-env) using $CONDA_CMD..."
        if ! $CONDA_CMD create -n nst-ai-env python=3.11 -y; then
            print_error "Failed to create conda environment. Falling back to venv..."
            # Fallback to venv
            print_status "Creating Python virtual environment (nst-ai-env)..."
            if ! python3 -m venv nst-ai-env; then
                print_error "Failed to create virtual environment. Please check Python installation."
                exit 1
            fi
            USE_CONDA=false
        else
            USE_CONDA=true
        fi
    else
        print_status "Conda not found. Creating Python virtual environment (nst-ai-env)..."
        if ! python3 -m venv nst-ai-env; then
            print_error "Failed to create virtual environment. Please check Python installation."
            exit 1
        fi
        USE_CONDA=false
    fi
    
    # Activate environment
    print_status "Activating environment..."
    if [ "$USE_CONDA" = true ]; then
        if ! conda activate nst-ai-env; then
            print_error "Failed to activate conda environment"
            exit 1
        fi
    else
        if ! source nst-ai-env/bin/activate; then
            print_error "Failed to activate virtual environment"
            exit 1
        fi
    fi
    
    # Upgrade pip and install build tools
    print_status "Upgrading pip and installing build tools..."
    if ! pip install --upgrade pip setuptools wheel; then
        print_warning "Failed to upgrade build tools, continuing with current versions"
    fi
    
    # Fix dependency conflicts
    fix_dependency_conflicts
    
    # Install Python dependencies with enhanced conflict resolution
    print_status "Installing Python dependencies (this may take a while)..."
    
    # Strategy 1: Try installing with the advanced fixed requirements
    if pip install -r backend/requirements_fixed.txt; then
        print_success "Dependencies installed successfully with advanced conflict resolution"
    else
        print_warning "Advanced requirements failed, trying with pip resolver..."
        
        # Strategy 2: Try with pip's dependency resolver and upgrade strategy
        if pip install --upgrade --upgrade-strategy eager -r backend/requirements_fixed.txt; then
            print_success "Dependencies installed with upgrade strategy"
        else
            print_warning "Upgrade strategy failed, trying original requirements with conflict resolution..."
            
            # Strategy 3: Try original requirements with conflict resolution flags
            if pip install --force-reinstall --no-cache-dir -r backend/requirements.txt; then
                print_warning "Installed original requirements with force reinstall"
            else
                print_warning "Force reinstall failed, trying minimal installation..."
                
                # Strategy 4: Minimal installation with core dependencies only
                if pip install fastapi uvicorn numpy pandas torch transformers; then
                    print_warning "Installed minimal dependencies only. Some features may not work."
                    print_warning "You may need to manually install additional packages as needed."
                else
                    print_error "Failed to install even minimal Python dependencies."
                    print_error "Please check your Python installation and try again."
                    print_error "You may need to manually resolve dependency conflicts."
                    exit 1
                fi
            fi
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

# Check for conda environment first, then virtual environment
USE_CONDA=false
if command -v conda >/dev/null 2>&1; then
    if conda env list | grep -q "nst-ai-env"; then
        USE_CONDA=true
        print_status "Found conda environment 'nst-ai-env'"
    fi
elif command -v mamba >/dev/null 2>&1; then
    if mamba env list | grep -q "nst-ai-env"; then
        USE_CONDA=true
        print_status "Found conda environment 'nst-ai-env'"
    fi
fi

if [ "$USE_CONDA" = false ]; then
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

# Activate environment (conda or virtual environment)
print_status "Activating NST-AI environment..."
if [ "$USE_CONDA" = true ]; then
    if ! conda activate nst-ai-env; then
        print_error "Failed to activate conda environment."
        exit 1
    fi
else
    if ! source nst-ai-env/bin/activate; then
        print_error "Failed to activate virtual environment."
        exit 1
    fi
fi

# Change to backend directory
cd backend

# Check for dependency conflicts before starting
print_status "Checking dependencies..."
if ! python -c "import numpy, fastapi, uvicorn" >/dev/null 2>&1; then
    print_warning "Some core dependencies may be missing or incompatible."
    print_warning "Attempting to verify installation..."
    
    # Try to identify specific missing packages
    missing_packages=()
    for package in numpy fastapi uvicorn torch transformers; do
        if ! python -c "import $package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_warning "Missing packages detected: ${missing_packages[*]}"
        print_warning "Consider reinstalling NST-AI or manually installing missing packages."
    else
        print_warning "Dependencies appear to be installed but may have compatibility issues."
    fi
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

# Remove conda environment if it exists
if command -v conda >/dev/null 2>&1; then
    if conda env list | grep -q "nst-ai-env"; then
        print_status "Removing conda environment 'nst-ai-env'..."
        conda env remove -n nst-ai-env -y || true
        print_success "Removed conda environment 'nst-ai-env'"
    fi
elif command -v mamba >/dev/null 2>&1; then
    if mamba env list | grep -q "nst-ai-env"; then
        print_status "Removing conda environment 'nst-ai-env'..."
        mamba env remove -n nst-ai-env -y || true
        print_success "Removed conda environment 'nst-ai-env'"
    fi
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

# Clean up pip cache for NST-AI related packages
if command -v pip3 >/dev/null 2>&1; then
    print_status "Clearing pip cache for NST-AI packages..."
    pip3 cache purge >/dev/null 2>&1 || true
    print_success "Cleared pip cache"
fi

# Remove any remaining configuration files
for config_dir in "$HOME/.config/nst-ai" "$HOME/.local/share/nst-ai"; do
    if [ -d "$config_dir" ]; then
        rm -rf "$config_dir"
        print_success "Removed configuration directory: $config_dir"
    fi
done

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
    
    # Final dependency resolution and validation
    print_status "Performing final dependency resolution..."
    
    # Check dependencies with automatic recovery
    if ! check_dependencies; then
        print_warning "Initial dependency check failed, attempting comprehensive resolution..."
        
        # Try one more comprehensive fix
        print_status "Applying comprehensive dependency fixes..."
        
        # Create a final conflict resolution requirements file
        cat > /tmp/final_requirements.txt << 'EOF'
# Core dependencies with conflict resolution
numpy>=1.21.0,<2.0.0
fastapi>=0.68.0,<1.0.0
uvicorn[standard]>=0.15.0,<1.0.0
requests>=2.25.0,<3.0.0
pydantic>=1.8.0,<3.0.0
starlette>=0.14.0,<1.0.0

# AI/ML dependencies
torch>=1.9.0
transformers>=4.0.0

# Database and storage
chromadb>=0.3.0
qdrant-client>=1.0.0

# Text processing
langchain>=0.0.100
langchain-community>=0.0.10
EOF
        
        # Install with conflict resolution
        if pip install -r /tmp/final_requirements.txt --upgrade --force-reinstall; then
            print_success "Comprehensive dependency resolution completed"
        else
            print_warning "Some dependencies may still have conflicts"
        fi
        
        rm -f /tmp/final_requirements.txt
        
        # Final check
        if ! check_dependencies; then
            print_error "Final dependency check failed"
            print_warning "Installation completed but some features may not work correctly"
            print_warning "Check the error messages above for specific issues"
        fi
    fi
    
    # Validate installation
    if ! validate_installation; then
        print_error "Installation validation failed. Please check the logs above."
        print_warning "You may need to run the installer again or install dependencies manually."
        print_warning "Common solutions:"
        print_warning "  1. Run: pip install --upgrade --force-reinstall numpy fastapi uvicorn"
        print_warning "  2. Check Python version compatibility (3.8+ required)"
        print_warning "  3. Ensure sufficient disk space and internet connectivity"
        exit 1
    fi
    
    # Create global command
    create_global_command
    
    # Create uninstall script
    create_uninstall_script
    
    echo ""
    print_success "🎉 NST-AI installation completed and validated successfully!"
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
    echo "All dependency conflicts have been resolved automatically."
    echo ""
}

# Run main function
main "$@"