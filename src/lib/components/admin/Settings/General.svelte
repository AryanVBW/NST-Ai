<script lang="ts">
	import DOMPurify from 'dompurify';

	import { getVersionUpdates, getWebhookUrl, updateWebhookUrl } from '$lib/apis';
	import {
		getAdminConfig,
		getLdapConfig,
		getLdapServer,
		updateAdminConfig,
		updateLdapConfig,
		updateLdapServer
	} from '$lib/apis/auths';
	import { workflowService } from '$lib/apis/workflows';
	import SensitiveInput from '$lib/components/common/SensitiveInput.svelte';
	import Switch from '$lib/components/common/Switch.svelte';
	import Tooltip from '$lib/components/common/Tooltip.svelte';
	import { WEBUI_BUILD_HASH, WEBUI_VERSION } from '$lib/constants';
	import { config, showChangelog } from '$lib/stores';
	import { compareVersion } from '$lib/utils';
	import { onMount, getContext } from 'svelte';
	import { toast } from 'svelte-sonner';
	import Textarea from '$lib/components/common/Textarea.svelte';

	const i18n = getContext('i18n');

	export let saveHandler: Function;

	let updateAvailable = null;
	let version = {
		current: '',
		latest: ''
	};

	let adminConfig = null;
	let webhookUrl = '';

	// Workflow Management
	let workflowStatus = null;
	let workflowLoading = false;

	// LDAP
	let ENABLE_LDAP = false;
	let LDAP_SERVER = {
		label: '',
		host: '',
		port: '',
		attribute_for_mail: 'mail',
		attribute_for_username: 'uid',
		app_dn: '',
		app_dn_password: '',
		search_base: '',
		search_filters: '',
		use_tls: false,
		certificate_path: '',
		ciphers: ''
	};

	const checkForVersionUpdates = async () => {
		updateAvailable = null;
		version = await getVersionUpdates(localStorage.token).catch((error) => {
			return {
				current: WEBUI_VERSION,
				latest: WEBUI_VERSION
			};
		});

		console.info(version);

		updateAvailable = compareVersion(version.latest, version.current);
		console.info(updateAvailable);
	};

	const updateLdapServerHandler = async () => {
		if (!ENABLE_LDAP) return;
		const res = await updateLdapServer(localStorage.token, LDAP_SERVER).catch((error) => {
			toast.error(`${error}`);
			return null;
		});
		if (res) {
			toast.success($i18n.t('LDAP server updated'));
		}
	};

	// Workflow management functions
	const checkWorkflowStatus = async () => {
		try {
			workflowStatus = await workflowService.getWorkflowStatus(localStorage.token);
		} catch (error) {
			console.error('Failed to check workflow status:', error);
			workflowStatus = {
				status: 'error',
				process_id: null,
				uptime: null,
				port: null,
				url: null
			};
		}
	};

	const startWorkflowServer = async () => {
		workflowLoading = true;
		try {
			const result = await workflowService.startWorkflowServer(localStorage.token);
			toast.success('Workflow server started successfully!');
			await checkWorkflowStatus();
		} catch (error) {
			toast.error(`Failed to start workflow server: ${error.message}`);
		}
		workflowLoading = false;
	};

	const stopWorkflowServer = async () => {
		workflowLoading = true;
		try {
			await workflowService.stopWorkflowServer(localStorage.token);
			toast.success('Workflow server stopped successfully!');
			await checkWorkflowStatus();
		} catch (error) {
			toast.error(`Failed to stop workflow server: ${error.message}`);
		}
		workflowLoading = false;
	};

	const restartWorkflowServer = async () => {
		workflowLoading = true;
		try {
			await workflowService.restartWorkflowServer(localStorage.token);
			toast.success('Workflow server restarted successfully!');
			await checkWorkflowStatus();
		} catch (error) {
			toast.error(`Failed to restart workflow server: ${error.message}`);
		}
		workflowLoading = false;
	};

	const updateHandler = async () => {
		webhookUrl = await updateWebhookUrl(localStorage.token, webhookUrl);
		const res = await updateAdminConfig(localStorage.token, adminConfig);
		await updateLdapConfig(localStorage.token, ENABLE_LDAP);
		await updateLdapServerHandler();

		// Handle workflow auto-start
		if (adminConfig.ENABLE_WORKFLOW_SYSTEM && adminConfig.WORKFLOW_AUTO_START) {
			// Check if workflow server is not running and start it
			await checkWorkflowStatus();
			if (workflowStatus.status !== 'running') {
				try {
					await startWorkflowServer();
					toast.success('Workflow system auto-started successfully!');
				} catch (error) {
					toast.error('Failed to auto-start workflow system');
				}
			}
		}

		if (res) {
			saveHandler();
		} else {
			toast.error($i18n.t('Failed to update settings'));
		}
	};

	onMount(async () => {
		if ($config?.features?.enable_version_update_check) {
			checkForVersionUpdates();
		}

		await Promise.all([
			(async () => {
				adminConfig = await getAdminConfig(localStorage.token);
			})(),

			(async () => {
				webhookUrl = await getWebhookUrl(localStorage.token);
			})(),
			(async () => {
				LDAP_SERVER = await getLdapServer(localStorage.token);
			})(),
			(async () => {
				await checkWorkflowStatus();
			})()
		]);

		const ldapConfig = await getLdapConfig(localStorage.token);
		ENABLE_LDAP = ldapConfig.ENABLE_LDAP;

		// Auto-start workflow server if enabled
		if (adminConfig?.WORKFLOW_AUTO_START && workflowStatus.status !== 'running') {
			setTimeout(async () => {
				try {
					await startWorkflowServer();
					toast.success('Workflow server auto-started!');
				} catch (error) {
					console.error('Auto-start failed:', error);
				}
			}, 2000); // Wait 2 seconds for UI to load
		}
	});
