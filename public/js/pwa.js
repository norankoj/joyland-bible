/**
 * 앱처럼 설치하기 (PWA)
 *  - 각 페이지 <head> 에서 window.JOYLAND_APP = 'admin' | 'teacher' | 'home' 지정 후 이 파일을 불러옵니다.
 *  - 안드로이드/크롬: 설치 버튼 표시
 *  - 아이폰/사파리: 공유 → 홈 화면에 추가 안내
 */
(function () {
  const APP = window.JOYLAND_APP || 'home';
  const NAME = { admin: '관리자', teacher: '출석 체크', home: '조이랜드 통독' }[APP];
  const DISMISS_KEY = `joyland_pwa_dismissed_${APP}`;

  // ── 서비스워커 등록 ──
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js').catch(() => {});
    });
  }

  const isStandalone = () =>
    window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;

  const isIOS = () =>
    /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  /**
   * 아이폰은 브라우저마다 '홈 화면에 추가' 위치가 달라서 안내를 다르게 해야 합니다.
   * 카톡·네이버 등 앱 안에 내장된 브라우저는 아예 추가가 불가능합니다.
   */
  function iosBrowser() {
    const ua = navigator.userAgent;
    if (/KAKAOTALK/i.test(ua))              return { key: 'inapp', name: '카카오톡' };
    if (/NAVER|Whale/i.test(ua))            return { key: 'inapp', name: '네이버' };
    if (/Instagram|FBAN|FBAV|Line/i.test(ua)) return { key: 'inapp', name: '앱 내 브라우저' };
    if (/CriOS/i.test(ua))                  return { key: 'chrome', name: '크롬' };
    if (/EdgiOS/i.test(ua))                 return { key: 'chrome', name: '엣지' };
    if (/FxiOS/i.test(ua))                  return { key: 'firefox', name: '파이어폭스' };
    return { key: 'safari', name: '사파리' };
  }

  const IOS_GUIDE = {
    safari:  '아래 <b>공유</b> 버튼 → <b>홈 화면에 추가</b>',
    chrome:  '주소창 오른쪽 <b>공유</b> 버튼 → <b>홈 화면에 추가</b>',
    firefox: '오른쪽 아래 <b>≡</b> → <b>공유</b> → <b>홈 화면에 추가</b>',
    inapp:   '오른쪽 위 <b>⋯</b> → <b>다른 브라우저로 열기</b>(사파리·크롬) 후 추가해주세요'
  };

  // 이미 앱으로 실행 중이거나, 사용자가 닫았으면 표시하지 않음
  if (isStandalone() || localStorage.getItem(DISMISS_KEY) === '1') return;

  let deferredPrompt = null;

  function injectStyles() {
    if (document.getElementById('pwa-style')) return;
    const st = document.createElement('style');
    st.id = 'pwa-style';
    st.textContent = `
      .pwa-bar {
        position: fixed; left: 12px; right: 12px; bottom: 12px; z-index: 9500;
        background: #1E1248; color: #fff; border-radius: 16px;
        padding: 13px 15px; display: flex; align-items: center; gap: 11px;
        box-shadow: 0 12px 36px rgba(20,10,60,.35);
        font-family: 'Apple SD Gothic Neo','Noto Sans KR',sans-serif;
        animation: pwaUp .3s ease;
      }
      @keyframes pwaUp { from { transform: translateY(16px); opacity: 0 } to { transform: none; opacity: 1 } }
      .pwa-ic { width: 34px; height: 34px; border-radius: 9px; flex-shrink: 0; }
      .pwa-tx { flex: 1; min-width: 0; }
      .pwa-t { font-size: 13px; font-weight: 800; }
      .pwa-s { font-size: 11.5px; opacity: .78; margin-top: 2px; line-height: 1.45; }
      .pwa-btn {
        border: none; border-radius: 99px; padding: 9px 14px; cursor: pointer;
        font-family: inherit; font-size: 12.5px; font-weight: 800;
        background: #fff; color: #1E1248; flex-shrink: 0;
      }
      .pwa-x {
        border: none; background: none; color: rgba(255,255,255,.55);
        font-size: 20px; cursor: pointer; padding: 0 2px; line-height: 1; flex-shrink: 0;
      }
      .pwa-s b { color: #FFD580; font-weight: 800; }
      @media (max-width: 380px) { .pwa-t { font-size: 12.5px } .pwa-s { font-size: 11px } }
    `;
    document.head.appendChild(st);
  }

  function showBar(mode) {
    if (document.querySelector('.pwa-bar')) return;
    injectStyles();
    const bar = document.createElement('div');
    bar.className = 'pwa-bar';
    let title = `${NAME} 앱으로 설치`;
    let sub = '홈 화면에 추가하면 앱처럼 열려요';
    if (mode === 'ios') {
      const b = iosBrowser();
      sub = IOS_GUIDE[b.key];
      if (b.key === 'inapp') title = `${NAME} — 사파리·크롬에서 설치해요`;
    }
    bar.innerHTML = `
      <img class="pwa-ic" src="/icons/icon-${APP}-192.png" alt="">
      <div class="pwa-tx">
        <div class="pwa-t">${title}</div>
        <div class="pwa-s">${sub}</div>
      </div>
      ${mode === 'prompt' ? '<button class="pwa-btn" id="pwaInstall">설치</button>' : ''}
      <button class="pwa-x" id="pwaClose" aria-label="닫기">&times;</button>
    `;
    document.body.appendChild(bar);

    document.getElementById('pwaClose').onclick = () => {
      localStorage.setItem(DISMISS_KEY, '1');
      bar.remove();
    };
    const btn = document.getElementById('pwaInstall');
    if (btn) btn.onclick = async () => {
      if (!deferredPrompt) return;
      bar.remove();
      deferredPrompt.prompt();
      await deferredPrompt.userChoice;
      deferredPrompt = null;
    };
  }

  // 안드로이드/크롬 — 설치 가능 시점에 버튼 노출
  window.addEventListener('beforeinstallprompt', e => {
    e.preventDefault();
    deferredPrompt = e;
    showBar('prompt');
  });

  // 아이폰 — 수동 안내 (약간의 지연 후)
  if (isIOS()) setTimeout(() => showBar('ios'), 2500);

  window.addEventListener('appinstalled', () => {
    localStorage.setItem(DISMISS_KEY, '1');
    document.querySelector('.pwa-bar')?.remove();
  });
})();
