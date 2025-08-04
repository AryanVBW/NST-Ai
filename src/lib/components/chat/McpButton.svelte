<script lang="ts">
	import { onMount, createEventDispatcher } from 'svelte';
	import { toast } from 'svelte-sonner';
	import { fade, slide } from 'svelte/transition';
	import { clickOutside } from '$lib/actions/clickOutside';
	import { i18n } from '$lib/stores';
	import { getConnectedMcpServers, getMcpServerTools } from '$lib/apis/mcp';
	import Tooltip from '../common/Tooltip.svelte';

	// Icons
	import Cog from '$lib/components/icons/Cog.svelte';
	import ChevronDown from '$lib/components/icons/ChevronDown.svelte';
	import Settings from '$lib/components/icons/Settings.svelte';
	import Plug from '$lib/components/icons/Plug.svelte';

	const dispatch = createEventDispatcher();

	export let mcpServersEnabled: boolean = false;
	export let selectedMcpServers: string[] = [];

	let showDropdown = false;
	let mcpServers: any[] = [];
	let mcpServerTools: { [key: string]: any[] } = {};
	let loading = false;

	// Load MCP servers on component mount
	onMount(async () => {
		await loadMcpServers();
	});

	const loadMcpServers = async () => {
		loading = true;
		try {
			const data = await getConnectedMcpServers();
			mcpServers = data.servers || [];
			
			// Load tools for each connected server
			for (const server of mcpServers.filter(s => s.status === 'connected')) {
				try {
					const toolsData = await getMcpServerTools(server.id);
					mcpServerTools[server.id] = toolsData.tools || [];
				} catch (error) {
					console.error(`Failed to load tools for MCP server ${server.name}:`, error);
					mcpServerTools[server.id] = [];
				}
			}
		} catch (error) {
			console.error('Failed to load MCP servers:', error);
			toast.error($i18n.t('Failed to load MCP servers'));
		} finally {
			loading = false;
		}
	};

	const toggleMcpServer = (serverId: string) => {
		if (selectedMcpServers.includes(serverId)) {
			selectedMcpServers = selectedMcpServers.filter(id => id !== serverId);
		} else {
			selectedMcpServers = [...selectedMcpServers, serverId];
		}
		
		// Update parent component about the change
		dispatch('mcpServersChanged', {
			enabled: mcpServersEnabled,
			selectedServers: selectedMcpServers
		});
	};

	const toggleMcpServers = () => {
		mcpServersEnabled = !mcpServersEnabled;
		if (!mcpServersEnabled) {
			selectedMcpServers = [];
		}
		
		dispatch('mcpServersChanged', {
			enabled: mcpServersEnabled,
			selectedServers: selectedMcpServers
		});
	};

	const getConnectedServersCount = () => {
		return mcpServers.filter(s => s.status === 'connected').length;
	};

	const getSelectedServersCount = () => {
		return selectedMcpServers.length;
	};

	const getTotalToolsCount = () => {
		return selectedMcpServers.reduce((total, serverId) => {
			return total + (mcpServerTools[serverId]?.length || 0);
		}, 0);
	};

	const handleRefresh = async () => {
		await loadMcpServers();
		toast.success($i18n.t('MCP servers refreshed'));
	};

	// Close dropdown when clicking outside
	const handleClickOutside = () => {
		showDropdown = false;
	};
</script>

