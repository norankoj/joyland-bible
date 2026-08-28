-- =============================================
-- 출석 기록 삭제 권한 수정 (Supabase SQL Editor에서 실행)
-- =============================================
-- 문제: 선생님 페이지(teacher.html)는 로그인하지 않은 anon 역할로 동작하는데
--       joyland_attendance_delete 정책이 authenticated 만 허용하고 있어
--       "출석 체크 해제 후 저장"이 오류 없이 조용히 실패함.
-- 조치: 읽기/생성/수정과 동일하게 anon 삭제를 허용.

drop policy if exists "joyland_attendance_delete" on joyland_attendance;
create policy "joyland_attendance_delete" on joyland_attendance for delete using (true);
