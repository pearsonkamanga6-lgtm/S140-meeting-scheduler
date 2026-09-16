const CACHE="s140-v5-3";
const ASSETS=["./","./index.html","./manifest.webmanifest","./icon-192.png","./icon-512.png"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS))));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener("fetch",e=>{
 const u=new URL(e.request.url);
 if(u.pathname.startsWith("/api/"))return;
 e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request).then(resp=>{const copy=resp.clone();if(e.request.method==="GET"&&resp.ok)caches.open(CACHE).then(c=>c.put(e.request,copy));return resp})))
});
