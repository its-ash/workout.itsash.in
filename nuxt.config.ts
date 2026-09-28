const SITE_URL = "https://workout.itsash.in";
const GA_ID = "G-Z6HTBE0K9R";

export default defineNuxtConfig({
  srcDir: "src/",
  modules: ["@vite-pwa/nuxt"],
  devtools: { enabled: true },
  compatibilityDate: "latest",
  css: ["~/assets/main.css"],
  app: {
    baseURL: "/",
    head: {
      htmlAttrs: { lang: "en" },
      title: "WorkOut — Push Pull Legs Workout Planner & Gym Tracker",
      meta: [
        {
          name: "description",
          content:
            "Free evidence-based Push/Pull/Legs workout planner. Science-backed sets, reps, RIR and rest times, exercise demos, stretching routine and interval walk timer. Works offline as a PWA.",
        },
        {
          name: "keywords",
          content:
            "push pull legs, PPL workout, gym workout planner, hypertrophy program, workout tracker, RIR, exercise demos, interval walking, stretching routine",
        },
        { name: "author", content: "Ashvini Jangid" },
        { name: "robots", content: "index, follow, max-image-preview:large" },
        { name: "application-name", content: "WorkOut" },
        { name: "apple-mobile-web-app-title", content: "WorkOut" },
        { property: "og:type", content: "website" },
        { property: "og:site_name", content: "WorkOut" },
        { property: "og:url", content: SITE_URL },
        {
          property: "og:title",
          content: "WorkOut — Push Pull Legs Workout Planner",
        },
        {
          property: "og:description",
          content:
            "Evidence-based PPL sessions with sets, reps, RIR, rest times and exercise demos. Free and offline-ready.",
        },
        { property: "og:image", content: `${SITE_URL}/og.png` },
        { property: "og:image:width", content: "1200" },
        { property: "og:image:height", content: "630" },
        { name: "twitter:card", content: "summary_large_image" },
        {
          name: "twitter:title",
          content: "WorkOut — Push Pull Legs Workout Planner",
        },
        {
          name: "twitter:description",
          content:
            "Evidence-based PPL sessions with sets, reps, RIR, rest times and exercise demos.",
        },
        { name: "twitter:image", content: `${SITE_URL}/og.png` },
        { name: "theme-color", content: "#0a0a0a" },
        { name: "apple-mobile-web-app-capable", content: "yes" },
        {
          name: "apple-mobile-web-app-status-bar-style",
          content: "black-translucent",
        },
      ],
      link: [
        { rel: "canonical", href: `${SITE_URL}/` },
        { rel: "manifest", href: "/manifest.webmanifest" },
        { rel: "preconnect", href: "https://fonts.googleapis.com" },
        {
          rel: "preconnect",
          href: "https://fonts.gstatic.com",
          crossorigin: "",
        },
        {
          rel: "stylesheet",
          href: "https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap",
        },
        { rel: "icon", type: "image/svg+xml", href: "icon.svg" },
        {
          rel: "icon",
          type: "image/svg+xml",
          sizes: "192x192",
          href: "icon-192.svg",
        },
        {
          rel: "icon",
          type: "image/svg+xml",
          sizes: "512x512",
          href: "icon-512.svg",
        },
        { rel: "apple-touch-icon", sizes: "192x192", href: "icon-192.svg" },
      ],
      script: [
        {
          src: `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`,
          async: true,
        },
        {
          innerHTML: `window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','${GA_ID}');`,
        },
        {
          type: "application/ld+json",
          innerHTML: JSON.stringify({
            "@context": "https://schema.org",
            "@type": "WebApplication",
            name: "WorkOut",
            url: `${SITE_URL}/`,
            description:
              "Evidence-based Push/Pull/Legs workout planner with exercise demos, stretching routine and interval walk timer.",
            applicationCategory: "HealthApplication",
            operatingSystem: "Any",
            offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
            author: {
              "@type": "Person",
              name: "Ashvini Jangid",
              url: "https://itsash.in",
            },
          }),
        },
      ],
    },
  },
  nitro: {
    preset: "static",
    prerender: {
      crawlLinks: true,
      routes: ["/"],
    },
  },
  pwa: {
    strategies: "generateSW",
    injectRegister: "auto",
    registerType: "autoUpdate",
    client: {
      installPrompt: false,
      periodicSyncForUpdates: 3600,
    },
    manifest: {
      id: "/",
      name: "WorkOut — PPL Workout Planner",
      short_name: "WorkOut",
      description: "Evidence-based Push/Pull/Legs workout planner with exercise demos and timers.",
      lang: "en",
      orientation: "portrait",
      theme_color: "#0a0a0a",
      background_color: "#0a0a0a",
      display: "standalone",
      start_url: "/",
      scope: "/",
      icons: [
        {
          src: "icon-192.svg",
          sizes: "192x192",
          type: "image/svg+xml",
          purpose: "any",
        },
        {
          src: "icon-512.svg",
          sizes: "512x512",
          type: "image/svg+xml",
          purpose: "any maskable",
        },
      ],
    },
    workbox: {
      cleanupOutdatedCaches: true,
      globPatterns: ["**/*.{js,css,html,png,svg,ico,txt,woff2}"],
      navigateFallback: "/",
    },
    client: {
      installPrompt: true,
    },
    devOptions: {
      enabled: true,
      type: "module",
    },
  },
});
