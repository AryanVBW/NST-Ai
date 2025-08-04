<script lang="ts">
	import { createEventDispatcher, getContext, onMount } from 'svelte';
	import { toast } from 'svelte-sonner';
	import { testMcpServerConnection } from '$lib/apis/mcp';

	import XMark from '$lib/components/icons/XMark.svelte';
	import Tooltip from '$lib/components/common/Tooltip.svelte';
	import Spinner from '$lib/components/common/Spinner.svelte';
	import CheckCircle from '$lib/components/icons/CheckCircle.svelte';
	import ExclamationTriangle from '$lib/components/icons/ExclamationTriangle.svelte';

	const dispatch = createEventDispatcher();
	const i18n = getContext('i18n');

	export let connection = {
		id: '',
		name: '',
		url: '',
		transport: 'sse',
		auth_type: 'none',
		auth_key: '',
		auth_header_name: '',
		enabled: true,
		config: {}
	};

	export let onSubmit: Function = () => {};
	export let onDelete: Function = () => {};

	let testing = false;
	let testResult = null;

	const testConnection = async () => {
		testing = true;
		testResult = null;

		try {
			const result = await testMcpServerConnection(localStorage.token, {
				name: connection.name,
				url: connection.url,
				transport: connection.transport,
				auth_type: connection.auth_type,
				auth_key: connection.auth_key,
				auth_header_name: connection.auth_header_name
			});

			testResult = result;
			
			if (result.success) {
				toast.success($i18n.t('Connection successful'));
			} else {
				toast.error($i18n.t('Connection failed: {{message}}', { message: result.message }));
			}
		} catch (error) {
			console.error('MCP connection test failed:', error);
			toast.error($i18n.t('Connection test failed'));
			testResult = { success: false, message: error.message || 'Unknown error' };
		} finally {
			testing = false;
		}
	};

	const deleteHandler = () => {
		onDelete();
	};

	const submitHandler = async () => {
		if (!connection.name || !connection.url) {
			toast.error($i18n.t('Name and URL are required'));
			return;
		}

		onSubmit();
	};
</script>

<div class="flex w-full justify-between">
	<div class="flex w-full">
		<div class="w-full">
			<div class="w-full p-3 bg-gray-50 dark:bg-gray-850 rounded-lg">
				<div class="flex justify-between items-center mb-3">
					<div class="flex items-center gap-2">
						<input
							bind:value={connection.name}
							placeholder={$i18n.t('Server Name')}
							class="flex-1 text-sm bg-transparent border-none outline-none font-medium"
							required
						/>
						<div class="flex items-center gap-1">
							<label class="flex items-center gap-1.5 text-xs">
								<input
									type="checkbox"
									bind:checked={connection.enabled}
									class="rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500"
								/>
								{$i18n.t('Enabled')}
							</label>
						</div>
					</div>
					<button
						class="text-gray-500 hover:text-red-500 transition-colors"
						type="button"
						on:click={deleteHandler}
					>
						<XMark className="size-4" />
					</button>
				</div>

				<div class="space-y-3">
					<!-- URL -->
					<div class="flex flex-col gap-1">
						<label class="text-xs font-medium text-gray-700 dark:text-gray-300">
							{$i18n.t('Server URL')}
						</label>
						<input
							bind:value={connection.url}
							placeholder="https://your-mcp-server.com"
							class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
							required
						/>
					</div>

					<!-- Transport -->
					<div class="flex flex-col gap-1">
						<label class="text-xs font-medium text-gray-700 dark:text-gray-300">
							{$i18n.t('Transport')}
						</label>
						<select
							bind:value={connection.transport}
							class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
						>
							<option value="sse">Server-Sent Events (SSE)</option>
							<option value="httpStreamable">HTTP Streamable</option>
						</select>
					</div>

					<!-- Authentication -->
					<div class="flex flex-col gap-1">
						<label class="text-xs font-medium text-gray-700 dark:text-gray-300">
							{$i18n.t('Authentication')}
						</label>
						<select
							bind:value={connection.auth_type}
							class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
						>
							<option value="none">{$i18n.t('None')}</option>
							<option value="bearer">Bearer Token</option>
							<option value="header">Custom Header</option>
						</select>
					</div>

					<!-- Auth Key -->
					{#if connection.auth_type !== 'none'}
						<div class="flex flex-col gap-1">
							<label class="text-xs font-medium text-gray-700 dark:text-gray-300">
								{connection.auth_type === 'bearer' ? $i18n.t('Bearer Token') : $i18n.t('Auth Key')}
							</label>
							<input
								bind:value={connection.auth_key}
								type="password"
								placeholder={connection.auth_type === 'bearer' ? 'Bearer token' : 'Authentication key'}
								class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
							/>
						</div>
					{/if}

					<!-- Header Name for custom header auth -->
					{#if connection.auth_type === 'header'}
						<div class="flex flex-col gap-1">
							<label class="text-xs font-medium text-gray-700 dark:text-gray-300">
								{$i18n.t('Header Name')}
							</label>
							<input
								bind:value={connection.auth_header_name}
								placeholder="X-API-Key"
								class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
							/>
						</div>
					{/if}

					<!-- Actions -->
					<div class="flex justify-between items-center pt-2">
						<div class="flex gap-2">
							<button
								type="button"
								on:click={testConnection}
								disabled={testing || !connection.url}
								class="px-3 py-1.5 text-xs bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white rounded transition-colors flex items-center gap-1.5"
							>
								{#if testing}
									<Spinner className="size-3" />
									{$i18n.t('Testing...')}
								{:else}
									{$i18n.t('Test Connection')}
								{/if}
							</button>

							<button
								type="button"
								on:click={submitHandler}
								class="px-3 py-1.5 text-xs bg-green-500 hover:bg-green-600 text-white rounded transition-colors"
							>
								{$i18n.t('Save')}
							</button>
						</div>

						<!-- Test Result -->
						{#if testResult}
							<div class="flex items-center gap-1.5">
								{#if testResult.success}
									<CheckCircle className="size-4 text-green-500" />
									<span class="text-xs text-green-600 dark:text-green-400">
										{$i18n.t('Connected')}
										{#if testResult.tools_count !== undefined}
											• {testResult.tools_count} tools
										{/if}
									</span>
								{:else}
									<ExclamationTriangle className="size-4 text-red-500" />
									<span class="text-xs text-red-600 dark:text-red-400">
										{$i18n.t('Failed')}
									</span>
								{/if}
							</div>
						{/if}
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
