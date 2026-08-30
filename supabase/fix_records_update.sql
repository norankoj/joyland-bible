-- =============================================
-- 학부모가 통독 체크를 "수정"할 수 있도록 권한 수정
-- (Supabase SQL Editor에서 전체를 한 번에 실행하세요)
-- =============================================
-- [문제]
--  joyland_records 의 UPDATE 정책이 관리자(authenticated)에게만 열려 있습니다.
--    create policy "joyland_records_update" ... for update using (auth.role() = 'authenticated');
--  학부모 페이지는 로그인하지 않은 anon 으로 동작하므로
--   · 처음 체크(INSERT)는 되지만
--   · 완료 → 부분완료 로 "바꾸는" 순간 UPDATE 가 되어 아래 오류가 납니다.
--       42501: new row violates row-level security policy for table "joyland_records"
--  같은 성격의 joyland_attendance 는 이미 using (true) 로 열려 있어 정상 동작합니다.
--
-- [조치]
--  통독 기록 UPDATE 를 출석과 동일하게 허용합니다.
--  (같은 화요일 안에서는 학부모가 자유롭게 수정할 수 있어야 하는 요구사항)
--  DELETE 는 그대로 관리자 전용으로 둡니다.

drop policy if exists "joyland_records_update" on joyland_records;
create policy "joyland_records_update" on joyland_records
  for update using (true) with check (true);


-- ─────────────────────────────────────────────
-- 점검 중 생성된 임시 데이터 정리 (97주차 테스트 행)
-- 학기는 18주까지라 화면에는 보이지 않지만 함께 지웁니다.
-- ─────────────────────────────────────────────
delete from joyland_records   where week_num > 90;
delete from joyland_attendance where week_num > 90;
