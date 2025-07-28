#!/bin/bash

# Test script for dependency conflict resolution logic

# Source the color functions from install.sh
source ./install.sh

# Create a test environment
TEST_DIR="/tmp/nst-ai-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "\n===== Testing Dependency Conflict Resolution Logic ====="

# Create a virtual environment
print_status "Creating test virtual environment..."
python3 -m venv test-env
source test-env/bin/activate

# Create conflicting requirements file
cat > requirements_conflict.txt << 'EOF'
numpy==1.19.5
fastapi==0.68.0
uvicorn==0.15.0
chromadb==0.4.18
langchain==0.0.267
langchain-community==0.0.10
qdrant-client==1.5.4
EOF

# Create a test function for dependency recovery
test_dependency_recovery() {
    print_status "Testing dependency recovery function..."
    
    # Install conflicting packages
    print_status "Installing conflicting packages..."
    pip install -r requirements_conflict.txt
    
    # Source the recover_dependencies function
    source /Users/vivek-w/Production/PyPI/NST-Ai/install.sh
    
    # Run recovery function
    print_status "Running dependency recovery..."
    recover_dependencies
    
    # Test imports
    print_status "Testing imports after recovery..."
    if python -c "import numpy; import fastapi; import uvicorn" 2>/dev/null; then
        print_success "Recovery successful - core packages can be imported"
    else
        print_error "Recovery failed - core packages cannot be imported"
    fi
}

# Test the fixed requirements function
test_fixed_requirements() {
    print_status "Testing fixed requirements function..."
    
    # Source the create_fixed_requirements function
    source /Users/vivek-w/Production/PyPI/NST-Ai/install.sh
    
    # Create fixed requirements
    print_status "Creating fixed requirements..."
    create_fixed_requirements
    
    if [ -f "/tmp/fixed_requirements.txt" ]; then
        print_success "Fixed requirements file created successfully"
        echo "Contents of fixed requirements file:"
        cat /tmp/fixed_requirements.txt
    else
        print_error "Failed to create fixed requirements file"
    fi
}

# Test the comprehensive dependency resolution
test_comprehensive_resolution() {
    print_status "Testing comprehensive dependency resolution..."
    
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
    print_status "Installing with comprehensive conflict resolution..."
    if pip install -r /tmp/final_requirements.txt --upgrade --force-reinstall; then
        print_success "Comprehensive dependency resolution completed"
    else
        print_warning "Some dependencies may still have conflicts"
    fi
    
    # Test imports
    print_status "Testing imports after comprehensive resolution..."
    if python -c "import numpy; import fastapi; import uvicorn; import langchain; import chromadb" 2>/dev/null; then
        print_success "Comprehensive resolution successful - all packages can be imported"
    else
        print_error "Comprehensive resolution failed - some packages cannot be imported"
    fi
}

# Run tests
test_fixed_requirements
test_dependency_recovery
test_comprehensive_resolution

# Clean up
deactivate
rm -rf "$TEST_DIR"

echo "\n===== Dependency Conflict Resolution Tests Completed ====="