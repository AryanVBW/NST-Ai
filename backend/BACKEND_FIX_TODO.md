# Backend Fix TODO List

## Current Issues Identified:
1. ❌ Missing `overrides` module (chromadb dependency)
2. ❌ Missing `build` tools for psycopg2-binary compilation 
3. ❌ Missing `sentencepiece` compilation dependencies
4. ❌ Dependency conflicts with numpy versions
5. ❌ Some packages failing to build on Python 3.13

## Priority Fix Plan:

### Phase 1: Critical Dependencies (Required for startup)
- [x] 1.1 Install `overrides` module ✅
- [x] 1.2 Install chromadb with proper dependencies ✅
- [x] 1.3 Test if server starts with minimal dependencies ✅

**PHASE 1 COMPLETE** - Backend is now running successfully on http://localhost:8080

### Phase 2: Database Dependencies 
- [ ] 2.1 Try alternative to psycopg2-binary (use psycopg2 or asyncpg only)
- [ ] 2.2 Install database packages that work with Python 3.13
- [ ] 2.3 Test database connectivity

### Phase 3: ML/AI Dependencies (Optional for basic startup)
- [ ] 3.1 Skip sentencepiece for now (can be added later)
- [ ] 3.2 Install transformers and sentence-transformers separately
- [ ] 3.3 Install other AI packages that don't have build issues

### Phase 4: Vector Database Dependencies
- [ ] 4.1 Install vector database clients (qdrant, pinecone, etc.)
- [ ] 4.2 Test vector database connections

### Phase 5: Additional Features
- [ ] 5.1 Install document processing libraries
- [ ] 5.2 Install web scraping dependencies
- [ ] 5.3 Install monitoring and observability tools

## Fix Strategy:
1. **Start minimal**: Get the server running with core dependencies only
2. **Add incrementally**: Add feature dependencies one by one
3. **Test each step**: Ensure server still starts after each addition
4. **Document failures**: Keep track of what doesn't work for later

## Commands to Execute:
```bash
# Phase 1 - Critical fixes
pip install overrides
pip install chromadb  # with dependencies this time
python -m uvicorn nst_ai.main:app --host 0.0.0.0 --port 8080  # test

# Phase 2 - Database fixes  
pip install asyncpg  # alternative to psycopg2-binary
pip install sqlalchemy alembic peewee

# Phase 3 - Skip problematic packages
# Skip: psycopg2-binary, sentencepiece for now

# Test server startup after each phase
```

## Expected Outcome:
- ✅ Server starts successfully
- ✅ Basic API endpoints work
- ✅ Database connections established
- ⚠️ Some advanced features may not work initially (can be fixed later)
