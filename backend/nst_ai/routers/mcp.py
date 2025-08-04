"""
Model Context Protocol (MCP) server management and integration.

This module provides APIs for managing MCP server connections,
discovering available tools, and executing MCP tool calls.
"""

import logging
import asyncio
import aiohttp
import os
import json
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, ConfigDict
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse

from nst_ai.utils.auth import get_admin_user, get_verified_user
from nst_ai.config import PersistentConfig


log = logging.getLogger(__name__)
router = APIRouter()


class McpServerConnection(BaseModel):
    """MCP Server Connection Configuration"""
    id: Optional[str] = None
    name: str
    url: str
    transport: str = "sse"  # "sse" or "httpStreamable"
    auth_type: Optional[str] = "none"  # "none", "bearer", "header"
    auth_key: Optional[str] = None
    auth_header_name: Optional[str] = None
    enabled: bool = True
    config: Optional[dict] = None
    
    model_config = ConfigDict(extra="allow")


class McpServersConfigForm(BaseModel):
    """Form for managing MCP server connections"""
    MCP_SERVER_CONNECTIONS: List[McpServerConnection]


class McpServerTestForm(BaseModel):
    """Form for testing MCP server connection"""
    name: str
    url: str
    transport: str = "sse"
    auth_type: str = "none"
    auth_key: Optional[str] = None
    auth_header_name: Optional[str] = None


class McpToolCall(BaseModel):
    """MCP Tool Call Request"""
    server_id: str
    tool_name: str
    arguments: Dict[str, Any]


# Persistent configuration for MCP servers
try:
    mcp_server_connections = json.loads(
        os.environ.get("MCP_SERVER_CONNECTIONS", "[]")
    )
except Exception as e:
    log.exception(f"Error loading MCP_SERVER_CONNECTIONS: {e}")
    mcp_server_connections = []

MCP_SERVER_CONNECTIONS = PersistentConfig(
    "MCP_SERVER_CONNECTIONS",
    "mcp.server_connections",
    mcp_server_connections,
)


async def create_mcp_client_session(server: McpServerConnection) -> Optional[Dict[str, Any]]:
    """Create a new MCP client session with the specified server"""
    try:
        headers = {}
        
        # Add authentication headers if configured
        if server.auth_type == "bearer" and server.auth_key:
            headers["Authorization"] = f"Bearer {server.auth_key}"
        elif server.auth_type == "header" and server.auth_key and server.auth_header_name:
            headers[server.auth_header_name] = server.auth_key
        
        # For SSE transport, establish connection
        if server.transport == "sse":
            async with aiohttp.ClientSession(headers=headers) as session:
                async with session.get(f"{server.url}/sse") as response:
                    if response.status == 200:
                        return {
                            "server_id": server.id,
                            "session_id": response.headers.get("X-Session-ID"),
                            "status": "connected",
                            "transport": "sse"
                        }
        
        # For HTTP Streamable transport
        elif server.transport == "httpStreamable":
            async with aiohttp.ClientSession(headers=headers) as session:
                async with session.post(server.url, json={}) as response:
                    if response.status == 200:
                        return {
                            "server_id": server.id,
                            "session_id": response.headers.get("mcp-session-id"),
                            "status": "connected",
                            "transport": "httpStreamable"
                        }
        
        return None
        
    except Exception as e:
        log.error(f"Failed to connect to MCP server {server.name}: {e}")
        return None


