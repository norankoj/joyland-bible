// Supabase 대시보드 > Project Settings > API 에서 복사
const SUPABASE_URL = "https://qdsajqulyqnsitdcevul.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkc2FqcXVseXFuc2l0ZGNldnVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2ODIzMDUsImV4cCI6MjA4ODI1ODMwNX0.BMZQLcSjXa1tq7QmnMAa8GdaAQ98nPsf0L6ZtrJSeG4";

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// =============================================
// 공통 설정 · 유틸  (home / teacher / admin 공용)
// =============================================

// 통독 체크 가능 요일 (0=일 1=월 2=화 3=수 4=목 5=금 6=토)
// ※ 실제 운영 = 2(화요일). 테스트할 때만 잠시 바꾸고 반드시 2로 되돌리세요.
const CHECK_DAY = 2;

const DAY_NAMES = ['일', '월', '화', '수', '목', '금', '토'];
const CHECK_DAY_LABEL = DAY_NAMES[CHECK_DAY];

/** 현재 시각을 KST 기준으로 (getUTC* 계열로 읽어야 함) */
function kstNow() {
  return new Date(Date.now() + 9 * 3600000);
}

/** 오늘이 체크 가능 요일인가 (KST 00:00 ~ 24:00) */
function isCheckDayKST() {
  return kstNow().getUTCDay() === CHECK_DAY;
}

/** 다음 체크일 안내 문구 */
function nextCheckDayLabel() {
  const kst = kstNow();
  const daysUntil = (CHECK_DAY - kst.getUTCDay() + 7) % 7 || 7;
  const next = new Date(kst);
  next.setUTCDate(kst.getUTCDate() + daysUntil);
  return `다음 체크일: ${next.getUTCMonth() + 1}월 ${next.getUTCDate()}일(${CHECK_DAY_LABEL})`;
}

/** 학기 기준 현재 주차 (학기 시작 전이면 0) */
function calcWeekNum(sem) {
  if (!sem) return 0;
  const diff = kstNow() - new Date(sem.first_check_date + 'T00:00:00Z');
  return diff < 0 ? 0 : Math.floor(diff / (7 * 86400000)) + 1;
}

/** w주차의 체크일 Date 객체 */
function weekCheckDateObj(sem, w) {
  const d = new Date(sem.first_check_date + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() + (w - 1) * 7);
  return d;
}

/** 8/25(화) 형식 */
function fmtShortDate(d) {
  return `${d.getUTCMonth() + 1}/${d.getUTCDate()}(${DAY_NAMES[d.getUTCDay()]})`;
}

/** 8월 25일(화) 형식 */
function fmtLongDate(d) {
  return `${d.getUTCMonth() + 1}월 ${d.getUTCDate()}일(${DAY_NAMES[d.getUTCDay()]})`;
}

/**
 * 시상·비율 계산에서 제외되는 주차 (방학·개강·종강·테스트)
 * ※ 테스트 주차는 체크는 가능하지만 시상에는 반영되지 않습니다.
 */
function specialWeekSet(sem) {
  if (!sem) return new Set();
  return new Set([
    ...(sem.break_weeks || []),
    ...(sem.opening_weeks || []),
    ...(sem.closing_weeks || []),
    ...(sem.test_weeks || [])
  ]);
}

/** 통독·출석 체크 자체가 불가능한 주차 (방학·개강·종강) */
function noCheckWeekSet(sem) {
  if (!sem) return new Set();
  return new Set([
    ...(sem.break_weeks || []),
    ...(sem.opening_weeks || []),
    ...(sem.closing_weeks || [])
  ]);
}

/** 주차 유형 라벨 — 없으면 null */
function weekTypeLabel(sem, w) {
  if (!sem) return null;
  if ((sem.opening_weeks || []).includes(w)) return '개강';
  if ((sem.closing_weeks || []).includes(w)) return '종강';
  if ((sem.break_weeks   || []).includes(w)) return '방학';
  if ((sem.test_weeks    || []).includes(w)) return '테스트';
  return null;
}
