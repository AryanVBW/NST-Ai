<script lang="ts">
	import { createEventDispatcher, getContext } from 'svelte';
	import { toast } from 'svelte-sonner';
	import { testMcpServerConnection } from '$lib/apis/mcp';

	import Modal from '$lib/components/common/Modal.svelte';
	import Spinner from '$lib/components/common/Spinner.svelte';
	import CheckCircle from '$lib/components/icons/CheckCircle.svelte';
	import ExclamationTriangle from '$lib/components/icons/ExclamationTriangle.svelte';

	const dispatch = createEventDispatcher();
	const i18n = getContext('i18n');

	export let show = false;
	export let onSubmit: Function = () => {};

	let serverConfig = {
		name: '',
		url: '',
		transport: 'sse',
		auth_type: 'none',
		auth_key: '',
		auth_header_name: '',
		enabled: true
	};

	let testing = false;
	let testResult = null;

	const resetForm = () => {
		serverConfig = {
			name: '',
			url: '',
			transport: 'sse',
			auth_type: 'none',
			auth_key: '',
			auth_header_name: '',
			enabled: true
		};
		testResult = null;
	};

	const testConnection = async () => {
		if (!serverConfig.url) {
			toast.error($i18n.t('Server URL is required'));
			return;
		}

		testing = true;
		testResult = null;

		try {
			const result = await testMcpServerConnection(localStorage.token, {
				name: serverConfig.name || 'Test Server',
				url: serverConfig.url,
				transport: serverConfig.transport,
				auth_type: serverConfig.auth_type,
				auth_key: serverConfig.auth_key,
				auth_header_name: serverConfig.auth_header_name
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

	const submitHandler = async () => {
		if (!serverConfig.name) {
			toast.error($i18n.t('Server name is required'));
			return;
		}

		if (!serverConfig.url) {
			toast.error($i18n.t('Server URL is required'));
			return;
		}

		if (serverConfig.auth_type === 'header' && !serverConfig.auth_header_name) {
			toast.error($i18n.t('Header name is required for custom header authentication'));
			return;
		}

		// Generate a unique ID for the server
		serverConfig.id = `mcp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

		onSubmit(serverConfig);
		show = false;
		resetForm();
	};

	$: if (show) {
		resetForm();
	}
</script>

<Modal bind:show size="md">
	<div class="p-4">
		<div class="text-lg font-semibold mb-4">{$i18n.t('Add MCP Server')}</div>

		<form on:submit|preventDefault={submitHandler} class="space-y-4">
			<!-- Server Name -->
			<div class="flex flex-col gap-1">
				<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
					{$i18n.t('Server Name')} *
				</label>
				<input
					bind:value={serverConfig.name}
					placeholder={$i18n.t('Enter server name')}
					class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
					required
				/>
			</div>

			<!-- Server URL -->
			<div class="flex flex-col gap-1">
				<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
					{$i18n.t('Server URL')} *
				</label>
				<input
					bind:value={serverConfig.url}
					placeholder="https://your-mcp-server.com"
					class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
					required
				/>
			</div>

			<!-- Transport -->
			<div class="flex flex-col gap-1">
				<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
					{$i18n.t('Transport Protocol')}
				</label>
				<select
					bind:value={serverConfig.transport}
					class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
				>
					<option value="sse">Server-Sent Events (SSE)</option>
					<option value="httpStreamable">HTTP Streamable</option>
				</select>
			</div>

			<!-- Authentication -->
			<div class="flex flex-col gap-1">
				<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
					{$i18n.t('Authentication Type')}
				</label>
				<select
					bind:value={serverConfig.auth_type}
					class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
				>
					<option value="none">{$i18n.t('None')}</option>
					<option value="bearer">Bearer Token</option>
					<option value="header">Custom Header</option>
				</select>
			</div>

			<!-- Auth Key -->
			{#if serverConfig.auth_type !== 'none'}
				<div class="flex flex-col gap-1">
					<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
						{serverConfig.auth_type === 'bearer' ? $i18n.t('Bearer Token') : $i18n.t('Authentication Key')}
					</label>
					<input
						bind:value={serverConfig.auth_key}
						type="password"
						placeholder={serverConfig.auth_type === 'bearer' ? 'Enter bearer token' : 'Enter authentication key'}
						class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
					/>
				</div>
			{/if}

			<!-- Header Name for custom header auth -->
			{#if serverConfig.auth_type === 'header'}
				<div class="flex flex-col gap-1">
					<label class="text-sm font-medium text-gray-700 dark:text-gray-300">
						{$i18n.t('Header Name')}
					</label>
					<input
						bind:value={serverConfig.auth_header_name}
						placeholder="X-API-Key"
						class="w-full text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
					/>
				</div>
			{/if}

			<!-- Enabled checkbox -->
			<div class="flex items-center gap-2">
				<input
					type="checkbox"
					bind:checked={serverConfig.enabled}
					class="rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500"
				/>
				<label class="text-sm text-gray-700 dark:text-gray-300">
					{$i18n.t('Enable this server')}
				</label>
			</div>

			<!-- Test Connection -->
			<div class="border-t border-gray-200 dark:border-gray-700 pt-4">
				<div class="flex justify-between items-center mb-2">
					<button
						type="button"
						on:click={testConnection}
						disabled={testing || !serverConfig.url}
						class="px-4 py-2 text-sm bg-blue-500 hover:bg-blue-600 disabled:bg-gray-400 text-white rounded transition-colors flex items-center gap-2"
					>
						{#if testing}
							<Spinner className="size-4" />
							{$i18n.t('Testing Connection...')}
						{:else}
							{$i18n.t('Test Connection')}
						{/if}
					</button>

					<!-- Test Result -->
					{#if testResult}
						<div class="flex items-center gap-2">
							{#if testResult.success}
								<CheckCircle className="size-5 text-green-500" />
								<div class="text-sm text-green-600 dark:text-green-400">
									<div>{$i18n.t('Connection successful!')}</div>
									{#if testResult.tools_count !== undefined}
										<div class="text-xs opacity-75">
											{testResult.tools_count} tools available
										</div>
									{/if}
								</div>
							{:else}
								<ExclamationTriangle className="size-5 text-red-500" />
								<div class="text-sm text-red-600 dark:text-red-400">
									<div>{$i18n.t('Connection failed')}</div>
									{#if testResult.message}
										<div class="text-xs opacity-75 max-w-48 truncate">
											{testResult.message}
										</div>
									{/if}
								</div>
							{/if}
						</div>
					{/if}
				</div>
			</div>

			<!-- Actions -->
			<div class="flex justify-end gap-2 pt-4 border-t border-gray-200 dark:border-gray-700">
				<button
					type="button"
					on:click={() => (show = false)}
					class="px-4 py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 transition-colors"
				>
					{$i18n.t('Cancel')}
				</button>
				<button
					type="submit"
					class="px-4 py-2 text-sm bg-green-500 hover:bg-green-600 text-white rounded transition-colors"
				>
					{$i18n.t('Add Server')}
				</button>
			</div>
		</form>
	</div>
</Modal>
