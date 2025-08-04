<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import { workflowActions, currentWorkflow, selectedNodes, isExecuting } from '$lib/stores/workflow';
	import { workflowService } from '$lib/apis/workflows';
	import type { WorkflowNode, WorkflowConnection } from '$lib/apis/workflows';

	export let workflowData = null;
	
	let workflowContainer: HTMLElement;
	let workflowEditor: any = null;
	let isLoading = true;
	let error: string | null = null;
	let isDragging = false;
	let draggedNodeType: string | null = null;

	// Node types with NST-AI branding
	const nodeCategories = [
		{
			name: 'NST-AI Core',
			icon: '🚀',
			nodes: [
				{ type: 'nst-chat', name: 'Chat', icon: '💬', description: 'Interact with NST-AI chat models' },
				{ type: 'nst-model', name: 'Model', icon: '🤖', description: 'Configure AI model settings' },
				{ type: 'nst-prompt', name: 'Prompt', icon: '📝', description: 'Create and manage prompts' },
				{ type: 'nst-memory', name: 'Memory', icon: '🧠', description: 'Manage conversation memory' },
				{ type: 'nst-tools', name: 'Tools', icon: '🔧', description: 'Use NST-AI tools and functions' }
			]
		},
		{
			name: 'Data Processing',
			icon: '📊',
			nodes: [
				{ type: 'data-input', name: 'Input', icon: '📥', description: 'Receive input data' },
				{ type: 'data-output', name: 'Output', icon: '📤', description: 'Send output data' },
				{ type: 'data-transform', name: 'Transform', icon: '🔄', description: 'Transform data' },
				{ type: 'data-filter', name: 'Filter', icon: '🔍', description: 'Filter data based on conditions' }
			]
		},
		{
			name: 'Logic & Control',
			icon: '⚡',
			nodes: [
				{ type: 'logic-if', name: 'If/Else', icon: '❓', description: 'Conditional logic' },
				{ type: 'logic-switch', name: 'Switch', icon: '🔀', description: 'Multi-path routing' },
				{ type: 'logic-merge', name: 'Merge', icon: '🔗', description: 'Merge multiple inputs' },
				{ type: 'logic-delay', name: 'Delay', icon: '⏱️', description: 'Add time delays' }
			]
		},
		{
			name: 'Integrations',
			icon: '🔌',
			nodes: [
				{ type: 'api-request', name: 'HTTP Request', icon: '🌐', description: 'Make HTTP requests' },
				{ type: 'webhook', name: 'Webhook', icon: '📡', description: 'Receive webhook data' },
				{ type: 'database', name: 'Database', icon: '🗄️', description: 'Database operations' },
				{ type: 'email', name: 'Email', icon: '📧', description: 'Send/receive emails' }
			]
		}
	];

	onMount(async () => {
		if (browser && workflowContainer) {
			await initializeWorkflowEditor();
		}
	});

	onDestroy(() => {
		if (workflowEditor) {
			workflowEditor.destroy?.();
		}
	});

	const initializeWorkflowEditor = async () => {
		try {
			isLoading = true;
			error = null;

			// Initialize empty workflow if none provided
			if (!$currentWorkflow) {
				workflowActions.setCurrentWorkflow({
					id: null,
					name: 'Untitled Workflow',
					description: '',
					nodes: [],
					connections: [],
					variables: {},
					settings: {
						timezone: 'UTC',
						saveDataErrorExecution: 'all',
						saveDataSuccessExecution: 'all'
					},
					tags: []
				});
			}

			// Create the workflow editor interface
			const editorDiv = document.createElement('div');
			editorDiv.className = 'nst-workflow-editor';
			editorDiv.innerHTML = createEditorHTML();

			workflowContainer.appendChild(editorDiv);

			// Add event listeners
			addEventListeners();

			isLoading = false;
		} catch (err) {
			console.error('Failed to initialize workflow editor:', err);
			error = 'Failed to load NST-AI Workflow editor. Please try again.';
			isLoading = false;
		}
	};

	const createEditorHTML = () => `
		<div class="nst-workflow-layout">
			<!-- Header -->
			<div class="nst-workflow-header">
				<div class="nst-workflow-title">
					<div class="flex items-center gap-3">
						<img src="/static/nst-ai.png" alt="NST-AI" class="w-8 h-8 rounded-lg" />
						<div>
							<h2>${$currentWorkflow?.name || 'Untitled Workflow'}</h2>
							<p>NST-AI Workflow Builder</p>
						</div>
					</div>
				</div>
				<div class="nst-workflow-actions">
					<button class="nst-btn-secondary" id="import-workflow">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
							<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
							<polyline points="14,2 14,8 20,8"/>
						</svg>
						Import
					</button>
					<button class="nst-btn-secondary" id="export-workflow">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
							<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
							<polyline points="14,2 14,8 20,8"/>
						</svg>
						Export
					</button>
					<button class="nst-btn-primary" id="save-workflow">
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
							<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
							<polyline points="17,21 17,13 7,13 7,21"/>
							<polyline points="7,3 7,8 15,8"/>
						</svg>
						Save
					</button>
					<button class="nst-btn-success" id="run-workflow" ${!$currentWorkflow?.nodes.length ? 'disabled' : ''}>
						<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
							<polygon points="5,3 19,12 5,21"/>
						</svg>
						${$isExecuting ? 'Running...' : 'Run'}
					</button>
				</div>
			</div>

			<!-- Main Content -->
			<div class="nst-workflow-content">
				<!-- Node Palette -->
				<div class="nst-node-palette">
					<div class="nst-palette-header">
						<h3>Node Library</h3>
						<p>Drag nodes to the canvas</p>
					</div>
					<div class="nst-node-categories">
						${nodeCategories.map(category => `
							<div class="nst-category">
								<div class="nst-category-header">
									<span class="nst-category-icon">${category.icon}</span>
									<h4>${category.name}</h4>
								</div>
								<div class="nst-category-nodes">
									${category.nodes.map(node => `
										<div class="nst-node-item" 
											 data-node-type="${node.type}" 
											 draggable="true"
											 title="${node.description}">
											<span class="nst-node-icon">${node.icon}</span>
											<span class="nst-node-name">${node.name}</span>
										</div>
									`).join('')}
								</div>
							</div>
						`).join('')}
					</div>
				</div>

				<!-- Canvas -->
				<div class="nst-workflow-canvas" id="nst-canvas">
					<div class="nst-canvas-background">
						<div class="nst-canvas-dots"></div>
					</div>
					${$currentWorkflow?.nodes.length === 0 ? `
						<div class="nst-canvas-welcome">
							<div class="nst-welcome-content">
								<div class="nst-welcome-icon">
									<img src="/static/nst-ai.png" alt="NST-AI" style="width: 80px; height: 80px; border-radius: 16px;" />
								</div>
								<h3>Welcome to NST-AI Workflow</h3>
								<p>Start building your automation workflow by dragging nodes from the left panel onto this canvas.</p>
								<div class="nst-quick-start">
									<button class="nst-quick-action" id="add-chat-node">
										💬 Add Chat Node
									</button>
									<button class="nst-quick-action" id="load-template">
										📋 Load Template
									</button>
								</div>
							</div>
						</div>
					` : `
						<div class="nst-canvas-nodes" id="nst-canvas-nodes">
							<!-- Workflow nodes will be rendered here -->
						</div>
					`}
				</div>

				<!-- Properties Panel -->
				<div class="nst-properties-panel">
					<div class="nst-properties-header">
						<h3>Properties</h3>
						<p>Configure selected node</p>
					</div>
					<div class="nst-properties-content" id="nst-properties-content">
						<div class="nst-no-selection">
							<div class="nst-no-selection-icon">⚙️</div>
							<p>Select a node to edit its properties</p>
						</div>
					</div>
				</div>
			</div>

			<!-- Status Bar -->
			<div class="nst-workflow-status">
				<div class="nst-status-left">
					<span class="nst-status-item">
						<span class="nst-status-label">Nodes:</span>
						<span class="nst-status-value">${$currentWorkflow?.nodes.length || 0}</span>
					</span>
					<span class="nst-status-item">
						<span class="nst-status-label">Connections:</span>
						<span class="nst-status-value">${$currentWorkflow?.connections.length || 0}</span>
					</span>
				</div>
				<div class="nst-status-right">
					<span class="nst-status-item">
						<span class="nst-status-indicator nst-status-ready"></span>
						<span class="nst-status-text">Ready</span>
					</span>
				</div>
			</div>
		</div>
	`;

	const addEventListeners = () => {
		// Node drag and drop
		const nodeItems = document.querySelectorAll('.nst-node-item');
		nodeItems.forEach(item => {
			item.addEventListener('dragstart', handleNodeDragStart);
			item.addEventListener('dragend', handleNodeDragEnd);
		});

		// Canvas drop handling
		const canvas = document.getElementById('nst-canvas');
		if (canvas) {
			canvas.addEventListener('dragover', handleCanvasDragOver);
			canvas.addEventListener('drop', handleCanvasDrop);
		}

		// Action buttons
		document.getElementById('save-workflow')?.addEventListener('click', handleSaveWorkflow);
		document.getElementById('run-workflow')?.addEventListener('click', handleRunWorkflow);
		document.getElementById('import-workflow')?.addEventListener('click', handleImportWorkflow);
		document.getElementById('export-workflow')?.addEventListener('click', handleExportWorkflow);
		document.getElementById('add-chat-node')?.addEventListener('click', () => handleAddQuickNode('nst-chat'));
		document.getElementById('load-template')?.addEventListener('click', handleLoadTemplate);
	};

	const handleNodeDragStart = (e: DragEvent) => {
		const target = e.target as HTMLElement;
		const nodeType = target.getAttribute('data-node-type');
		if (nodeType) {
			draggedNodeType = nodeType;
			isDragging = true;
			e.dataTransfer?.setData('text/plain', nodeType);
			target.classList.add('nst-dragging');
		}
	};

	const handleNodeDragEnd = (e: DragEvent) => {
		const target = e.target as HTMLElement;
		target.classList.remove('nst-dragging');
		isDragging = false;
		draggedNodeType = null;
	};

	const handleCanvasDragOver = (e: DragEvent) => {
		e.preventDefault();
		e.dataTransfer!.dropEffect = 'copy';
	};

	const handleCanvasDrop = (e: DragEvent) => {
		e.preventDefault();
		const nodeType = e.dataTransfer?.getData('text/plain');
		if (nodeType) {
			const rect = (e.target as HTMLElement).getBoundingClientRect();
			const x = e.clientX - rect.left;
			const y = e.clientY - rect.top;
			addNodeToCanvas(nodeType, x, y);
		}
	};

	const addNodeToCanvas = (nodeType: string, x: number, y: number) => {
		const nodeConfig = nodeCategories
			.flatMap(cat => cat.nodes)
			.find(node => node.type === nodeType);
		
		if (nodeConfig) {
			const newNode: WorkflowNode = {
				id: `${nodeType}_${Date.now()}`,
				type: nodeType,
				position: { x: Math.max(0, x - 75), y: Math.max(0, y - 25) },
				data: {
					label: nodeConfig.name,
					icon: nodeConfig.icon,
					description: nodeConfig.description
				}
			};

			workflowActions.addNode(newNode);
			renderNodes();
		}
	};

	const handleAddQuickNode = (nodeType: string) => {
		addNodeToCanvas(nodeType, 200, 150);
	};

	const renderNodes = () => {
		const nodesContainer = document.getElementById('nst-canvas-nodes');
		const welcomeContainer = document.querySelector('.nst-canvas-welcome');
		
		if (!nodesContainer || !$currentWorkflow) return;

		// Hide welcome screen if we have nodes
		if ($currentWorkflow.nodes.length > 0 && welcomeContainer) {
			welcomeContainer.style.display = 'none';
		}

		// Render nodes
		nodesContainer.innerHTML = $currentWorkflow.nodes.map(node => `
			<div class="nst-canvas-node" 
				 style="left: ${node.position.x}px; top: ${node.position.y}px;"
				 data-node-id="${node.id}">
				<div class="nst-node-header">
					<span class="nst-node-icon">${node.data.icon}</span>
					<span class="nst-node-label">${node.data.label}</span>
					<button class="nst-node-delete" data-node-id="${node.id}">×</button>
				</div>
				<div class="nst-node-content">
					<div class="nst-node-input"></div>
					<div class="nst-node-output"></div>
				</div>
			</div>
		`).join('');

		// Add node event listeners
		nodesContainer.querySelectorAll('.nst-node-delete').forEach(btn => {
			btn.addEventListener('click', (e) => {
				const nodeId = (e.target as HTMLElement).getAttribute('data-node-id');
				if (nodeId) {
					workflowActions.removeNode(nodeId);
					renderNodes();
				}
			});
		});

		nodesContainer.querySelectorAll('.nst-canvas-node').forEach(node => {
			node.addEventListener('click', (e) => {
				const nodeId = (e.currentTarget as HTMLElement).getAttribute('data-node-id');
				if (nodeId) {
					workflowActions.selectNode(nodeId);
					updatePropertiesPanel(nodeId);
				}
			});
		});
	};

	const updatePropertiesPanel = (nodeId: string) => {
		const propertiesContent = document.getElementById('nst-properties-content');
		if (!propertiesContent || !$currentWorkflow) return;

		const node = $currentWorkflow.nodes.find(n => n.id === nodeId);
		if (node) {
			propertiesContent.innerHTML = `
				<div class="nst-property-form">
					<div class="nst-property-group">
						<label>Node Name</label>
						<input type="text" value="${node.data.label}" id="node-name-input" />
					</div>
					<div class="nst-property-group">
						<label>Description</label>
						<textarea rows="3" id="node-description-input">${node.data.description || ''}</textarea>
					</div>
					<div class="nst-property-group">
						<label>Type</label>
						<input type="text" value="${node.type}" readonly />
					</div>
				</div>
			`;

			// Add property update listeners
			const nameInput = document.getElementById('node-name-input') as HTMLInputElement;
			const descInput = document.getElementById('node-description-input') as HTMLTextAreaElement;

			nameInput?.addEventListener('input', (e) => {
				workflowActions.updateNode(nodeId, {
					data: { ...node.data, label: (e.target as HTMLInputElement).value }
				});
				renderNodes();
			});

			descInput?.addEventListener('input', (e) => {
				workflowActions.updateNode(nodeId, {
					data: { ...node.data, description: (e.target as HTMLTextAreaElement).value }
				});
			});
		}
	};

	const handleSaveWorkflow = async () => {
		if ($currentWorkflow) {
			try {
				const saved = await workflowService.createWorkflow(localStorage.token, $currentWorkflow);
				workflowActions.setCurrentWorkflow(saved);
				console.log('Workflow saved successfully');
			} catch (error) {
				console.error('Failed to save workflow:', error);
			}
		}
	};

	const handleRunWorkflow = async () => {
		if ($currentWorkflow && $currentWorkflow.id) {
			try {
				workflowActions.startExecution();
				const execution = await workflowService.executeWorkflow(localStorage.token, $currentWorkflow.id);
				console.log('Workflow execution started:', execution);
				// You could poll for execution status here
				setTimeout(() => {
					workflowActions.stopExecution();
				}, 3000);
			} catch (error) {
				console.error('Failed to run workflow:', error);
				workflowActions.stopExecution();
			}
		}
	};

	const handleImportWorkflow = () => {
		const input = document.createElement('input');
		input.type = 'file';
		input.accept = '.json';
		input.onchange = async (e) => {
			const file = (e.target as HTMLInputElement).files?.[0];
			if (file) {
				const text = await file.text();
				try {
					const workflowData = JSON.parse(text);
					workflowActions.setCurrentWorkflow(workflowData);
					renderNodes();
				} catch (error) {
					console.error('Failed to import workflow:', error);
				}
			}
		};
		input.click();
	};

	const handleExportWorkflow = () => {
		if ($currentWorkflow) {
			const blob = new Blob([JSON.stringify($currentWorkflow, null, 2)], { type: 'application/json' });
			const url = URL.createObjectURL(blob);
			const a = document.createElement('a');
			a.href = url;
			a.download = `${$currentWorkflow.name || 'workflow'}.json`;
			a.click();
			URL.revokeObjectURL(url);
		}
	};

	const handleLoadTemplate = () => {
		// Load a sample template
		const templateWorkflow = {
			id: null,
			name: 'Sample Chat Workflow',
			description: 'A sample workflow that processes chat messages',
			nodes: [
				{
					id: 'trigger_1',
					type: 'nst-chat',
					position: { x: 100, y: 100 },
					data: { label: 'Chat Input', icon: '💬', description: 'Receive chat messages' }
				},
				{
					id: 'process_1',
					type: 'nst-model',
					position: { x: 350, y: 100 },
					data: { label: 'AI Model', icon: '🤖', description: 'Process with AI' }
				},
				{
					id: 'output_1',
					type: 'data-output',
					position: { x: 600, y: 100 },
					data: { label: 'Output', icon: '📤', description: 'Send response' }
				}
			],
			connections: [
				{ id: 'conn_1', source: 'trigger_1', target: 'process_1' },
				{ id: 'conn_2', source: 'process_1', target: 'output_1' }
			],
			variables: {},
			settings: {
				timezone: 'UTC',
				saveDataErrorExecution: 'all',
				saveDataSuccessExecution: 'all'
			},
			tags: ['template', 'chat']
		};

		workflowActions.setCurrentWorkflow(templateWorkflow);
		renderNodes();
	};

	// Subscribe to workflow changes to update the UI
	$: if ($currentWorkflow && browser) {
		renderNodes();
	}
