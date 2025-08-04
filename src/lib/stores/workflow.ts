import { writable, derived } from 'svelte/store';
import type { Workflow, WorkflowNode, WorkflowConnection, WorkflowExecution } from '$lib/apis/workflows';

// Main workflow state
export const currentWorkflow = writable<Workflow | null>(null);
export const workflows = writable<Workflow[]>([]);
export const workflowExecutions = writable<WorkflowExecution[]>([]);

// Editor state
export const selectedNodes = writable<string[]>([]);
export const selectedConnections = writable<string[]>([]);
export const editorMode = writable<'design' | 'execute' | 'debug'>('design');
export const canvasZoom = writable<number>(1);
export const canvasPosition = writable<{ x: number; y: number }>({ x: 0, y: 0 });

// Node panel state
export const nodePanelOpen = writable<boolean>(true);
export const propertyPanelOpen = writable<boolean>(true);
export const selectedNodeForProperties = writable<string | null>(null);

// Execution state
export const isExecuting = writable<boolean>(false);
export const executionData = writable<Record<string, any>>({});
export const executionProgress = writable<Record<string, 'waiting' | 'running' | 'success' | 'error'>>({});

// Workflow validation
export const workflowErrors = writable<Array<{ nodeId: string; message: string }>>([]);
export const workflowWarnings = writable<Array<{ nodeId: string; message: string }>>([]);

// Derived stores
export const hasUnsavedChanges = derived(
	currentWorkflow,
	($currentWorkflow) => {
		// This would compare with the last saved state
		return false; // Placeholder
	}
);

export const canExecute = derived(
	[currentWorkflow, workflowErrors, isExecuting],
	([$currentWorkflow, $workflowErrors, $isExecuting]) => {
		return $currentWorkflow && 
			   $currentWorkflow.nodes.length > 0 && 
			   $workflowErrors.length === 0 && 
			   !$isExecuting;
	}
);

export const nodeCount = derived(
	currentWorkflow,
	($currentWorkflow) => $currentWorkflow?.nodes.length || 0
);

export const connectionCount = derived(
	currentWorkflow,
	($currentWorkflow) => $currentWorkflow?.connections.length || 0
);

