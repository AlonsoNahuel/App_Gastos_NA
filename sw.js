/* ═══════════════════════════════════════════════════════════
   Service worker — hace que la app se pueda instalar y abra rápido.

   Reglas:
   - Supabase (datos y login) NUNCA pasa por el caché: siempre va a la red.
   - Archivos propios (HTML, CSS, íconos): primero la red, y si no hay
     conexión (o tarda más de 4 s) se usa la copia guardada. Así, con
     internet siempre ves la última versión publicada.
   - Librerías y fuentes de CDN: se sirven del caché y se actualizan
     en segundo plano.

   Si cambiás la lista de PRECACHE, subí la VERSION para limpiar lo viejo.
   ═══════════════════════════════════════════════════════════ */
const VERSION = "v1";
const CACHE = `gastos-${VERSION}`;

const PRECACHE = [
  "./",
  "./index.html",
  "./styles.css",
  "./logo.png",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/favicon-32.png",
];
const CDN = [
  "https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2",
];
const HOSTS_CDN = ["cdn.jsdelivr.net", "fonts.googleapis.com", "fonts.gstatic.com"];

self.addEventListener("install", e => {
  e.waitUntil((async () => {
    const c = await caches.open(CACHE);
    await c.addAll(PRECACHE);
    // Las librerías se intentan guardar, pero si el CDN falla no se frena la instalación
    await Promise.all(CDN.map(u => c.add(u).catch(() => {})));
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", e => {
  e.waitUntil((async () => {
    const claves = await caches.keys();
    await Promise.all(claves.filter(k => k.startsWith("gastos-") && k !== CACHE).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  if (url.origin === self.location.origin) {
    e.respondWith(primeroRed(req));
  } else if (HOSTS_CDN.includes(url.hostname)) {
    e.respondWith(cacheYActualizar(req, e));
  }
  // Cualquier otra cosa (Supabase incluido) no se toca: va directo a la red.
});

async function primeroRed(req) {
  const c = await caches.open(CACHE);
  try {
    const res = await conTimeout(fetch(req), 4000);
    if (res.ok) c.put(req, res.clone());
    return res;
  } catch {
    const copia = await c.match(req, { ignoreSearch: true })
      || (req.mode === "navigate" && await c.match("./index.html"));
    if (copia) return copia;
    return new Response("Sin conexión", { status: 503, headers: { "Content-Type": "text/plain; charset=utf-8" } });
  }
}

async function cacheYActualizar(req, e) {
  const c = await caches.open(CACHE);
  const copia = await c.match(req);
  const red = fetch(req).then(res => {
    if (res.ok || res.type === "opaque") c.put(req, res.clone());
    return res;
  });
  if (copia) { e.waitUntil(red.catch(() => {})); return copia; }
  return red;
}

function conTimeout(promesa, ms) {
  return new Promise((ok, mal) => {
    const t = setTimeout(() => mal(new Error("timeout")), ms);
    promesa.then(r => { clearTimeout(t); ok(r); }, err => { clearTimeout(t); mal(err); });
  });
}
