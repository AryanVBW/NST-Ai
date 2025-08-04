<script lang="ts">
	import { twMerge } from 'tailwind-merge';

	export let className = 'size-4';
	export let strokeWidth = '1.5';
</script>

<svg
	xmlns="http://www.w3.org/2000/svg"
	fill="none"
	viewBox="0 0 24 24"
	stroke-width={strokeWidth}
	stroke="currentColor"
	class={twMerge('shrink-0', className)}
	{...$$restProps}
>
	<path
		stroke-linecap="round"
		stroke-linejoin="round"
		d="M7 6V4a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v2M10 4h4M7 9v10a2 2 0 0 0 2 2h6a2 2 0 0 0 2 2V9M9 6h6M9 6a2 2 0 0 0-2 2M15 6a2 2 0 0 1 2 2M10 12h4"
	/>
</svg>