</script>

<form
	class="flex flex-col h-full justify-between space-y-3 text-sm"
	on:submit|preventDefault={async () => {
		updateHandler();
	}}
>
	<div class="mt-0.5 space-y-3 overflow-y-scroll scrollbar-hidden h-full">
		{#if adminConfig !== null}
			<div class="">
				<div class="mb-3.5">
					<div class=" mb-2.5 text-base font-medium">{$i18n.t('General')}</div>

					<hr class=" border-gray-100 dark:border-gray-850 my-2" />

					<div class="mb-2.5">
						<div class=" mb-1 text-xs font-medium flex space-x-2 items-center">
							<div>
								{$i18n.t('Version')}
							</div>
						</div>
						<div class="flex w-full justify-between items-center">
							<div class="flex flex-col text-xs text-gray-700 dark:text-gray-200">
								<div class="flex gap-1">
									<Tooltip content={WEBUI_BUILD_HASH}>
										v{WEBUI_VERSION}
									</Tooltip>

									{#if $config?.features?.enable_version_update_check}
										<a
											href="https://github.com/AryanVBW/NST-Ai/releases/tag/v{version.latest}"
											target="_blank"
										>
											{updateAvailable === null
												? $i18n.t('Checking for updates...')
												: updateAvailable
													? `(v${version.latest} ${$i18n.t('available!')})`
													: $i18n.t('(latest)')}
										</a>
									{/if}
								</div>

								<button
									class=" underline flex items-center space-x-1 text-xs text-gray-500 dark:text-gray-500"
									type="button"
									on:click={() => {
										showChangelog.set(true);
									}}
								>
									<div>{$i18n.t("See what's new")}</div>
								</button>
							</div>

							{#if $config?.features?.enable_version_update_check}
								<button
									class=" text-xs px-3 py-1.5 bg-gray-50 hover:bg-gray-100 dark:bg-gray-850 dark:hover:bg-gray-800 transition rounded-lg font-medium"
									type="button"
									on:click={() => {
										checkForVersionUpdates();
									}}
								>
									{$i18n.t('Check for updates')}
								</button>
							{/if}
						</div>
					</div>

					<div class="mb-2.5">
						<div class="flex w-full justify-between items-center">
							<div class="text-xs pr-2">
								<div class="">
									{$i18n.t('Help')}
								</div>
								<div class=" text-xs text-gray-500">
									{$i18n.t('Discover how to use NST-Ai and seek support from the community.')}
								</div>
							</div>

							<a
								class="flex-shrink-0 text-xs font-medium underline"
								href="https://docs.NST-AI.com/"
								target="_blank"
							>
								{$i18n.t('Documentation')}
							</a>
						</div>

						<div class="mt-1">
							<div class="flex space-x-1">
								<a href="https://discord.gg/KC5Gfqff" target="_blank">
									<img
										alt="Discord"
										src="https://img.shields.io/badge/Discord-nst_ai-blue?logo=discord&logoColor=white"
									/>
								</a>

								<a href="https://twitter.com/NST-AI" target="_blank">
									<img
										alt="X (formerly Twitter) Follow"
										src="https://img.shields.io/twitter/follow/NST-AI"
									/>
								</a>

								<a href="https://github.com/AryanVBW/NST-Ai" target="_blank">
									<img
										alt="Github Repo"
										src="https://img.shields.io/github/stars/NST-Ai/NST-Ai?style=social&label=Star us on Github"
									/>
								</a>
							</div>
						</div>
					</div>

					<div class="mb-2.5">
						<div class="flex w-full justify-between items-center">
							<div class="text-xs pr-2">
								<div class="">
									{$i18n.t('License')}
								</div>

								{#if $config?.license_metadata}
									<a
										href="https://docs.NST-AI.com/enterprise"
										target="_blank"
										class="text-gray-500 mt-0.5"
									>
										<span class=" capitalize text-black dark:text-white"
											>{$config?.license_metadata?.type}
											license</span
										>
										registered to
										<span class=" capitalize text-black dark:text-white"
											>{$config?.license_metadata?.organization_name}</span
										>
										for
										<span class=" font-medium text-black dark:text-white"
											>{$config?.license_metadata?.seats ?? 'Unlimited'} users.</span
										>
									</a>
									{#if $config?.license_metadata?.html}
										<div class="mt-0.5">
											{@html DOMPurify.sanitize($config?.license_metadata?.html)}
										</div>
									{/if}
								{:else}
									<a
										class=" text-xs hover:underline"
										href="https://docs.NST-AI.com/enterprise"
										target="_blank"
									>
										<span class="text-gray-500">
											{$i18n.t(
												'Upgrade to a licensed plan for enhanced capabilities, including custom theming and branding, and dedicated support.'
											)}
										</span>
									</a>
								{/if}
							</div>

							<!-- <button
								class="flex-shrink-0 text-xs px-3 py-1.5 bg-gray-50 hover:bg-gray-100 dark:bg-gray-850 dark:hover:bg-gray-800 transition rounded-lg font-medium"
							>
								{$i18n.t('Activate')}
							</button> -->
						</div>
					</div>
				</div>

				<div class="mb-3">
					<div class=" mb-2.5 text-base font-medium">{$i18n.t('Authentication')}</div>

					<hr class=" border-gray-100 dark:border-gray-850 my-2" />

					<div class="  mb-2.5 flex w-full justify-between">
						<div class=" self-center text-xs font-medium">{$i18n.t('Default User Role')}</div>
						<div class="flex items-center relative">
							<select
								class="dark:bg-gray-900 w-fit pr-8 rounded-sm px-2 text-xs bg-transparent outline-hidden text-right"
								bind:value={adminConfig.DEFAULT_USER_ROLE}
								placeholder="Select a role"
							>
								<option value="pending">{$i18n.t('pending')}</option>
								<option value="user">{$i18n.t('user')}</option>
								<option value="admin">{$i18n.t('admin')}</option>
							</select>
						</div>
					</div>

					<div class=" mb-2.5 flex w-full justify-between pr-2">
						<div class=" self-center text-xs font-medium">{$i18n.t('Enable New Sign Ups')}</div>

						<Switch bind:state={adminConfig.ENABLE_SIGNUP} />
					</div>

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">
							{$i18n.t('Show Admin Details in Account Pending Overlay')}
						</div>

						<Switch bind:state={adminConfig.SHOW_ADMIN_DETAILS} />
					</div>

					<div class="mb-2.5">
						<div class=" self-center text-xs font-medium mb-2">
							{$i18n.t('Pending User Overlay Title')}
						</div>
						<Textarea
							placeholder={$i18n.t(
								'Enter a title for the pending user info overlay. Leave empty for default.'
							)}
							bind:value={adminConfig.PENDING_USER_OVERLAY_TITLE}
						/>
					</div>

					<div class="mb-2.5">
						<div class=" self-center text-xs font-medium mb-2">
							{$i18n.t('Pending User Overlay Content')}
						</div>
						<Textarea
							placeholder={$i18n.t(
								'Enter content for the pending user info overlay. Leave empty for default.'
							)}
							bind:value={adminConfig.PENDING_USER_OVERLAY_CONTENT}
						/>
					</div>

					<div class="mb-2.5 flex w-full justify-between pr-2">
						<div class=" self-center text-xs font-medium">{$i18n.t('Enable API Key')}</div>

						<Switch bind:state={adminConfig.ENABLE_API_KEY} />
					</div>

					{#if adminConfig?.ENABLE_API_KEY}
						<div class="mb-2.5 flex w-full justify-between pr-2">
							<div class=" self-center text-xs font-medium">
								{$i18n.t('API Key Endpoint Restrictions')}
							</div>

							<Switch bind:state={adminConfig.ENABLE_API_KEY_ENDPOINT_RESTRICTIONS} />
						</div>

						{#if adminConfig?.ENABLE_API_KEY_ENDPOINT_RESTRICTIONS}
							<div class=" flex w-full flex-col pr-2">
								<div class=" text-xs font-medium">
									{$i18n.t('Allowed Endpoints')}
								</div>

								<input
									class="w-full mt-1 rounded-lg text-sm dark:text-gray-300 bg-transparent outline-hidden"
									type="text"
									placeholder={`e.g.) /api/v1/messages, /api/v1/channels`}
									bind:value={adminConfig.API_KEY_ALLOWED_ENDPOINTS}
								/>

								<div class="mt-2 text-xs text-gray-400 dark:text-gray-500">
									<!-- https://docs.NST-AI.com/getting-started/advanced-topics/api-endpoints -->
									<a
										href="https://docs.NST-AI.com/getting-started/api-endpoints"
										target="_blank"
										class=" text-gray-300 font-medium underline"
									>
										{$i18n.t('To learn more about available endpoints, visit our documentation.')}
									</a>
								</div>
							</div>
						{/if}
					{/if}

					<div class=" mb-2.5 w-full justify-between">
						<div class="flex w-full justify-between">
							<div class=" self-center text-xs font-medium">{$i18n.t('JWT Expiration')}</div>
						</div>

						<div class="flex mt-2 space-x-2">
							<input
								class="w-full rounded-lg py-2 px-4 text-sm bg-gray-50 dark:text-gray-300 dark:bg-gray-850 outline-hidden"
								type="text"
								placeholder={`e.g.) "30m","1h", "10d". `}
								bind:value={adminConfig.JWT_EXPIRES_IN}
							/>
						</div>

						<div class="mt-2 text-xs text-gray-400 dark:text-gray-500">
							{$i18n.t('Valid time units:')}
							<span class=" text-gray-300 font-medium"
								>{$i18n.t("'s', 'm', 'h', 'd', 'w' or '-1' for no expiration.")}</span
							>
						</div>
					</div>

					<div class=" space-y-3">
						<div class="mt-2 space-y-2 pr-1.5">
							<div class="flex justify-between items-center text-sm">
								<div class="  font-medium">{$i18n.t('LDAP')}</div>

								<div class="mt-1">
									<Switch bind:state={ENABLE_LDAP} />
								</div>
							</div>

							{#if ENABLE_LDAP}
								<div class="flex flex-col gap-1">
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Label')}
											</div>
											<input
												class="w-full bg-transparent outline-hidden py-0.5"
												required
												placeholder={$i18n.t('Enter server label')}
												bind:value={LDAP_SERVER.label}
											/>
										</div>
										<div class="w-full"></div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Host')}
											</div>
											<input
												class="w-full bg-transparent outline-hidden py-0.5"
												required
												placeholder={$i18n.t('Enter server host')}
												bind:value={LDAP_SERVER.host}
											/>
										</div>
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Port')}
											</div>
											<Tooltip
												placement="top-start"
												content={$i18n.t('Default to 389 or 636 if TLS is enabled')}
												className="w-full"
											>
												<input
													class="w-full bg-transparent outline-hidden py-0.5"
													type="number"
													placeholder={$i18n.t('Enter server port')}
													bind:value={LDAP_SERVER.port}
												/>
											</Tooltip>
										</div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Application DN')}
											</div>
											<Tooltip
												content={$i18n.t('The Application Account DN you bind with for search')}
												placement="top-start"
											>
												<input
													class="w-full bg-transparent outline-hidden py-0.5"
													required
													placeholder={$i18n.t('Enter Application DN')}
													bind:value={LDAP_SERVER.app_dn}
												/>
											</Tooltip>
										</div>
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Application DN Password')}
											</div>
											<SensitiveInput
												placeholder={$i18n.t('Enter Application DN Password')}
												bind:value={LDAP_SERVER.app_dn_password}
											/>
										</div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Attribute for Mail')}
											</div>
											<Tooltip
												content={$i18n.t(
													'The LDAP attribute that maps to the mail that users use to sign in.'
												)}
												placement="top-start"
											>
												<input
													class="w-full bg-transparent outline-hidden py-0.5"
													required
													placeholder={$i18n.t('Example: mail')}
													bind:value={LDAP_SERVER.attribute_for_mail}
												/>
											</Tooltip>
										</div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Attribute for Username')}
											</div>
											<Tooltip
												content={$i18n.t(
													'The LDAP attribute that maps to the username that users use to sign in.'
												)}
												placement="top-start"
											>
												<input
													class="w-full bg-transparent outline-hidden py-0.5"
													required
													placeholder={$i18n.t(
														'Example: sAMAccountName or uid or userPrincipalName'
													)}
													bind:value={LDAP_SERVER.attribute_for_username}
												/>
											</Tooltip>
										</div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Search Base')}
											</div>
											<Tooltip
												content={$i18n.t('The base to search for users')}
												placement="top-start"
											>
												<input
													class="w-full bg-transparent outline-hidden py-0.5"
													required
													placeholder={$i18n.t('Example: ou=users,dc=foo,dc=example')}
													bind:value={LDAP_SERVER.search_base}
												/>
											</Tooltip>
										</div>
									</div>
									<div class="flex w-full gap-2">
										<div class="w-full">
											<div class=" self-center text-xs font-medium min-w-fit mb-1">
												{$i18n.t('Search Filters')}
											</div>
											<input
												class="w-full bg-transparent outline-hidden py-0.5"
												placeholder={$i18n.t('Example: (&(objectClass=inetOrgPerson)(uid=%s))')}
												bind:value={LDAP_SERVER.search_filters}
											/>
										</div>
									</div>
									<div class="text-xs text-gray-400 dark:text-gray-500">
										<a
											class=" text-gray-300 font-medium underline"
											href="https://ldap.com/ldap-filters/"
											target="_blank"
										>
											{$i18n.t('Click here for filter guides.')}
										</a>
									</div>
									<div>
										<div class="flex justify-between items-center text-sm">
											<div class="  font-medium">{$i18n.t('TLS')}</div>

											<div class="mt-1">
												<Switch bind:state={LDAP_SERVER.use_tls} />
											</div>
										</div>
										{#if LDAP_SERVER.use_tls}
											<div class="flex w-full gap-2">
												<div class="w-full">
													<div class=" self-center text-xs font-medium min-w-fit mb-1 mt-1">
														{$i18n.t('Certificate Path')}
													</div>
													<input
														class="w-full bg-transparent outline-hidden py-0.5"
														placeholder={$i18n.t('Enter certificate path')}
														bind:value={LDAP_SERVER.certificate_path}
													/>
												</div>
											</div>
											<div class="flex justify-between items-center text-xs">
												<div class=" font-medium">Validate certificate</div>

												<div class="mt-1">
													<Switch bind:state={LDAP_SERVER.validate_cert} />
												</div>
											</div>
											<div class="flex w-full gap-2">
												<div class="w-full">
													<div class=" self-center text-xs font-medium min-w-fit mb-1">
														{$i18n.t('Ciphers')}
													</div>
													<Tooltip content={$i18n.t('Default to ALL')} placement="top-start">
														<input
															class="w-full bg-transparent outline-hidden py-0.5"
															placeholder={$i18n.t('Example: ALL')}
															bind:value={LDAP_SERVER.ciphers}
														/>
													</Tooltip>
												</div>
												<div class="w-full"></div>
											</div>
										{/if}
									</div>
								</div>
							{/if}
						</div>
					</div>
				</div>

				<div class="mb-3">
					<div class=" mb-2.5 text-base font-medium">{$i18n.t('Features')}</div>

					<hr class=" border-gray-100 dark:border-gray-850 my-2" />

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">
							{$i18n.t('Enable Community Sharing')}
						</div>

						<Switch bind:state={adminConfig.ENABLE_COMMUNITY_SHARING} />
					</div>

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">{$i18n.t('Enable Message Rating')}</div>

						<Switch bind:state={adminConfig.ENABLE_MESSAGE_RATING} />
					</div>

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">
							{$i18n.t('Notes')} ({$i18n.t('Beta')})
						</div>

						<Switch bind:state={adminConfig.ENABLE_NOTES} />
					</div>

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">
							{$i18n.t('Channels')} ({$i18n.t('Beta')})
						</div>

						<Switch bind:state={adminConfig.ENABLE_CHANNELS} />
					</div>

					<div class="mb-2.5 flex w-full items-center justify-between pr-2">
						<div class=" self-center text-xs font-medium">
							{$i18n.t('User Webhooks')}
						</div>

						<Switch bind:state={adminConfig.ENABLE_USER_WEBHOOKS} />
					</div>

					<!-- NST-AI Workflow System -->
					<hr class="border-gray-100 dark:border-gray-850 my-4" />
					<div class="mb-3">
						<div class="mb-2.5 text-sm font-medium flex items-center space-x-2">
							<div>NST-AI Workflow System</div>
							<div class="px-2 py-0.5 text-xs bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 rounded">
								Advanced
							</div>
						</div>

						<div class="mb-2.5 flex w-full items-center justify-between pr-2">
							<div class="self-center text-xs font-medium">Enable Workflow System</div>
							<Switch bind:state={adminConfig.ENABLE_WORKFLOW_SYSTEM} />
						</div>

						{#if adminConfig.ENABLE_WORKFLOW_SYSTEM}
							<div class="mb-2.5 flex w-full items-center justify-between pr-2">
								<div class="self-center text-xs font-medium">Auto-Start on Admin Login</div>
								<Switch bind:state={adminConfig.WORKFLOW_AUTO_START} />
							</div>

							<!-- Workflow Status -->
							<div class="mb-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
								<div class="flex items-center justify-between mb-2">
									<div class="text-xs font-medium">Workflow Server Status</div>
									<div class="flex items-center space-x-2">
										<div 
											class="w-2 h-2 rounded-full {workflowStatus.status === 'running' ? 'bg-green-500' : workflowStatus.status === 'error' ? 'bg-red-500' : 'bg-gray-400'}"
										></div>
										<span class="text-xs text-gray-600 dark:text-gray-400 capitalize">
											{workflowStatus.status}
										</span>
									</div>
								</div>

								{#if workflowStatus.status === 'running'}
									<div class="text-xs text-gray-600 dark:text-gray-400 mb-2">
										<div>Process ID: {workflowStatus.process_id}</div>
										<div>Port: {workflowStatus.port}</div>
										{#if workflowStatus.uptime}
											<div>Uptime: {workflowStatus.uptime}</div>
										{/if}
										{#if workflowStatus.url}
											<div>
												URL: <a href={workflowStatus.url} target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline">
													{workflowStatus.url}
												</a>
											</div>
										{/if}
									</div>
								{/if}

								<!-- Control Buttons -->
								<div class="flex space-x-2">
									<button
										class="px-3 py-1 text-xs bg-green-600 hover:bg-green-700 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed"
										on:click={startWorkflowServer}
										disabled={workflowLoading || workflowStatus.status === 'running'}
									>
										{#if workflowLoading && workflowStatus.status !== 'running'}
											<div class="flex items-center space-x-1">
												<div class="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin"></div>
												<span>Starting...</span>
											</div>
										{:else}
											Start Server
										{/if}
									</button>

									<button
										class="px-3 py-1 text-xs bg-red-600 hover:bg-red-700 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed"
										on:click={stopWorkflowServer}
										disabled={workflowLoading || workflowStatus.status !== 'running'}
									>
										{#if workflowLoading && workflowStatus.status === 'running'}
											<div class="flex items-center space-x-1">
												<div class="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin"></div>
												<span>Stopping...</span>
											</div>
										{:else}
											Stop Server
										{/if}
									</button>

									<button
										class="px-3 py-1 text-xs bg-blue-600 hover:bg-blue-700 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed"
										on:click={restartWorkflowServer}
										disabled={workflowLoading}
									>
										{#if workflowLoading}
											<div class="flex items-center space-x-1">
												<div class="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin"></div>
												<span>Restarting...</span>
											</div>
										{:else}
											Restart
										{/if}
									</button>

									<button
										class="px-3 py-1 text-xs bg-gray-600 hover:bg-gray-700 text-white rounded"
										on:click={checkWorkflowStatus}
									>
										Refresh
									</button>
								</div>

								{#if workflowStatus.status === 'running'}
									<div class="mt-2 text-xs text-green-600 dark:text-green-400">
										✓ Workflow system is running and accessible via the "NST-AI Workflow" tab
									</div>
								{:else if workflowStatus.status === 'error'}
									<div class="mt-2 text-xs text-red-600 dark:text-red-400">
										⚠ Workflow system encountered an error. Check logs for details.
									</div>
								{:else}
									<div class="mt-2 text-xs text-gray-600 dark:text-gray-400">
										ℹ Click "Start Server" to enable workflow automation features
									</div>
								{/if}
							</div>
						{/if}
					</div>

					<div class="mb-2.5">
						<div class=" self-center text-xs font-medium mb-2">
							{$i18n.t('Response Watermark')}
						</div>
						<Textarea
							placeholder={$i18n.t('Enter a watermark for the response. Leave empty for none.')}
							bind:value={adminConfig.RESPONSE_WATERMARK}
						/>
					</div>

					<div class="mb-2.5 w-full justify-between">
						<div class="flex w-full justify-between">
							<div class=" self-center text-xs font-medium">{$i18n.t('WebUI URL')}</div>
						</div>

						<div class="flex mt-2 space-x-2">
							<input
								class="w-full rounded-lg py-2 px-4 text-sm bg-gray-50 dark:text-gray-300 dark:bg-gray-850 outline-hidden"
								type="text"
								placeholder={`e.g.) "http://localhost:3000"`}
								bind:value={adminConfig.WEBUI_URL}
							/>
						</div>

						<div class="mt-2 text-xs text-gray-400 dark:text-gray-500">
							{$i18n.t(
								'Enter the public URL of your WebUI. This URL will be used to generate links in the notifications.'
							)}
						</div>
					</div>

					<div class=" w-full justify-between">
						<div class="flex w-full justify-between">
							<div class=" self-center text-xs font-medium">{$i18n.t('Webhook URL')}</div>
						</div>

						<div class="flex mt-2 space-x-2">
							<input
								class="w-full rounded-lg py-2 px-4 text-sm bg-gray-50 dark:text-gray-300 dark:bg-gray-850 outline-hidden"
								type="text"
								placeholder={`https://example.com/webhook`}
								bind:value={webhookUrl}
							/>
						</div>
					</div>
				</div>
			</div>
		{/if}
	</div>

	<div class="flex justify-end pt-3 text-sm font-medium">
		<button
			class="px-3.5 py-1.5 text-sm font-medium bg-black hover:bg-gray-900 text-white dark:bg-white dark:text-black dark:hover:bg-gray-100 transition rounded-full"
			type="submit"
		>
			{$i18n.t('Save')}
		</button>
	</div>
</form>
