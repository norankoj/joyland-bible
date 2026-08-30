/**
 * 조이랜드 서비스워커
 *
 * 설계 원칙
 *  - 데이터(Supabase)는 절대 캐시하지 않습니다. 항상 최신 값을 봐야 하므로.
 *  - 화면 파일은 "네트워크 우선" — 새 버전이 배포되면 즉시 반영됩니다.
 *    인터넷이 끊겼을 때만 캐시본을 보여줍니다.
 *  - 아이콘 등 정적 자원만 캐시 우선.
 */
const VERSION = 'joyland-v1';
const SHELL = `${VERSION}-shell`;
const ASSET = `${VERSION}-asset`;

// 오프라인일 때 최소한 열리도록 미리 받아두는 파일
const PRECACHE = ['/', '/home', '/teacher', '/admin', '/js/config.js'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(SHELL)
      .then(c => Promise.allSettled(PRECACHE.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => !k.startsWith(VERSION)).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // GET 이 아니거나 다른 도메인(Supabase, CDN)이면 서비스워커가 관여하지 않음
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;

  // 아이콘·매니페스트 → 캐시 우선
  if (url.pathname.startsWith('/icons/') || url.pathname.endsWith('.json')) {
    event.respondWith(
      caches.match(request).then(hit =>
        hit || fetch(request).then(res => {
          if (res.ok) { const copy = res.clone(); caches.open(ASSET).then(c => c.put(request, copy)); }
          return res;
        })
      )
    );
    return;
  }

  // 그 외(HTML/JS) → 네트워크 우선, 실패 시 캐시
  event.respondWith(
    fetch(request)
      .then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(SHELL).then(c => c.put(request, copy)); }
        return res;
      })
      .catch(() =>
        caches.match(request).then(hit =>
          hit || (request.mode === 'navigate' ? caches.match('/') : undefined)
        )
      )
  );
});
