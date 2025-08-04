/**
 * MCP (Model Context Protocol) API functions
 */

import { WEBUI_API_BASE_URL } from '$lib/constants';

type McpServer = {
	id: string;
	name: string;
	status: 'connected' | 'disconnected';
	tools_count: number;
	session_id?: string;
	transport?: string;
};

type McpServerConnection = {
	id?: string;
	name: string;
	url: string;
	transport: string;
	auth_type: string;
	auth_key?: string;
	auth_header_name?: string;
	enabled: boolean;
	config?: Record<string, any>;
};

type McpTool = {
	name: string;
	description?: string;
	inputSchema?: Record<string, any>;
};

type McpToolCall = {
	server_id: string;
	tool_name: string;
	arguments: Record<string, any>;
};

type McpToolResult = {
	server_id: string;
	tool_name: string;
	result: {
		success: boolean;
		result?: any;
		error?: string;
	};
};

/**
 * Get MCP server configuration
 */
export const getMcpServersConfig = async (token: string) => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/config`, {
		method: 'GET',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		}
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return null;
		});

	if (error) {
		throw error;
	}

	return res;
};

/**
 * Update MCP server configuration
 */
export const updateMcpServersConfig = async (token: string, servers: McpServerConnection[]) => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/config`, {
		method: 'POST',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		},
		body: JSON.stringify({
			MCP_SERVER_CONNECTIONS: servers
		})
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return null;
		});

	if (error) {
		throw error;
	}

	return res;
};

/**
 * Test connection to an MCP server
 */
export const testMcpServerConnection = async (
	token: string,
	serverConfig: {
		name: string;
		url: string;
		transport: string;
		auth_type: string;
		auth_key?: string;
		auth_header_name?: string;
	}
) => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/test`, {
		method: 'POST',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		},
		body: JSON.stringify(serverConfig)
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return null;
		});

	if (error) {
		throw error;
	}

	return res;
};

/**
 * Get list of connected MCP servers
 */
export const getConnectedMcpServers = async (token?: string): Promise<{ servers: McpServer[] }> => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/servers`, {
		method: 'GET',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		}
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return { servers: [] };
		});

	if (error) {
		throw error;
	}

	return res;
};

/**
 * Get tools available from a specific MCP server
 */
export const getMcpServerTools = async (
	serverId: string,
	token?: string
): Promise<{ server_id: string; server_name: string; session_id: string; tools: McpTool[] }> => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/servers/${serverId}/tools`, {
		method: 'GET',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		}
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return { server_id: serverId, server_name: '', session_id: '', tools: [] };
		});

	if (error) {
		throw error;
	}

	return res;
};

/**
 * Execute an MCP tool call
 */
export const callMcpTool = async (
	toolCall: McpToolCall,
	token?: string
): Promise<McpToolResult> => {
	let error = null;

	const res = await fetch(`${WEBUI_API_BASE_URL}/mcp/call`, {
		method: 'POST',
		headers: {
			Accept: 'application/json',
			'Content-Type': 'application/json',
			...(token && { authorization: `Bearer ${token}` })
		},
		body: JSON.stringify(toolCall)
	})
		.then(async (res) => {
			if (!res.ok) throw await res.json();
			return res.json();
		})
		.catch((err) => {
			error = err.detail ?? err;
			console.log(err);
			return {
				server_id: toolCall.server_id,
				tool_name: toolCall.tool_name,
				result: {
					success: false,
					error: error?.detail || error || 'Unknown error'
				}
			};
		});

	if (error) {
		throw error;
	}

	return res;
};

export {
	type McpServer,
	type McpServerConnection,
	type McpTool,
	type McpToolCall,
	type McpToolResult
};
