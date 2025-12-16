const CACHE_NAME = 'bay-area-discounts';
const BASE_URL = self.registration.scope.replace(/\/$/, '');
const urlsToCache = [
  `${BASE_URL}/`,
  `${BASE_URL}/students.html`,
  `${BASE_URL}/assets/css/vision-pro-optimized.css`,
  `${BASE_URL}/assets/css/accessibility-toolbar.css`,
  `${BASE_URL}/assets/css/read-more.css`,
  `${BASE_URL}/assets/js/search-filter.js`,
  `${BASE_URL}/assets/js/accessibility-toolbar.js`,
  `${BASE_URL}/assets/js/read-more.js`,
  `${BASE_URL}/assets/images/favicons/favicon-96x96.png`,
  `${BASE_URL}/assets/images/favicons/favicon.svg`,
  `${BASE_URL}/assets/images/favicons/apple-touch-icon.png`,
  `${BASE_URL}/assets/images/logo/banner.svg`,
  `${BASE_URL}/assets/images/logo/logo.svg`
];

// Install service worker and cache resources
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
      .catch(err => {
        console.error('Cache installation failed:', err);
      })
  );
});

// Fetch from cache, fallback to network
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response;
        }

        const fetchRequest = event.request.clone();
        
        return fetch(fetchRequest).then(response => {
          if (!response || response.status !== 200 || (response.type !== 'basic' && response.type !== 'cors')) {
            return response;
          }

          const responseToCache = response.clone();

          caches.open(CACHE_NAME)
            .then(cache => {
              cache.put(event.request, responseToCache);
            })
            .catch(err => {
              console.error('Failed to cache:', err);
            });

          return response;
        });
      })
  );
});

// Clean up old caches
self.addEventListener('activate', event => {
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
