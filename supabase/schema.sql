-- =============================================
-- 조이랜드 통독 계수 시스템 - Supabase 스키마
-- Supabase 대시보드 > SQL Editor에서 실행하세요
-- =============================================

-- 1. 학생 테이블
create table if not exists joyland_students (
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
create table if not exists joyland_semesters (
  id               uuid primary key default gen_random_uuid(),
  year             integer not null,
  semester         integer not null,       -- 1 또는 2
  total_weeks      integer not null,
  first_check_date date not null,          -- 첫 번째 체크 화요일
  break_weeks      integer[] default '{}', -- 방학/공휴일 주차 번호 배열 (예: {3,7,15})
  active           boolean default true,
  created_at       timestamptz default now()
);

-- 3. 통독 기록 테이블
create table if not exists joyland_records (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references joyland_students(id) on delete cascade,
  semester_id uuid references joyland_semesters(id) on delete cascade,
  week_num    integer not null,
  status      text not null check (status in ('done', 'partial')),
  checked_at  timestamptz default now(),
  unique (student_id, semester_id, week_num)  -- 주차당 1회만 체크
);

-- =============================================
-- Row Level Security (RLS) 설정
-- =============================================

alter table joyland_students enable row level security;
alter table joyland_semesters enable row level security;
alter table joyland_records enable row level security;

-- 학생: 누구나 읽기 (PIN 검증용), 인증된 관리자만 쓰기
create policy "joyland_students_read"   on joyland_students for select using (true);
create policy "joyland_students_write"  on joyland_students for insert with check (auth.role() = 'authenticated');
create policy "joyland_students_update" on joyland_students for update using (auth.role() = 'authenticated');
create policy "joyland_students_delete" on joyland_students for delete using (auth.role() = 'authenticated');

-- 학기: 누구나 읽기, 관리자만 쓰기
create policy "joyland_semesters_read"   on joyland_semesters for select using (true);
create policy "joyland_semesters_write"  on joyland_semesters for insert with check (auth.role() = 'authenticated');
create policy "joyland_semesters_update" on joyland_semesters for update using (auth.role() = 'authenticated');
create policy "joyland_semesters_delete" on joyland_semesters for delete using (auth.role() = 'authenticated');

-- 기록: 누구나 읽기/생성 (보호자 체크), 관리자만 수정·삭제
create policy "joyland_records_read"   on joyland_records for select using (true);
create policy "joyland_records_insert" on joyland_records for insert with check (true);
-- 학부모가 같은 날 안에서 완료↔부분완료를 바꿀 수 있어야 하므로 UPDATE 를 열어둡니다
create policy "joyland_records_update" on joyland_records for update using (true) with check (true);
create policy "joyland_records_delete" on joyland_records for delete using (auth.role() = 'authenticated');

-- =============================================
-- 출석 시스템 추가
-- =============================================

-- 학생 테이블에 반 컬럼 추가
alter table joyland_students add column if not exists class_name text;

-- 4. 반 테이블 (선생님 로그인용)
create table if not exists joyland_classes (
  id           uuid primary key default gen_random_uuid(),
  name         text not null unique,
  password     text not null,
  grade        text,                 -- 담당 학년 (예: '1학년')
  teacher_name text,                 -- 담당 선생님 이름
  created_at   timestamptz default now()
);

-- 5. 출석 기록 테이블
create table if not exists joyland_attendance (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references joyland_students(id) on delete cascade,
  semester_id uuid references joyland_semesters(id) on delete cascade,
  week_num    integer not null,
  status      text not null check (status in ('출석', '지각', '결석')),
  recorded_at timestamptz default now(),
  unique (student_id, semester_id, week_num)
);

-- RLS
alter table joyland_classes    enable row level security;
alter table joyland_attendance enable row level security;

-- 반: 누구나 읽기 (선생님 로그인 검증용), 관리자만 쓰기
create policy "joyland_classes_read"   on joyland_classes for select using (true);
create policy "joyland_classes_write"  on joyland_classes for insert with check (auth.role() = 'authenticated');
create policy "joyland_classes_update" on joyland_classes for update using (auth.role() = 'authenticated');
create policy "joyland_classes_delete" on joyland_classes for delete using (auth.role() = 'authenticated');

-- 출석: 누구나 읽기/생성/수정 (선생님 체크), 관리자만 삭제
create policy "joyland_attendance_read"   on joyland_attendance for select using (true);
create policy "joyland_attendance_insert" on joyland_attendance for insert with check (true);
create policy "joyland_attendance_update" on joyland_attendance for update using (true);
create policy "joyland_attendance_delete" on joyland_attendance for delete using (auth.role() = 'authenticated');
