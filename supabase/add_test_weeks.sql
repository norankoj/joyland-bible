-- 테스트 주차 컬럼 추가 (Supabase SQL Editor에서 실행)
-- 학부모님이 미리 체크를 연습해볼 수 있는 주차입니다.
-- 방학/개강/종강과 달리 체크는 가능하지만, 시상 계산에서는 제외됩니다.
ALTER TABLE joyland_semesters
  ADD COLUMN IF NOT EXISTS test_weeks integer[] DEFAULT '{}';
