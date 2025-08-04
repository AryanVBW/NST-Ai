#!/bin/bash

# Test script for MCP integration
echo "Testing NST-AI MCP Integration..."

# 1. Test backend server
echo "1. Testing backend server..."
cd backend
python -m nst_ai.main &
BACKEND_PID=$!
sleep 5

# Test if backend is running
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Backend server is running"
else
    echo "❌ Backend server failed to start"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# 2. Test MCP API endpoints
echo "2. Testing MCP API endpoints..."

# Test config endpoint
echo "  - Testing /api/v1/mcp/config"
curl -f http://localhost:8080/api/v1/mcp/config > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✅ MCP config endpoint accessible"
else
    echo "  ❌ MCP config endpoint failed"
fi

# Test servers endpoint
echo "  - Testing /api/v1/mcp/servers"
curl -f http://localhost:8080/api/v1/mcp/servers > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✅ MCP servers endpoint accessible"
else
    echo "  ❌ MCP servers endpoint failed"
fi

# 3. Test frontend build
echo "3. Testing frontend build..."
cd ../
npm run build > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Frontend builds successfully"
else
    echo "❌ Frontend build failed"
fi

# Cleanup
kill $BACKEND_PID 2>/dev/null
echo "🎉 MCP integration test completed!"
