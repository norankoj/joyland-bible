-- =============================================
-- 조이랜드 통독 계수 시스템 - Supabase 스키마
-- Supabase 대시보드 > SQL Editor에서 실행하세요
-- =============================================

-- 1. 학생 테이블
create table if not exists students (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  grade       text not null,
  gender      text not null,
  phone       text not null,
  birthday    text not null,       -- MMDD (예: 0305)
  pin         text not null unique, -- 전화뒤4자리 + 생일MMDD (예: 56780305)
  active      boolean default true,
  created_at  timestamptz default now()
);

-- 2. 학기 테이블
create table if not exists semesters (
  id               uuid primary key default gen_random_uuid(),
  year             integer not null,
  semester         integer not null,       -- 1 또는 2
  total_weeks      integer not null,
  first_check_date date not null,          -- 첫 번째 체크 화요일
  active           boolean default true,
  created_at       timestamptz default now()
);

-- 3. 통독 기록 테이블
create table if not exists records (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references students(id) on delete cascade,
  semester_id uuid references semesters(id) on delete cascade,
  week_num    integer not null,
  status      text not null check (status in ('done', 'partial')),
  checked_at  timestamptz default now(),
  unique (student_id, semester_id, week_num)  -- 주차당 1회만 체크
);

-- =============================================
-- Row Level Security (RLS) 설정
-- =============================================

alter table students enable row level security;
alter table semesters enable row level security;
alter table records enable row level security;

-- 학생: 누구나 읽기 (PIN 검증용), 인증된 관리자만 쓰기
create policy "students_read"   on students for select using (true);
create policy "students_write"  on students for insert with check (auth.role() = 'authenticated');
create policy "students_update" on students for update using (auth.role() = 'authenticated');
create policy "students_delete" on students for delete using (auth.role() = 'authenticated');

-- 학기: 누구나 읽기, 관리자만 쓰기
create policy "semesters_read"   on semesters for select using (true);
create policy "semesters_write"  on semesters for insert with check (auth.role() = 'authenticated');
create policy "semesters_update" on semesters for update using (auth.role() = 'authenticated');
create policy "semesters_delete" on semesters for delete using (auth.role() = 'authenticated');

-- 기록: 누구나 읽기/생성 (보호자 체크), 관리자만 수정·삭제
create policy "records_read"   on records for select using (true);
create policy "records_insert" on records for insert with check (true);
create policy "records_update" on records for update using (auth.role() = 'authenticated');
create policy "records_delete" on records for delete using (auth.role() = 'authenticated');
