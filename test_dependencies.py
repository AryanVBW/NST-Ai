#!/usr/bin/env python3
"""
Test script to verify that the dependency conflicts have been resolved.
This script attempts to import all the problematic packages that were causing
numpy version conflicts.
"""

import sys

def test_imports():
    """Test importing all the packages that had numpy conflicts."""
    packages_to_test = [
        ('numpy', 'NumPy'),
        ('pgvector', 'pgvector'),
        ('langchain_community', 'LangChain Community'),
        ('chromadb', 'ChromaDB'),
        ('qdrant_client', 'Qdrant Client'),
        ('unstructured', 'Unstructured'),
        ('fastapi', 'FastAPI'),
        ('uvicorn', 'Uvicorn')
    ]
    
    print("🔍 Testing dependency imports...\n")
    
    success_count = 0
    total_count = len(packages_to_test)
    
    for package_name, display_name in packages_to_test:
        try:
            __import__(package_name)
            print(f"✅ {display_name}: Successfully imported")
            success_count += 1
        except ImportError as e:
            print(f"❌ {display_name}: Import failed - {e}")
        except Exception as e:
            print(f"⚠️  {display_name}: Unexpected error - {e}")
    
    print(f"\n📊 Results: {success_count}/{total_count} packages imported successfully")
    
    if success_count == total_count:
        print("🎉 All dependency conflicts have been resolved!")
        return True
    else:
        print("⚠️  Some packages still have issues. Check the installation.")
        return False

if __name__ == "__main__":
    print("NST-AI Dependency Conflict Resolution Test")
    print("=" * 50)
    
    # Check Python version
    print(f"🐍 Python version: {sys.version}")
    print(f"📍 Python executable: {sys.executable}\n")
    
    success = test_imports()
    sys.exit(0 if success else 1)