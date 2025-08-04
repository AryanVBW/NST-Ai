<script lang="ts">
	import { onMount } from 'svelte';
	import { user } from '$lib/stores';
	import { toast } from 'svelte-sonner';
	import { goto } from '$app/navigation';

	// Status monitoring variables
	let workflowStatus: any = null;
	let isLoading = true;
	let workflowUrl = '';
	let serverLog = '';
	let refreshInterval: NodeJS.Timeout | null = null;

	onMount(async () => {
		// Check if user has permission to access workflow management
		if ($user?.role !== 'admin') {
			toast.error('Access denied. Admin privileges required.');
			goto('/');
			return;
		}

		await checkWorkflowStatus();
		
		// Set up auto-refresh every 5 seconds
		refreshInterval = setInterval(checkWorkflowStatus, 5000);
		
		return () => {
			if (refreshInterval) {
				clearInterval(refreshInterval);
			}
		};
	});

	const checkWorkflowStatus = async () => {
		try {
			const response = await fetch('/api/v1/workflows/status', {
				method: 'GET',
				headers: {
					'Authorization': `Bearer ${localStorage.token}`,
					'Content-Type': 'application/json'
				}
			});

			if (response.ok) {
				workflowStatus = await response.json();
				if (workflowStatus?.url) {
					workflowUrl = workflowStatus.url;
				}
			} else {
				workflowStatus = { status: 'error', message: 'Failed to get status' };
			}
		} catch (e: any) {
			console.error('Failed to get workflow status:', e);
			workflowStatus = { status: 'error', message: e.message };
		} finally {
			isLoading = false;
		}
	};

	const startWorkflowServer = async () => {
		try {
			isLoading = true;
			const response = await fetch('/api/v1/workflows/start', {
				method: 'POST',
				headers: {
					'Authorization': `Bearer ${localStorage.token}`,
					'Content-Type': 'application/json'
				}
			});

			if (response.ok) {
				toast.success('Workflow server started successfully!');
				serverLog += `\n[${new Date().toLocaleTimeString()}] Server started successfully`;
				await checkWorkflowStatus();
			} else {
				throw new Error('Failed to start server');
			}
		} catch (e: any) {
			const error = `Failed to start workflow server: ${e.message}`;
			serverLog += `\n[${new Date().toLocaleTimeString()}] Error: ${e.message}`;
			toast.error(error);
		} finally {
			isLoading = false;
		}
	};

	const stopWorkflowServer = async () => {
		try {
			isLoading = true;
			const response = await fetch('/api/v1/workflows/stop', {
				method: 'POST',
				headers: {
					'Authorization': `Bearer ${localStorage.token}`,
					'Content-Type': 'application/json'
				}
			});

			if (response.ok) {
				toast.success('Workflow server stopped');
				serverLog += `\n[${new Date().toLocaleTimeString()}] Server stopped`;
				await checkWorkflowStatus();
			} else {
				throw new Error('Failed to stop server');
			}
		} catch (e: any) {
			toast.error(`Failed to stop workflow server: ${e.message}`);
			serverLog += `\n[${new Date().toLocaleTimeString()}] Stop error: ${e.message}`;
		} finally {
			isLoading = false;
		}
	};

	const restartWorkflowServer = async () => {
		try {
			isLoading = true;
			serverLog += `\n[${new Date().toLocaleTimeString()}] Restarting server...`;
			await stopWorkflowServer();
			setTimeout(async () => {
				await startWorkflowServer();
			}, 2000);
		} catch (e: any) {
			toast.error(`Failed to restart workflow server: ${e.message}`);
		}
	};

	const openWorkflowEditor = () => {
		if (workflowUrl) {
			window.open(workflowUrl, '_blank');
		} else {
			goto('/workflow');
		}
	};

	const clearLog = () => {
		serverLog = '';
	};
</script>

