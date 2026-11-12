/* El Gestor se mudó a xyrostudio.net/gestor/: este SW se borra solo y limpia la caché vieja. */
self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.map(k=>caches.delete(k)))).then(()=>self.registration.unregister()).then(()=>self.clients.matchAll()).then(cs=>cs.forEach(c=>c.navigate('https://xyrostudio.net/gestor/')))));
