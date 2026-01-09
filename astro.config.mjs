import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://baynavigator.org',
  integrations: [
    tailwind(),
    sitemap({
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
      serialize(item) {
        // Set higher priority for main pages
        if (item.url === 'https://baynavigator.org/') {
          item.priority = 1.0;
          item.changefreq = 'daily';
        } else if (item.url.includes('/directory')) {
          item.priority = 0.9;
          item.changefreq = 'daily';
        } else if (item.url.includes('/eligibility')) {
          item.priority = 0.8;
        }
        return item;
      },
    }),
  ],
  markdown: {
    shikiConfig: {
      theme: 'github-light',
    },
  },
});