<svelte:head>
	<title>Workflow Management | NST AI</title>
	<meta name="description" content="Manage NST-AI Workflow Server" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<div class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center py-6">
				<div>
					<h1 class="text-3xl font-bold text-gray-900 dark:text-white">
						NST-AI Workflow Management
					</h1>
					<p class="mt-2 text-gray-600 dark:text-gray-400">
						Control and monitor your workflow automation server
					</p>
				</div>
				<div class="flex items-center space-x-4">
					<button
						on:click={checkWorkflowStatus}
						class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
						disabled={isLoading}
					>
						<svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
						</svg>
						Refresh
					</button>
				</div>
			</div>
		</div>
	</div>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
			<!-- Server Status Card -->
			<div class="lg:col-span-1">
				<div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
					<div class="flex items-center justify-between mb-4">
						<h2 class="text-lg font-semibold text-gray-900 dark:text-white">Server Status</h2>
						<div class="flex items-center space-x-2">
							<div class="w-3 h-3 rounded-full {workflowStatus?.status === 'running' ? 'bg-green-500' : workflowStatus?.status === 'error' ? 'bg-red-500' : 'bg-gray-400'}"></div>
							<span class="text-sm text-gray-600 dark:text-gray-400 capitalize">
								{workflowStatus?.status || 'Unknown'}
							</span>
						</div>
					</div>

					{#if isLoading}
						<div class="flex items-center justify-center py-4">
							<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
						</div>
					{:else if workflowStatus}
						<div class="space-y-3">
							{#if workflowStatus.status === 'running'}
								<div class="space-y-2 text-sm">
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Process ID:</span>
										<span class="font-mono text-gray-900 dark:text-white">{workflowStatus.process_id}</span>
									</div>
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Port:</span>
										<span class="font-mono text-gray-900 dark:text-white">{workflowStatus.port}</span>
									</div>
									{#if workflowStatus.uptime}
										<div class="flex justify-between">
											<span class="text-gray-600 dark:text-gray-400">Uptime:</span>
											<span class="font-mono text-gray-900 dark:text-white">{workflowStatus.uptime}</span>
										</div>
									{/if}
									{#if workflowStatus.url}
										<div class="flex justify-between">
											<span class="text-gray-600 dark:text-gray-400">URL:</span>
											<a href={workflowStatus.url} target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline font-mono text-xs">
												{workflowStatus.url}
											</a>
										</div>
									{/if}
								</div>
							{:else if workflowStatus.status === 'error'}
								<div class="text-red-600 dark:text-red-400 text-sm">
									{workflowStatus.message || 'Server error occurred'}
								</div>
							{:else}
								<div class="text-gray-600 dark:text-gray-400 text-sm">
									Workflow server is not running
								</div>
							{/if}
						</div>
					{/if}

					<!-- Control Buttons -->
					<div class="mt-6 space-y-2">
						{#if workflowStatus?.status === 'running'}
							<button
								on:click={openWorkflowEditor}
								class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium"
							>
								Open Workflow Editor
							</button>
							<button
								on:click={stopWorkflowServer}
								class="w-full px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors font-medium"
								disabled={isLoading}
							>
								Stop Server
							</button>
							<button
								on:click={restartWorkflowServer}
								class="w-full px-4 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700 transition-colors font-medium"
								disabled={isLoading}
							>
								Restart Server
							</button>
						{:else}
							<button
								on:click={startWorkflowServer}
								class="w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors font-medium"
								disabled={isLoading}
							>
								Start Server
							</button>
						{/if}
					</div>
				</div>

				<!-- Quick Actions Card -->
				<div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6 mt-6">
					<h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
					<div class="space-y-2">
						<a
							href="/workflow"
							class="block w-full px-4 py-2 text-center bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
						>
							Go to Workflow Page
						</a>
						<a
							href="/admin/settings/general"
							class="block w-full px-4 py-2 text-center bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
						>
							Admin Settings
						</a>
					</div>
				</div>
			</div>

			<!-- Main Content Area -->
			<div class="lg:col-span-2">
				<!-- Server Log -->
				<div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6 mb-6">
					<div class="flex items-center justify-between mb-4">
						<h2 class="text-lg font-semibold text-gray-900 dark:text-white">Server Log</h2>
						<button
							on:click={clearLog}
							class="px-3 py-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
						>
							Clear Log
						</button>
					</div>
					<div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 h-64 overflow-y-auto">
						<pre class="text-xs text-gray-700 dark:text-gray-300 font-mono whitespace-pre-wrap">{serverLog || 'No log entries yet...'}</pre>
					</div>
				</div>

				<!-- Workflow Information -->
				<div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
					<h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">About NST-AI Workflow</h2>
					<div class="prose dark:prose-invert max-w-none">
						<p class="text-gray-600 dark:text-gray-400">
							The NST-AI Workflow system provides powerful automation capabilities using n8n workflow engine. 
							Create, manage, and execute complex workflows to automate your tasks and integrate with various services.
						</p>
						
						<div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
							<div>
								<h3 class="text-md font-semibold text-gray-900 dark:text-white mb-2">Features</h3>
								<ul class="text-sm text-gray-600 dark:text-gray-400 space-y-1">
									<li>• Visual workflow editor</li>
									<li>• 200+ integrations</li>
									<li>• Conditional logic</li>
									<li>• Scheduled execution</li>
									<li>• Error handling</li>
									<li>• Data transformation</li>
								</ul>
							</div>
							<div>
								<h3 class="text-md font-semibold text-gray-900 dark:text-white mb-2">Use Cases</h3>
								<ul class="text-sm text-gray-600 dark:text-gray-400 space-y-1">
									<li>• Data synchronization</li>
									<li>• API integrations</li>
									<li>• Automated notifications</li>
									<li>• File processing</li>
									<li>• Database operations</li>
									<li>• Custom automations</li>
								</ul>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<style>
	:global(body) {
		background-color: rgb(249 250 251);
	}
	:global(.dark body) {
		background-color: rgb(17 24 39);
	}
</style>
