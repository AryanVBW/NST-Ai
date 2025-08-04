<script lang="ts">
	import { onMount } from 'svelte';
	import { user, config } from '$lib/stores';
	import { workflowService } from '$lib/apis/workflows';
	import { toast } from 'svelte-sonner';

	let workflowStatus = null;
	let isLoading = true;
	let error = null;
	let workflowUrl = '';

	onMount(async () => {
		await checkWorkflowStatus();
		
		// Auto-start workflow if it's not running and auto-start is enabled
		if (workflowStatus?.status !== 'running') {
			try {
				await startWorkflowServer();
			} catch (e) {
				console.error('Failed to auto-start workflow:', e);
			}
		}
	});

	const checkWorkflowStatus = async () => {
		try {
			workflowStatus = await workflowService.getWorkflowStatus(localStorage.token);
			if (workflowStatus?.url) {
				workflowUrl = workflowStatus.url;
			}
		} catch (e) {
			console.error('Failed to get workflow status:', e);
			workflowStatus = { status: 'error' };
		} finally {
			isLoading = false;
		}
	};

	const startWorkflowServer = async () => {
		try {
			await workflowService.startWorkflowServer(localStorage.token);
			toast.success('Workflow server started successfully!');
			await checkWorkflowStatus();
		} catch (e) {
			error = `Failed to start workflow server: ${e.message}`;
			toast.error(error);
		}
	};

	const stopWorkflowServer = async () => {
		try {
			await workflowService.stopWorkflowServer(localStorage.token);
			toast.success('Workflow server stopped');
			await checkWorkflowStatus();
		} catch (e) {
			toast.error(`Failed to stop workflow server: ${e.message}`);
		}
	};
</script>

<svelte:head>
	<title>NST-AI Workflow | NST AI</title>
	<meta name="description" content="Build and automate powerful workflows with NST-AI" />
</svelte:head>

<div class="min-h-screen max-h-screen bg-white dark:bg-gray-900 flex flex-col">
	<div class="flex-1 overflow-hidden">
		{#if isLoading}
			<div class="flex items-center justify-center h-full">
				<div class="text-center">
					<div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 dark:border-white mb-4"></div>
					<p class="text-gray-600 dark:text-gray-400">Loading NST-AI Workflow...</p>
				</div>
			</div>
		{:else if error}
			<div class="flex items-center justify-center h-full">
				<div class="text-center max-w-md mx-auto p-6">
					<div class="text-red-500 mb-4">
						<svg class="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.664-.833-2.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
						</svg>
					</div>
					<h2 class="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-2">Workflow Server Error</h2>
					<p class="text-gray-600 dark:text-gray-400 mb-4">{error}</p>
					<button 
						class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
						on:click={startWorkflowServer}
					>
						Retry Start Server
					</button>
				</div>
			</div>
		{:else if workflowStatus?.status === 'running' && workflowUrl}
			<div class="flex flex-col h-full">
				<div class="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-2 flex items-center justify-between">
					<div class="flex items-center space-x-3">
						<div class="flex items-center space-x-2">
							<div class="w-2 h-2 bg-green-500 rounded-full"></div>
							<span class="text-sm font-medium text-gray-700 dark:text-gray-300">NST-AI Workflow Server</span>
						</div>
						<span class="text-xs text-gray-500 dark:text-gray-400">Running on {workflowUrl}</span>
					</div>
					<button 
						class="px-3 py-1 text-xs bg-red-100 hover:bg-red-200 text-red-700 rounded transition-colors"
						on:click={stopWorkflowServer}
					>
						Stop Server
					</button>
				</div>
				<iframe 
					src={workflowUrl}
					class="flex-1 w-full border-0"
					title="NST-AI Workflow Editor"
					allow="clipboard-read; clipboard-write"
				></iframe>
			</div>
		{:else}
			<div class="flex items-center justify-center h-full">
				<div class="text-center max-w-md mx-auto p-6">
					<div class="text-blue-500 mb-4">
						<svg class="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
						</svg>
					</div>
					<h2 class="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-2">NST-AI Workflow</h2>
					<p class="text-gray-600 dark:text-gray-400 mb-4">
						The workflow server is not running. Start it to access the powerful workflow editor.
					</p>
					<div class="space-y-2">
						<button 
							class="w-full px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
							on:click={startWorkflowServer}
						>
							Start Workflow Server
						</button>
						<button 
							class="w-full px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
							on:click={checkWorkflowStatus}
						>
							Refresh Status
						</button>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) {
		overflow: hidden;
	}
</style>