// Actions
export const workflowActions = {
	// Workflow management
	setCurrentWorkflow: (workflow: Workflow | null) => {
		currentWorkflow.set(workflow);
		selectedNodes.set([]);
		selectedConnections.set([]);
		selectedNodeForProperties.set(null);
	},

	updateWorkflowName: (name: string) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return { ...workflow, name };
			}
			return workflow;
		});
	},

	updateWorkflowDescription: (description: string) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return { ...workflow, description };
			}
			return workflow;
		});
	},

	// Node management
	addNode: (node: WorkflowNode) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return {
					...workflow,
					nodes: [...workflow.nodes, node]
				};
			}
			return workflow;
		});
	},

	updateNode: (nodeId: string, updates: Partial<WorkflowNode>) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return {
					...workflow,
					nodes: workflow.nodes.map(node => 
						node.id === nodeId ? { ...node, ...updates } : node
					)
				};
			}
			return workflow;
		});
	},

	removeNode: (nodeId: string) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return {
					...workflow,
					nodes: workflow.nodes.filter(node => node.id !== nodeId),
					connections: workflow.connections.filter(
						conn => conn.source !== nodeId && conn.target !== nodeId
					)
				};
			}
			return workflow;
		});
		selectedNodes.update(selected => selected.filter(id => id !== nodeId));
	},

	duplicateNode: (nodeId: string) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				const originalNode = workflow.nodes.find(node => node.id === nodeId);
				if (originalNode) {
					const newNode: WorkflowNode = {
						...originalNode,
						id: `${originalNode.type}_${Date.now()}`,
						position: {
							x: originalNode.position.x + 50,
							y: originalNode.position.y + 50
						}
					};
					return {
						...workflow,
						nodes: [...workflow.nodes, newNode]
					};
				}
			}
			return workflow;
		});
	},

	// Connection management
	addConnection: (connection: WorkflowConnection) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				// Check if connection already exists
				const exists = workflow.connections.some(
					conn => conn.source === connection.source && 
					        conn.target === connection.target &&
					        conn.sourceHandle === connection.sourceHandle &&
					        conn.targetHandle === connection.targetHandle
				);
				
				if (!exists) {
					return {
						...workflow,
						connections: [...workflow.connections, connection]
					};
				}
			}
			return workflow;
		});
	},

	removeConnection: (connectionId: string) => {
		currentWorkflow.update(workflow => {
			if (workflow) {
				return {
					...workflow,
					connections: workflow.connections.filter(conn => conn.id !== connectionId)
				};
			}
			return workflow;
		});
		selectedConnections.update(selected => selected.filter(id => id !== connectionId));
	},

	// Selection management
	selectNode: (nodeId: string) => {
		selectedNodes.set([nodeId]);
		selectedNodeForProperties.set(nodeId);
	},

	toggleNodeSelection: (nodeId: string) => {
		selectedNodes.update(selected => {
			if (selected.includes(nodeId)) {
				return selected.filter(id => id !== nodeId);
			} else {
				return [...selected, nodeId];
			}
		});
	},

	addNodeToSelection: (nodeId: string) => {
		selectedNodes.update(selected => {
			if (!selected.includes(nodeId)) {
				return [...selected, nodeId];
			}
			return selected;
		});
	},

	selectConnection: (connectionId: string) => {
		selectedConnections.set([connectionId]);
	},

	toggleConnectionSelection: (connectionId: string) => {
		selectedConnections.update(selected => {
			if (selected.includes(connectionId)) {
				return selected.filter(id => id !== connectionId);
			} else {
				return [...selected, connectionId];
			}
		});
	},

	addConnectionToSelection: (connectionId: string) => {
		selectedConnections.update(selected => {
			if (!selected.includes(connectionId)) {
				return [...selected, connectionId];
			}
			return selected;
		});
	},

	clearSelection: () => {
		selectedNodes.set([]);
		selectedConnections.set([]);
		selectedNodeForProperties.set(null);
	},

	// Canvas management
	setCanvasZoom: (zoom: number) => {
		canvasZoom.set(Math.max(0.1, Math.min(3, zoom)));
	},

	setCanvasPosition: (position: { x: number; y: number }) => {
		canvasPosition.set(position);
	},

	// Panel management
	toggleNodePanel: () => {
		nodePanelOpen.update(open => !open);
	},

	togglePropertyPanel: () => {
		propertyPanelOpen.update(open => !open);
	},

	// Execution management
	startExecution: () => {
		isExecuting.set(true);
		executionProgress.set({});
	},

	stopExecution: () => {
		isExecuting.set(false);
		executionProgress.set({});
	},

	updateExecutionProgress: (nodeId: string, status: 'waiting' | 'running' | 'success' | 'error') => {
		executionProgress.update(progress => ({
			...progress,
			[nodeId]: status
		}));
	},

	// Validation
	validateWorkflow: () => {
		const errors: Array<{ nodeId: string; message: string }> = [];
		const warnings: Array<{ nodeId: string; message: string }> = [];

		currentWorkflow.subscribe(workflow => {
			if (workflow) {
				// Check for disconnected nodes
				workflow.nodes.forEach(node => {
					const hasIncoming = workflow.connections.some(conn => conn.target === node.id);
					const hasOutgoing = workflow.connections.some(conn => conn.source === node.id);
					
					if (!hasIncoming && !hasOutgoing && workflow.nodes.length > 1) {
						warnings.push({
							nodeId: node.id,
							message: 'Node is not connected to the workflow'
						});
					}
				});

				// Check for required fields
				workflow.nodes.forEach(node => {
					if (!node.data || Object.keys(node.data).length === 0) {
						warnings.push({
							nodeId: node.id,
							message: 'Node configuration is incomplete'
						});
					}
				});
			}
		})();

		workflowErrors.set(errors);
		workflowWarnings.set(warnings);
	},

	// Reset all stores
	reset: () => {
		currentWorkflow.set(null);
		workflows.set([]);
		workflowExecutions.set([]);
		selectedNodes.set([]);
		selectedConnections.set([]);
		editorMode.set('design');
		canvasZoom.set(1);
		canvasPosition.set({ x: 0, y: 0 });
		nodePanelOpen.set(true);
		propertyPanelOpen.set(true);
		selectedNodeForProperties.set(null);
		isExecuting.set(false);
		executionData.set({});
		executionProgress.set({});
		workflowErrors.set([]);
		workflowWarnings.set([]);
	}
};
