-- joyland_classes에 학년·선생님 컬럼 추가 (Supabase SQL Editor에서 실행)
ALTER TABLE joyland_classes
  ADD COLUMN IF NOT EXISTS grade        text,
  ADD COLUMN IF NOT EXISTS teacher_name text;
