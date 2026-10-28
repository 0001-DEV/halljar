const CACHE_NAME = 'halljar-v1';

self.addEventListener('install', event => {
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', event => {
  if (event.request.url.includes('/api/')) {
    return; // Dynamic API calls bypass cache
  }
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});