async def get_mcp_server_tools(server: McpServerConnection, session_id: str = None) -> List[Dict[str, Any]]:
    """Get available tools from an MCP server"""
    try:
        headers = {}
        
        # Add authentication headers
        if server.auth_type == "bearer" and server.auth_key:
            headers["Authorization"] = f"Bearer {server.auth_key}"
        elif server.auth_type == "header" and server.auth_key and server.auth_header_name:
            headers[server.auth_header_name] = server.auth_key
        
        # Add session headers if available
        if session_id:
            if server.transport == "sse":
                # For SSE, session ID goes in query params
                url = f"{server.url}?sessionId={session_id}"
            else:
                # For HTTP Streamable, session ID goes in headers
                headers["mcp-session-id"] = session_id
                url = server.url
        else:
            url = server.url
        
        # Request to list tools
        tools_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/list"
        }
        
        async with aiohttp.ClientSession(headers=headers) as session:
            async with session.post(url, json=tools_request) as response:
                if response.status == 200:
                    data = await response.json()
                    if "result" in data and "tools" in data["result"]:
                        return data["result"]["tools"]
        
        return []
        
    except Exception as e:
        log.error(f"Failed to get tools from MCP server {server.name}: {e}")
        return []


async def call_mcp_tool(
    server: McpServerConnection,
    tool_name: str,
    arguments: Dict[str, Any],
    session_id: str = None
) -> Dict[str, Any]:
    """Call a specific tool on an MCP server"""
    try:
        headers = {}
        
        # Add authentication headers
        if server.auth_type == "bearer" and server.auth_key:
            headers["Authorization"] = f"Bearer {server.auth_key}"
        elif server.auth_type == "header" and server.auth_key and server.auth_header_name:
            headers[server.auth_header_name] = server.auth_key
        
        # Add session headers if available
        if session_id:
            if server.transport == "sse":
                url = f"{server.url}?sessionId={session_id}"
            else:
                headers["mcp-session-id"] = session_id
                url = server.url
        else:
            url = server.url
        
        # Tool call request
        tool_request = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments
            }
        }
        
        async with aiohttp.ClientSession(headers=headers) as session:
            async with session.post(url, json=tool_request) as response:
                if response.status == 200:
                    data = await response.json()
                    if "result" in data:
                        return {
                            "success": True,
                            "result": data["result"]
                        }
                    elif "error" in data:
                        return {
                            "success": False,
                            "error": data["error"]
                        }
                
                return {
                    "success": False,
                    "error": f"HTTP {response.status}: {await response.text()}"
                }
        
    except Exception as e:
        log.error(f"Failed to call tool {tool_name} on MCP server {server.name}: {e}")
        return {
            "success": False,
            "error": str(e)
        }


@router.get("/config", response_model=McpServersConfigForm)
async def get_mcp_servers_config(request: Request, user=Depends(get_admin_user)):
    """Get MCP server connections configuration"""
    return {
        "MCP_SERVER_CONNECTIONS": request.app.state.config.MCP_SERVER_CONNECTIONS,
    }


@router.post("/config", response_model=McpServersConfigForm)
async def set_mcp_servers_config(
    request: Request,
    form_data: McpServersConfigForm,
    user=Depends(get_admin_user),
):
    """Update MCP server connections configuration"""
    # Generate IDs for new connections
    for i, connection in enumerate(form_data.MCP_SERVER_CONNECTIONS):
        if not connection.id:
            connection.id = f"mcp_server_{i}_{hash(connection.name + connection.url) % 10000}"
    
    request.app.state.config.MCP_SERVER_CONNECTIONS = [
        connection.model_dump() for connection in form_data.MCP_SERVER_CONNECTIONS
    ]
    
    # Store the connections in app state for quick access
    request.app.state.MCP_SERVERS = {
        conn.id: conn for conn in form_data.MCP_SERVER_CONNECTIONS if conn.enabled
    }
    
    return {
        "MCP_SERVER_CONNECTIONS": request.app.state.config.MCP_SERVER_CONNECTIONS,
    }