<div class="relative">
	<!-- MCP Button -->
	<Tooltip content={$i18n.t('Connect to MCP servers')} placement="top">
		<button
			aria-label={mcpServersEnabled
				? $i18n.t('Disable MCP servers')
				: $i18n.t('Enable MCP servers')}
			aria-pressed={mcpServersEnabled}
			on:click|preventDefault={toggleMcpServers}
			type="button"
			class="px-2 @xl:px-2.5 py-2 flex gap-1.5 items-center text-sm transition-colors duration-300 max-w-full overflow-hidden hover:bg-gray-50 dark:hover:bg-gray-800 {mcpServersEnabled
				? ' text-blue-500 dark:text-blue-300 bg-blue-50 dark:bg-blue-200/5'
				: 'bg-transparent text-gray-600 dark:text-gray-300 '} focus:outline-hidden rounded-full"
		>
			<Plug className="size-4" strokeWidth="1.75" />
			<span
				class="hidden @xl:block whitespace-nowrap overflow-hidden text-ellipsis leading-none pr-0.5"
			>
				{$i18n.t('MCP')}
				{#if mcpServersEnabled && getSelectedServersCount() > 0}
					<span class="text-xs opacity-75">
						({getSelectedServersCount()})
					</span>
				{/if}
			</span>
			
			<!-- Dropdown arrow -->
			<button
				on:click|stopPropagation={() => (showDropdown = !showDropdown)}
				class="ml-1 p-0.5 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors"
			>
				<ChevronDown 
					className="size-3 transition-transform {showDropdown ? 'rotate-180' : ''}" 
					strokeWidth="2" 
				/>
			</button>
		</button>
	</Tooltip>

	<!-- Dropdown Menu -->
	{#if showDropdown}
		<div
			class="absolute bottom-full mb-2 left-0 z-50 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg min-w-80 max-w-96"
			use:clickOutside={handleClickOutside}
			transition:slide={{ duration: 200 }}
		>
			<!-- Header -->
			<div class="p-3 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
				<h3 class="font-medium text-gray-900 dark:text-gray-100">
					{$i18n.t('MCP Servers')}
				</h3>
				<div class="flex items-center gap-2">
					<button
						on:click={handleRefresh}
						class="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
						disabled={loading}
					>
						<Cog className="size-4 {loading ? 'animate-spin' : ''}" />
					</button>
					<span class="text-xs text-gray-500 dark:text-gray-400">
						{getConnectedServersCount()} connected
					</span>
				</div>
			</div>

			<!-- Content -->
			<div class="max-h-64 overflow-y-auto">
				{#if loading}
					<div class="p-4 text-center text-gray-500 dark:text-gray-400">
						<Cog className="size-6 animate-spin mx-auto mb-2" />
						{$i18n.t('Loading MCP servers...')}
					</div>
				{:else if mcpServers.length === 0}
					<div class="p-4 text-center text-gray-500 dark:text-gray-400">
						<Plug className="size-8 mx-auto mb-2 opacity-50" />
						<p>{$i18n.t('No MCP servers configured')}</p>
						<p class="text-xs mt-1">
							{$i18n.t('Configure servers in admin settings')}
						</p>
					</div>
				{:else}
					<div class="p-2">
						{#each mcpServers as server (server.id)}
							<div class="mb-2 last:mb-0">
								<label class="flex items-center p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-lg cursor-pointer transition-colors">
									<input
										type="checkbox"
										checked={selectedMcpServers.includes(server.id)}
										on:change={() => toggleMcpServer(server.id)}
										disabled={server.status !== 'connected'}
										class="mr-3 rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500 disabled:opacity-50"
									/>
									<div class="flex-1">
										<div class="flex items-center justify-between">
											<span class="font-medium text-sm text-gray-900 dark:text-gray-100">
												{server.name}
											</span>
											<div class="flex items-center gap-2">
												<span class="text-xs px-2 py-0.5 rounded-full {server.status === 'connected' 
													? 'bg-green-100 text-green-800 dark:bg-green-200/20 dark:text-green-400' 
													: 'bg-red-100 text-red-800 dark:bg-red-200/20 dark:text-red-400'}">
													{server.status}
												</span>
												{#if server.status === 'connected'}
													<span class="text-xs text-gray-500 dark:text-gray-400">
														{server.tools_count || 0} tools
													</span>
												{/if}
											</div>
										</div>
										{#if selectedMcpServers.includes(server.id) && mcpServerTools[server.id]?.length > 0}
											<div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
												Tools: {mcpServerTools[server.id].slice(0, 3).map(t => t.name).join(', ')}
												{#if mcpServerTools[server.id].length > 3}
													and {mcpServerTools[server.id].length - 3} more
												{/if}
											</div>
										{/if}
									</div>
								</label>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			<!-- Footer -->
			{#if mcpServersEnabled && getSelectedServersCount() > 0}
				<div class="p-3 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-700/50 rounded-b-lg">
					<div class="text-xs text-gray-600 dark:text-gray-400 text-center">
						{getSelectedServersCount()} server{getSelectedServersCount() !== 1 ? 's' : ''} selected
						• {getTotalToolsCount()} tool{getTotalToolsCount() !== 1 ? 's' : ''} available
					</div>
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	/* Custom scrollbar for dropdown */
	.max-h-64::-webkit-scrollbar {
		width: 6px;
	}
	
	.max-h-64::-webkit-scrollbar-track {
		background: transparent;
	}
	
	.max-h-64::-webkit-scrollbar-thumb {
		background: rgba(156, 163, 175, 0.3);
		border-radius: 3px;
	}
	
	.max-h-64::-webkit-scrollbar-thumb:hover {
		background: rgba(156, 163, 175, 0.5);
	}

	/* Dark mode scrollbar */
	.dark .max-h-64::-webkit-scrollbar-thumb {
		background: rgba(75, 85, 99, 0.3);
	}
	
	.dark .max-h-64::-webkit-scrollbar-thumb:hover {
		background: rgba(75, 85, 99, 0.5);
	}
</style>
