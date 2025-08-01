// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';
import starlightBlog from 'starlight-blog';
import starlightLinksValidator from 'starlight-links-validator';

const site = 'https://dart-frog.dev/';

// https://astro.build/config
export default defineConfig({
	site,
	integrations: [
		starlight({
			title: 'Dart Frog',
			tagline: 'A fast, minimalistic backend framework for Dart 🎯',
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
					href: 'https://discord.gg/dart-frog',
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
					autogenerate: { directory: 'basics' },
				},
				{
					label: 'Tutorials',
					autogenerate: { directory: 'tutorials' },
				},
				{
					label: 'Deploy',
					autogenerate: { directory: 'deploy' },
				},
				{
					label: 'Advanced',
					autogenerate: { directory: 'advanced' },
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
							url: 'https://dart-frog.dev',
						},
					},
				}),
				starlightLinksValidator({
					errorOnFallbackPages: false,
					errorOnInconsistentLocale: true,
					exclude: ['http://localhost:8080', 'http://localhost:8080/**'],
				}),
			],
		}),
	],
	vite: { plugins: [tailwindcss()] },
});