@router.post("/test")
async def test_mcp_server_connection(
    request: Request,
    form_data: McpServerTestForm,
    user=Depends(get_admin_user)
):
    """Test connection to an MCP server"""
    try:
        # Create a temporary server connection object for testing
        test_server = McpServerConnection(
            id="test",
            name=form_data.name,
            url=form_data.url,
            transport=form_data.transport,
            auth_type=form_data.auth_type,
            auth_key=form_data.auth_key,
            auth_header_name=form_data.auth_header_name,
            enabled=True
        )
        
        # Try to establish connection
        session = await create_mcp_client_session(test_server)
        
        if session:
            # Try to get tools list
            tools = await get_mcp_server_tools(test_server, session.get("session_id"))
            
            return {
                "success": True,
                "message": "Connection successful",
                "session": session,
                "tools_count": len(tools),
                "tools": tools[:5]  # Return first 5 tools as preview
            }
        else:
            return {
                "success": False,
                "message": "Failed to establish connection with MCP server"
            }
            
    except Exception as e:
        log.error(f"MCP server test failed: {e}")
        return {
            "success": False,
            "message": f"Connection test failed: {str(e)}"
        }


@router.get("/servers")
async def get_connected_mcp_servers(request: Request, user=Depends(get_verified_user)):
    """Get list of connected MCP servers available to the user"""
    try:
        servers = getattr(request.app.state, 'MCP_SERVERS', {})
        connected_servers = []
        
        for server_id, server_config in servers.items():
            if server_config.get('enabled', True):
                # Create session and get tools
                server = McpServerConnection(**server_config)
                session = await create_mcp_client_session(server)
                
                if session:
                    tools = await get_mcp_server_tools(server, session.get("session_id"))
                    connected_servers.append({
                        "id": server_id,
                        "name": server.name,
                        "status": "connected",
                        "tools_count": len(tools),
                        "session_id": session.get("session_id"),
                        "transport": server.transport
                    })
                else:
                    connected_servers.append({
                        "id": server_id,
                        "name": server.name,
                        "status": "disconnected",
                        "tools_count": 0
                    })
        
        return {
            "servers": connected_servers
        }
        
    except Exception as e:
        log.error(f"Failed to get MCP servers: {e}")
        raise HTTPException(status_code=500, detail="Failed to get MCP servers")


@router.get("/servers/{server_id}/tools")
async def get_mcp_server_tools_endpoint(
    server_id: str,
    request: Request,
    user=Depends(get_verified_user)
):
    """Get available tools from a specific MCP server"""
    try:
        servers = getattr(request.app.state, 'MCP_SERVERS', {})
        
        if server_id not in servers:
            raise HTTPException(status_code=404, detail="MCP server not found")
        
        server_config = servers[server_id]
        server = McpServerConnection(**server_config)
        
        # Create session and get tools
        session = await create_mcp_client_session(server)
        
        if session:
            tools = await get_mcp_server_tools(server, session.get("session_id"))
            return {
                "server_id": server_id,
                "server_name": server.name,
                "session_id": session.get("session_id"),
                "tools": tools
            }
        else:
            raise HTTPException(status_code=503, detail="Failed to connect to MCP server")
            
    except HTTPException:
        raise
    except Exception as e:
        log.error(f"Failed to get tools for MCP server {server_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to get MCP server tools")


@router.post("/call")
async def call_mcp_tool_endpoint(
    request: Request,
    tool_call: McpToolCall,
    user=Depends(get_verified_user)
):
    """Execute a tool call on an MCP server"""
    try:
        servers = getattr(request.app.state, 'MCP_SERVERS', {})
        
        if tool_call.server_id not in servers:
            raise HTTPException(status_code=404, detail="MCP server not found")
        
        server_config = servers[tool_call.server_id]
        server = McpServerConnection(**server_config)
        
        # Create session and call tool
        session = await create_mcp_client_session(server)
        
        if session:
            result = await call_mcp_tool(
                server,
                tool_call.tool_name,
                tool_call.arguments,
                session.get("session_id")
            )
            
            return {
                "server_id": tool_call.server_id,
                "tool_name": tool_call.tool_name,
                "result": result
            }
        else:
            raise HTTPException(status_code=503, detail="Failed to connect to MCP server")
            
    except HTTPException:
        raise
    except Exception as e:
        log.error(f"Failed to call MCP tool: {e}")
        raise HTTPException(status_code=500, detail="Failed to execute MCP tool call")



