import { WEBUI_API_BASE_URL } from '$lib/constants';

export interface WorkflowNode {
	id: string;
	type: string;
	position: { x: number; y: number };
	data: Record<string, any>;
	inputs?: Record<string, any>;
	outputs?: Record<string, any>;
}

export interface WorkflowConnection {
	id: string;
	source: string;
	target: string;
	sourceHandle?: string;
	targetHandle?: string;
}

export interface Workflow {
	id: string | null;
	name: string;
	description?: string;
	nodes: WorkflowNode[];
	connections: WorkflowConnection[];
	variables: Record<string, any>;
	settings: {
		errorWorkflow?: string | null;
		timezone: string;
		saveDataErrorExecution: string;
		saveDataSuccessExecution: string;
	};
	tags?: string[];
	createdAt?: string;
	updatedAt?: string;
}

export interface WorkflowExecution {
	id: string;
	workflowId: string;
	status: 'new' | 'running' | 'success' | 'error' | 'canceled';
	startedAt: string;
	stoppedAt?: string;
	data?: Record<string, any>;
	error?: string;
}

class WorkflowService {
	private apiBase: string;

	constructor() {
		this.apiBase = `${WEBUI_API_BASE_URL}/workflows`;
	}

	// Workflow CRUD operations
	async getWorkflows(token: string): Promise<Workflow[]> {
		try {
			const response = await fetch(`${this.apiBase}`, {
				method: 'GET',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to fetch workflows: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error fetching workflows:', error);
			// Return mock data for now
			return this.getMockWorkflows();
		}
	}

	async getWorkflow(token: string, id: string): Promise<Workflow> {
		try {
			const response = await fetch(`${this.apiBase}/${id}`, {
				method: 'GET',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to fetch workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error fetching workflow:', error);
			throw error;
		}
	}

	async createWorkflow(token: string, workflow: Omit<Workflow, 'id'>): Promise<Workflow> {
		try {
			const response = await fetch(`${this.apiBase}`, {
				method: 'POST',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				},
				body: JSON.stringify(workflow)
			});

			if (!response.ok) {
				throw new Error(`Failed to create workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error creating workflow:', error);
			// Return mock workflow for now
			return {
				...workflow,
				id: `workflow_${Date.now()}`,
				createdAt: new Date().toISOString(),
				updatedAt: new Date().toISOString()
			};
		}
	}

	async updateWorkflow(token: string, id: string, workflow: Partial<Workflow>): Promise<Workflow> {
		try {
			const response = await fetch(`${this.apiBase}/${id}`, {
				method: 'PUT',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				},
				body: JSON.stringify(workflow)
			});

			if (!response.ok) {
				throw new Error(`Failed to update workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error updating workflow:', error);
			throw error;
		}
	}

	async deleteWorkflow(token: string, id: string): Promise<void> {
		try {
			const response = await fetch(`${this.apiBase}/${id}`, {
				method: 'DELETE',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to delete workflow: ${response.statusText}`);
			}
		} catch (error) {
			console.error('Error deleting workflow:', error);
			throw error;
		}
	}

	// Workflow execution
	async executeWorkflow(token: string, id: string, data?: Record<string, any>): Promise<WorkflowExecution> {
		try {
			const response = await fetch(`${this.apiBase}/${id}/execute`, {
				method: 'POST',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ data })
			});

			if (!response.ok) {
				throw new Error(`Failed to execute workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error executing workflow:', error);
			// Return mock execution for now
			return {
				id: `execution_${Date.now()}`,
				workflowId: id,
				status: 'running',
				startedAt: new Date().toISOString(),
				data
			};
		}
	}

	async getWorkflowExecutions(token: string, workflowId: string): Promise<WorkflowExecution[]> {
		try {
			const response = await fetch(`${this.apiBase}/${workflowId}/executions`, {
				method: 'GET',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to fetch executions: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error fetching executions:', error);
			return [];
		}
	}

	async stopExecution(token: string, executionId: string): Promise<void> {
		try {
			const response = await fetch(`${this.apiBase}/executions/${executionId}/stop`, {
				method: 'POST',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to stop execution: ${response.statusText}`);
			}
		} catch (error) {
			console.error('Error stopping execution:', error);
			throw error;
		}
	}

	// Node templates and types
	async getNodeTypes(token: string): Promise<Record<string, any>> {
		try {
			const response = await fetch(`${this.apiBase}/node-types`, {
				method: 'GET',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to fetch node types: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error fetching node types:', error);
			return this.getMockNodeTypes();
		}
	}

	// Import/Export
	async importWorkflow(token: string, workflowData: any): Promise<Workflow> {
		try {
			const response = await fetch(`${this.apiBase}/import`, {
				method: 'POST',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				},
				body: JSON.stringify(workflowData)
			});

			if (!response.ok) {
				throw new Error(`Failed to import workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error importing workflow:', error);
			throw error;
		}
	}

	async exportWorkflow(token: string, id: string): Promise<any> {
		try {
			const response = await fetch(`${this.apiBase}/${id}/export`, {
				method: 'GET',
				headers: {
					Authorization: `Bearer ${token}`,
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Failed to export workflow: ${response.statusText}`);
			}

			return await response.json();
		} catch (error) {
			console.error('Error exporting workflow:', error);
			throw error;
		}
	}

	// Mock data methods (for development)
	private getMockWorkflows(): Workflow[] {
		return [
			{
				id: 'workflow_1',
				name: 'Chat Processing Workflow',
				description: 'Process and analyze chat messages',
				nodes: [
					{
						id: 'start',
						type: 'nst-trigger',
						position: { x: 100, y: 100 },
						data: { label: 'Chat Trigger' }
					},
					{
						id: 'process',
						type: 'nst-chat',
						position: { x: 300, y: 100 },
						data: { label: 'Process Message' }
					}
				],
				connections: [
					{
						id: 'conn_1',
						source: 'start',
						target: 'process'
					}
				],
				variables: {},
				settings: {
					timezone: 'UTC',
					saveDataErrorExecution: 'all',
					saveDataSuccessExecution: 'all'
				},
				tags: ['chat', 'processing'],
				createdAt: '2024-01-01T00:00:00Z',
				updatedAt: '2024-01-01T00:00:00Z'
			}
		];
	}

	private getMockNodeTypes(): Record<string, any> {
		return {
			'nst-core': {
				'nst-chat': {
					displayName: 'NST Chat',
					name: 'nst-chat',
					icon: '💬',
					group: ['NST-AI Core'],
					description: 'Chat with NST-AI models',
					defaults: {
						name: 'NST Chat',
				        color: '#3B82F6'
					},
					inputs: ['main'],
					outputs: ['main'],
					properties: [
						{
							displayName: 'Model',
							name: 'model',
							type: 'options',
							options: [
								{ name: 'GPT-4', value: 'gpt-4' },
								{ name: 'Claude', value: 'claude' },
								{ name: 'Custom', value: 'custom' }
							],
							default: 'gpt-4'
						},
						{
							displayName: 'Message',
							name: 'message',
							type: 'string',
							typeOptions: {
								rows: 4
							},
							default: ''
						}
					]
				},
				'nst-model': {
					displayName: 'NST Model',
					name: 'nst-model',
					icon: '🤖',
					group: ['NST-AI Core'],
					description: 'Configure AI model settings',
					defaults: {
						name: 'NST Model',
						color: '#10B981'
					},
					inputs: ['main'],
					outputs: ['main'],
					properties: [
						{
							displayName: 'Model Type',
							name: 'modelType',
							type: 'options',
							options: [
								{ name: 'Text Generation', value: 'text' },
								{ name: 'Image Generation', value: 'image' },
								{ name: 'Code Generation', value: 'code' }
							],
							default: 'text'
						}
					]
				},
				'nst-prompt': {
					displayName: 'NST Prompt',
					name: 'nst-prompt',
					icon: '📝',
					group: ['NST-AI Core'],
					description: 'Create and manage prompts',
					defaults: {
						name: 'NST Prompt',
						color: '#F59E0B'
					},
					inputs: ['main'],
					outputs: ['main'],
					properties: [
						{
							displayName: 'Prompt Template',
							name: 'template',
							type: 'string',
							typeOptions: {
								rows: 6
							},
							default: ''
						}
					]
				}
			}
		};
	}

	// Server management methods
	async getWorkflowConfig(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/config`, {
			method: 'GET',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to get workflow config: ${response.statusText}`);
		}

		return response.json();
	}

	async updateWorkflowConfig(token: string, config: any) {
		const response = await fetch(`${this.apiBase}/workflows/config`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			},
			body: JSON.stringify(config)
		});

		if (!response.ok) {
			throw new Error(`Failed to update workflow config: ${response.statusText}`);
		}

		return response.json();
	}

	async getWorkflowStatus(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/status`, {
			method: 'GET',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to get workflow status: ${response.statusText}`);
		}

		return response.json();
	}

	async startWorkflowServer(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/start`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to start workflow server: ${response.statusText}`);
		}

		return response.json();
	}

	async stopWorkflowServer(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/stop`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to stop workflow server: ${response.statusText}`);
		}

		return response.json();
	}

	async restartWorkflowServer(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/restart`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to restart workflow server: ${response.statusText}`);
		}

		return response.json();
	}

	async checkWorkflowHealth(token: string) {
		const response = await fetch(`${this.apiBase}/workflows/health`, {
			method: 'GET',
			headers: {
				'Content-Type': 'application/json',
				Authorization: `Bearer ${token}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to check workflow health: ${response.statusText}`);
		}

		return response.json();
	}
}

export const workflowService = new WorkflowService();
