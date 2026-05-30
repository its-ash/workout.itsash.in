export default defineNuxtConfig({
  srcDir: 'src/',
  modules: ['@vite-pwa/nuxt'],
  devtools: { enabled: true },
  compatibilityDate: 'latest',
  css: ['~/assets/main.css'],
  app: {
    baseURL: '/',
    head: {
      meta: [
        { name: 'theme-color', content: '#171e19' },
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' },
      ],
      link: [
        { rel: 'manifest', href: '/manifest.webmanifest' },
        { rel: 'icon', type: 'image/svg+xml', href: 'icon.svg' },
        { rel: 'icon', type: 'image/svg+xml', sizes: '192x192', href: 'icon-192.svg' },
        { rel: 'icon', type: 'image/svg+xml', sizes: '512x512', href: 'icon-512.svg' },
        { rel: 'apple-touch-icon', sizes: '192x192', href: 'icon-192.svg' },
      ],
    },
  },
  nitro: {
    preset: 'static',
    prerender: {
      crawlLinks: true,
      routes: ['/'],
    },
  },
  pwa: {
    strategies: 'generateSW',
    injectRegister: 'auto',
    registerType: 'autoUpdate',
    manifest: {
      id: '/',
      name: 'Workout PWA',
      short_name: 'Workout',
      description: 'Track split workouts and progress day by day.',
      lang: 'en',
      orientation: 'portrait',
      theme_color: '#171e19',
      background_color: '#eeebe3',
      display: 'standalone',
      start_url: '/',
      scope: '/',
      icons: [
        {
          src: 'icon-192.svg',
          sizes: '192x192',
          type: 'image/svg+xml',
          purpose: 'any',
        },
        {
          src: 'icon-512.svg',
          sizes: '512x512',
          type: 'image/svg+xml',
          purpose: 'any maskable',
        },
      ],
    },
    workbox: {
      cleanupOutdatedCaches: true,
      globPatterns: ['**/*.{js,css,html,png,svg,ico,txt,woff2}'],
      navigateFallback: '/',
    },
    client: {
      installPrompt: true,
    },
    devOptions: {
      enabled: true,
      type: 'module',
    },
  },
})
