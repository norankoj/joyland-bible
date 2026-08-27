-- closing_weeks 컬럼 추가 (Supabase SQL Editor에서 실행)
ALTER TABLE joyland_semesters
  ADD COLUMN IF NOT EXISTS closing_weeks integer[] DEFAULT '{}';
