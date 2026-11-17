// @ts-check
import { defineConfig } from 'astro/config';
import { satteri, satteriHeadingIdsPlugin } from '@astrojs/markdown-satteri';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';
import starlightBlog from 'starlight-blog';
import starlightLinksValidator from 'starlight-links-validator';
import { normalizeHeadingIds } from './plugins/normalize-heading-ids';

const site = 'https://dart-frog.dev/';

// https://astro.build/config
export default defineConfig({
	site,
	integrations: [
		starlight({
			title: 'Dart Frog',
			logo: {
				light: './src/assets/logo-dark.png',
				dark: './src/assets/logo-light.png',
				replacesTitle: true,
			},
			favicon: 'favicon.ico',
			expressiveCode: {
				themes: ['dark-plus', 'github-light'],
			},
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/dart-frog-dev/dart_frog',
				},
				{
					icon: 'discord',
					label: 'Discord',
					href: 'https://dart-frog.dev/discord',
				},
			],
			editLink: {
				baseUrl: 'https://github.com/dart-frog-dev/dart_frog/edit/main/docs',
			},
			head: [
				{
					tag: 'meta',
					attrs: { property: 'og:image', content: site + 'open-graph.png?v=1' },
				},
				{
					tag: 'meta',
					attrs: {
						property: 'twitter:image',
						content: site + 'open-graph.png?v=1',
					},
				},
			],
			customCss: ['./src/tailwind.css', './src/styles/landing.css'],
			sidebar: [
				{
					label: 'Getting Started',
					link: '/getting-started/',
				},
				{
					label: 'Basics',
					items: [{ autogenerate: { directory: 'basics' } }],
				},
				{
					label: 'Tutorials',
					items: [{ autogenerate: { directory: 'tutorials' } }],
				},
				{
					label: 'Deploy',
					items: [{ autogenerate: { directory: 'deploy' } }],
				},
				{
					label: 'Advanced',
					items: [{ autogenerate: { directory: 'advanced' } }],
				},
				{
					label: '🗺️ Roadmap',
					link: '/roadmap/',
				},
			],
			plugins: [
				starlightBlog({
					metrics: { readingTime: true, words: false },
					authors: {
						team: {
							name: 'Dart Frog',
							title: 'Team',
							picture: '/headshots/dart-frog.svg',
							url: site,
						},
						erickzanardo: {
							name: 'Erick Zanardo',
							title: 'Maintainer',
							picture: '/headshots/erick-zanardo.png',
							url: 'https://github.com/erickzanardo',
						},
					},
				}),
				starlightLinksValidator({
					errorOnFallbackPages: false,
					errorOnInconsistentLocale: true,
					exclude: ['/blog/**', 'http://localhost:8080', 'http://localhost:8080/**'],
				}),
			],
		}),
	],
	markdown: {
		processor: satteri({
			hastPlugins: [satteriHeadingIdsPlugin(), normalizeHeadingIds],
		}),
	},
	vite: { plugins: [tailwindcss()] },
	redirects: { discord: 'https://discord.gg/ykpUvKxw9k' },
});
