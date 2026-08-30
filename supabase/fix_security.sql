-- =============================================
-- 🔴 보안 긴급 수정 (Supabase SQL Editor에서 실행)
-- =============================================
-- [문제]
--  정책이 `select using (true)` 라서, 브라우저에 공개된 anon 키만 있으면
--  누구나 아래 요청으로 전교생 개인정보를 통째로 내려받을 수 있습니다.
--    GET /rest/v1/joyland_students?select=*
--  → 이름 · 보호자 전화번호 · 생일 · 그리고 로그인 PIN 까지 전부 노출됩니다.
--    (PIN = 전화 뒤4자리+생일 이므로, 아무나 임의의 자녀로 로그인 가능)
--  같은 이유로 joyland_classes 의 선생님 비밀번호도 평문으로 조회됩니다.
--
-- [해결]
--  1) 로그인 검증을 서버측 함수(RPC)로 옮긴다 → PIN/비밀번호를 클라이언트로 내려보내지 않음
--  2) anon 에게는 민감 컬럼을 제외한 컬럼만 SELECT 권한을 준다 (컬럼 단위 GRANT)
--
-- ⚠ 실행 순서: 이 SQL을 먼저 실행한 뒤 최신 코드를 배포하세요.
-- ※ 함수 본문은 $$ 대신 $fn$ 으로 감쌉니다. 본문 안에 $ 기호가 있으면
--   $$ 가 조기 종료되어 "unterminated dollar-quoted string" 오류가 납니다.


-- ─────────────────────────────────────────────
-- 1. 학부모 PIN 로그인용 RPC
--    같은 PIN(쌍둥이)이면 여러 명이 반환되고, 화면에서 자녀를 선택합니다.
-- ─────────────────────────────────────────────
create or replace function joyland_login_pin(p_pin text)
returns table (id uuid, name text, grade text)
language sql
security definer
set search_path = public
as $fn$
  select s.id, s.name, s.grade
  from joyland_students s
  where s.pin = p_pin and s.active
  limit 10;
$fn$;

revoke all on function joyland_login_pin(text) from public, anon, authenticated;
grant execute on function joyland_login_pin(text) to anon, authenticated;


-- ─────────────────────────────────────────────
-- 2. 선생님 반 로그인용 RPC (비밀번호 대조를 서버에서 수행)
-- ─────────────────────────────────────────────
create or replace function joyland_login_class(p_name text, p_password text)
returns boolean
language sql
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from joyland_classes c
    where c.name = p_name and c.password = p_password
  );
$fn$;

revoke all on function joyland_login_class(text, text) from public, anon, authenticated;
grant execute on function joyland_login_class(text, text) to anon, authenticated;


-- ─────────────────────────────────────────────
-- 3. anon 은 민감 컬럼을 읽지 못하도록 컬럼 단위 권한 재설정
--    (RLS 는 행 단위라 컬럼을 못 가리므로 GRANT 로 제한)
-- ─────────────────────────────────────────────
revoke select on joyland_students from anon;
grant  select (id, name, grade, class_name, parent_name, active)
  on joyland_students to anon;
-- ※ 제외된 컬럼: phone, birthday, pin, gender  ← 더 이상 익명 조회 불가

revoke select on joyland_classes from anon;
grant  select (id, name, grade, teacher_name)
  on joyland_classes to anon;
-- ※ 제외된 컬럼: password  ← 더 이상 익명 조회 불가

-- 관리자(로그인 사용자)는 기존대로 전체 조회 가능
grant select on joyland_students to authenticated;
grant select on joyland_classes  to authenticated;


-- ─────────────────────────────────────────────
-- 4. 확인 — 아래 두 요청이 모두 permission denied 여야 정상입니다.
--   curl "$URL/rest/v1/joyland_students?select=pin"      -H "apikey: $ANON"
--   curl "$URL/rest/v1/joyland_classes?select=password"  -H "apikey: $ANON"
-- ─────────────────────────────────────────────