</script>

<div class="nst-workflow-container" bind:this={workflowContainer}>
	{#if isLoading}
		<div class="nst-loading-container">
			<div class="nst-loading-spinner"></div>
			<p>Loading NST-AI Workflow Editor...</p>
		</div>
	{/if}

	{#if error}
		<div class="nst-error-container">
			<div class="nst-error-icon">⚠️</div>
			<h3>Error Loading Workflow Editor</h3>
			<p>{error}</p>
			<button class="nst-retry-button" on:click={initializeWorkflowEditor}>
				Retry
			</button>
		</div>
	{/if}
</div>

<style>
	.nst-workflow-container {
		width: 100%;
		height: 100%;
		position: relative;
		background: #f8fafc;
		border-radius: 8px;
		overflow: hidden;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}

	.nst-loading-container, .nst-error-container {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100%;
		gap: 16px;
		padding: 32px;
		text-align: center;
	}

	.nst-loading-spinner {
		width: 32px;
		height: 32px;
		border: 3px solid #e2e8f0;
		border-top: 3px solid #3b82f6;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	.nst-error-icon {
		font-size: 48px;
	}

	.nst-retry-button {
		padding: 12px 24px;
		background: #3b82f6;
		color: white;
		border: none;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 500;
		transition: background-color 0.2s;
	}

	.nst-retry-button:hover {
		background: #2563eb;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	/* Main Layout */
	:global(.nst-workflow-layout) {
		display: flex;
		flex-direction: column;
		height: 100%;
		background: white;
		border-radius: 8px;
		overflow: hidden;
	}

	:global(.nst-workflow-header) {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 16px 24px;
		background: linear-gradient(90deg, #f8fafc 0%, #e2e8f0 100%);
		border-bottom: 1px solid #e2e8f0;
		min-height: 80px;
	}

	:global(.nst-workflow-title) {
		display: flex;
		align-items: center;
		gap: 12px;
	}

	:global(.nst-workflow-title h2) {
		margin: 0;
		font-size: 24px;
		font-weight: 700;
		color: #1f2937;
		background: linear-gradient(135deg, #3b82f6, #6366f1);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	:global(.nst-workflow-title p) {
		margin: 4px 0 0 0;
		font-size: 14px;
		color: #6b7280;
		font-weight: 500;
	}

	:global(.nst-workflow-actions) {
		display: flex;
		gap: 12px;
		align-items: center;
	}

	:global(.nst-btn-primary), :global(.nst-btn-secondary), :global(.nst-btn-success) {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 10px 16px;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		font-size: 14px;
		cursor: pointer;
		transition: all 0.2s;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
	}

	:global(.nst-btn-primary) {
		background: linear-gradient(135deg, #3b82f6, #2563eb);
		color: white;
	}

	:global(.nst-btn-primary:hover) {
		background: linear-gradient(135deg, #2563eb, #1d4ed8);
		transform: translateY(-1px);
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
	}

	:global(.nst-btn-secondary) {
		background: white;
		color: #374151;
		border: 1px solid #d1d5db;
	}

	:global(.nst-btn-secondary:hover) {
		background: #f9fafb;
		border-color: #9ca3af;
		transform: translateY(-1px);
	}

	:global(.nst-btn-success) {
		background: linear-gradient(135deg, #10b981, #059669);
		color: white;
	}

	:global(.nst-btn-success:hover) {
		background: linear-gradient(135deg, #059669, #047857);
		transform: translateY(-1px);
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
	}

	:global(.nst-btn-success:disabled) {
		background: #9ca3af;
		cursor: not-allowed;
		transform: none;
		box-shadow: none;
	}

	/* Content Layout */
	:global(.nst-workflow-content) {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	/* Node Palette */
	:global(.nst-node-palette) {
		width: 280px;
		background: #f8fafc;
		border-right: 1px solid #e2e8f0;
		overflow-y: auto;
		padding: 16px;
	}

	:global(.nst-palette-header h3) {
		margin: 0 0 4px 0;
		font-size: 18px;
		font-weight: 600;
		color: #1f2937;
	}

	:global(.nst-palette-header p) {
		margin: 0 0 20px 0;
		font-size: 13px;
		color: #6b7280;
	}

	:global(.nst-node-categories) {
		display: flex;
		flex-direction: column;
		gap: 24px;
	}

	:global(.nst-category-header) {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-bottom: 12px;
	}

	:global(.nst-category-icon) {
		font-size: 16px;
	}

	:global(.nst-category-header h4) {
		margin: 0;
		font-size: 14px;
		font-weight: 600;
		color: #374151;
		text-transform: uppercase;
		letter-spacing: 0.5px;
	}

	:global(.nst-category-nodes) {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	:global(.nst-node-item) {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 12px;
		background: white;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		cursor: grab;
		transition: all 0.2s;
		font-size: 14px;
		font-weight: 500;
		box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
	}

	:global(.nst-node-item:hover) {
		background: #f0f9ff;
		border-color: #3b82f6;
		transform: translateY(-1px);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	:global(.nst-node-item:active), :global(.nst-node-item.nst-dragging) {
		cursor: grabbing;
		transform: scale(0.98);
	}

	:global(.nst-node-icon) {
		font-size: 16px;
		flex-shrink: 0;
	}

	:global(.nst-node-name) {
		flex: 1;
		color: #374151;
	}

	/* Canvas */
	:global(.nst-workflow-canvas) {
		flex: 1;
		position: relative;
		background: #ffffff;
		overflow: auto;
	}

	:global(.nst-canvas-background) {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background-image: radial-gradient(circle, #e2e8f0 1px, transparent 1px);
		background-size: 20px 20px;
		opacity: 0.5;
	}

	:global(.nst-canvas-welcome) {
		display: flex;
		align-items: center;
		justify-content: center;
		height: 100%;
		padding: 32px;
		position: relative;
		z-index: 1;
	}

	:global(.nst-welcome-content) {
		text-align: center;
		max-width: 500px;
	}

	:global(.nst-welcome-icon) {
		margin-bottom: 24px;
	}

	:global(.nst-welcome-content h3) {
		margin: 0 0 12px 0;
		font-size: 28px;
		font-weight: 700;
		color: #1f2937;
		background: linear-gradient(135deg, #3b82f6, #6366f1);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	:global(.nst-welcome-content p) {
		margin: 0 0 32px 0;
		color: #6b7280;
		line-height: 1.6;
		font-size: 16px;
	}

	:global(.nst-quick-start) {
		display: flex;
		gap: 16px;
		justify-content: center;
		flex-wrap: wrap;
	}

	:global(.nst-quick-action) {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 14px 20px;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		color: #374151;
		text-decoration: none;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-size: 14px;
	}

	:global(.nst-quick-action:hover) {
		background: #f0f9ff;
		border-color: #3b82f6;
		color: #3b82f6;
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
	}

	/* Canvas Nodes */
	:global(.nst-canvas-nodes) {
		position: relative;
		width: 100%;
		height: 100%;
		z-index: 2;
	}

	:global(.nst-canvas-node) {
		position: absolute;
		width: 180px;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.07);
		cursor: pointer;
		transition: all 0.2s;
		z-index: 10;
	}

	:global(.nst-canvas-node:hover) {
		border-color: #3b82f6;
		box-shadow: 0 8px 25px rgba(59, 130, 246, 0.15);
		transform: translateY(-2px);
	}

	:global(.nst-node-header) {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 12px 16px;
		background: linear-gradient(135deg, #f8fafc, #e2e8f0);
		border-bottom: 1px solid #e2e8f0;
		border-radius: 10px 10px 0 0;
		position: relative;
	}

	:global(.nst-node-header .nst-node-icon) {
		font-size: 18px;
	}

	:global(.nst-node-label) {
		flex: 1;
		font-weight: 600;
		color: #1f2937;
		font-size: 14px;
	}

	:global(.nst-node-delete) {
		position: absolute;
		top: 4px;
		right: 4px;
		width: 20px;
		height: 20px;
		border: none;
		background: #ef4444;
		color: white;
		border-radius: 50%;
		cursor: pointer;
		font-size: 12px;
		font-weight: bold;
		opacity: 0;
		transition: opacity 0.2s;
	}

	:global(.nst-canvas-node:hover .nst-node-delete) {
		opacity: 1;
	}

	:global(.nst-node-content) {
		padding: 16px;
		display: flex;
		justify-content: space-between;
		align-items: center;
		min-height: 40px;
	}

	:global(.nst-node-input), :global(.nst-node-output) {
		width: 12px;
		height: 12px;
		border: 2px solid #6b7280;
		border-radius: 50%;
		background: white;
		cursor: pointer;
		transition: all 0.2s;
	}

	:global(.nst-node-input:hover), :global(.nst-node-output:hover) {
		border-color: #3b82f6;
		background: #3b82f6;
		transform: scale(1.2);
	}

	/* Properties Panel */
	:global(.nst-properties-panel) {
		width: 300px;
		background: #f8fafc;
		border-left: 1px solid #e2e8f0;
		padding: 16px;
		overflow-y: auto;
	}

	:global(.nst-properties-header h3) {
		margin: 0 0 4px 0;
		font-size: 18px;
		font-weight: 600;
		color: #1f2937;
	}

	:global(.nst-properties-header p) {
		margin: 0 0 20px 0;
		font-size: 13px;
		color: #6b7280;
	}

	:global(.nst-no-selection) {
		text-align: center;
		padding: 40px 20px;
		color: #9ca3af;
	}

	:global(.nst-no-selection-icon) {
		font-size: 48px;
		margin-bottom: 16px;
		opacity: 0.5;
	}

	:global(.nst-property-form) {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	:global(.nst-property-group) {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	:global(.nst-property-group label) {
		font-size: 13px;
		font-weight: 600;
		color: #374151;
		text-transform: uppercase;
		letter-spacing: 0.5px;
	}

	:global(.nst-property-group input), :global(.nst-property-group textarea) {
		padding: 10px 12px;
		border: 1px solid #d1d5db;
		border-radius: 6px;
		font-size: 14px;
		background: white;
		transition: border-color 0.2s;
	}

	:global(.nst-property-group input:focus), :global(.nst-property-group textarea:focus) {
		outline: none;
		border-color: #3b82f6;
		box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
	}

	:global(.nst-property-group input[readonly]) {
		background: #f9fafb;
		color: #6b7280;
	}

	/* Status Bar */
	:global(.nst-workflow-status) {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 8px 24px;
		background: #f8fafc;
		border-top: 1px solid #e2e8f0;
		font-size: 12px;
		min-height: 40px;
	}

	:global(.nst-status-left), :global(.nst-status-right) {
		display: flex;
		gap: 16px;
		align-items: center;
	}

	:global(.nst-status-item) {
		display: flex;
		align-items: center;
		gap: 4px;
	}

	:global(.nst-status-label) {
		color: #6b7280;
		font-weight: 500;
	}

	:global(.nst-status-value) {
		color: #1f2937;
		font-weight: 600;
	}

	:global(.nst-status-indicator) {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		margin-right: 4px;
	}

	:global(.nst-status-ready) {
		background: #10b981;
	}

	:global(.nst-status-text) {
		color: #374151;
		font-weight: 500;
	}

	/* Responsive Design */
	@media (max-width: 1024px) {
		:global(.nst-node-palette) {
			width: 240px;
		}

		:global(.nst-properties-panel) {
			width: 260px;
		}
	}

	@media (max-width: 768px) {
		:global(.nst-workflow-content) {
			flex-direction: column;
		}

		:global(.nst-node-palette), :global(.nst-properties-panel) {
			width: 100%;
			height: 200px;
		}

		:global(.nst-workflow-canvas) {
			height: 400px;
		}

		:global(.nst-workflow-header) {
			flex-direction: column;
			gap: 16px;
			padding: 16px;
		}

		:global(.nst-workflow-actions) {
			width: 100%;
			justify-content: center;
		}
	}
</style>
