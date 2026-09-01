-- =============================================
-- 통독 스케줄 (Supabase SQL Editor에서 전체 실행)
-- =============================================
-- 저학년(1~3학년) / 고학년(4~6학년) 별로 날짜마다 읽을 본문을 저장합니다.
-- 학부모 화면에서 "이번 주 읽을 본문"으로 보여집니다.
-- 다음 달 스케줄은 관리자 페이지 > 통독 스케줄 에서 엑셀로 올릴 수 있습니다.

create table if not exists joyland_schedule (
  id          uuid primary key default gen_random_uuid(),
  read_date   date not null,
  grade_group text not null check (grade_group in ('low', 'high')),  -- low=저학년(1~3), high=고학년(4~6)
  passage     text not null,                                          -- 예: '사무엘하 17장', '화요모임'
  created_at  timestamptz default now(),
  unique (read_date, grade_group)
);

create index if not exists joyland_schedule_date_idx on joyland_schedule (read_date);

alter table joyland_schedule enable row level security;

drop policy if exists "joyland_schedule_read"   on joyland_schedule;
drop policy if exists "joyland_schedule_insert" on joyland_schedule;
drop policy if exists "joyland_schedule_update" on joyland_schedule;
drop policy if exists "joyland_schedule_delete" on joyland_schedule;

-- 누구나 읽기 (학부모 화면), 관리자만 쓰기
create policy "joyland_schedule_read"   on joyland_schedule for select using (true);
create policy "joyland_schedule_insert" on joyland_schedule for insert with check (auth.role() = 'authenticated');
create policy "joyland_schedule_update" on joyland_schedule for update using (auth.role() = 'authenticated');
create policy "joyland_schedule_delete" on joyland_schedule for delete using (auth.role() = 'authenticated');


-- ─────────────────────────────────────────────
-- 9월 스케줄 (다시 실행해도 안전하도록 덮어쓰기)
-- ─────────────────────────────────────────────
insert into joyland_schedule (read_date, grade_group, passage) values
  ('2026-09-01','high','화요모임'),
  ('2026-09-01','low','화요모임'),
  ('2026-09-02','high','창세기 39-41장'),
  ('2026-09-02','low','사무엘하 17장'),
  ('2026-09-03','high','창세기 42-44장'),
  ('2026-09-03','low','사무엘하 18장'),
  ('2026-09-04','high','창세기 45-47장'),
  ('2026-09-04','low','사무엘하 19장'),
  ('2026-09-05','high','창세기 48-50장'),
  ('2026-09-05','low','사무엘하 20장'),
  ('2026-09-06','high','출애굽기 1장'),
  ('2026-09-06','low','사무엘하 21장'),
  ('2026-09-07','high','출애굽기 2-4장'),
  ('2026-09-07','low','사무엘하 22장'),
  ('2026-09-08','high','화요모임'),
  ('2026-09-08','low','화요모임'),
  ('2026-09-09','high','출애굽기 5-7장'),
  ('2026-09-09','low','사무엘하 23장'),
  ('2026-09-10','high','출애굽기 8-10장'),
  ('2026-09-10','low','사무엘하 24장'),
  ('2026-09-11','high','출애굽기 11-13장'),
  ('2026-09-11','low','열왕기상 1장'),
  ('2026-09-12','high','출애굽기 14-16장'),
  ('2026-09-12','low','열왕기상 2장'),
  ('2026-09-13','high','출애굽기 17장'),
  ('2026-09-13','low','열왕기상 3장'),
  ('2026-09-14','high','출애굽기 18-20장'),
  ('2026-09-14','low','열왕기상 4장'),
  ('2026-09-15','high','화요모임'),
  ('2026-09-15','low','화요모임'),
  ('2026-09-16','high','출애굽기 21-23장'),
  ('2026-09-16','low','열왕기상 5장'),
  ('2026-09-17','high','출애굽기 24-26장'),
  ('2026-09-17','low','열왕기상 6장'),
  ('2026-09-18','high','출애굽기 27-29장'),
  ('2026-09-18','low','열왕기상 7장'),
  ('2026-09-19','high','출애굽기 30-32장'),
  ('2026-09-19','low','열왕기상 8장'),
  ('2026-09-20','high','출애굽기 33장'),
  ('2026-09-20','low','열왕기상 9장'),
  ('2026-09-21','high','출애굽기 34-36장'),
  ('2026-09-21','low','열왕기상 10장'),
  ('2026-09-22','high','화요모임'),
  ('2026-09-22','low','화요모임'),
  ('2026-09-23','high','출애굽기 37-39장'),
  ('2026-09-23','low','열왕기상 11장'),
  ('2026-09-24','high','출애굽기 40장'),
  ('2026-09-24','low','열왕기상 12장'),
  ('2026-09-25','high','민수기 1-3장'),
  ('2026-09-25','low','열왕기상 13장'),
  ('2026-09-26','high','민수기 4-6장'),
  ('2026-09-26','low','열왕기상 14장'),
  ('2026-09-27','high','민수기 7장'),
  ('2026-09-27','low','열왕기상 15장'),
  ('2026-09-28','high','민수기 8-10장'),
  ('2026-09-28','low','열왕기상 16장'),
  ('2026-09-29','high','화요모임'),
  ('2026-09-29','low','화요모임'),
  ('2026-09-30','high','민수기 11-13장'),
  ('2026-09-30','low','열왕기상 17장')
on conflict (read_date, grade_group) do update set passage = excluded.passage;
