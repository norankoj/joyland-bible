-- =============================================
-- 선생님의 "자기 반 명단 수정" 권한 (Supabase SQL Editor에서 실행)
-- =============================================
-- 선생님 페이지는 로그인하지 않은 anon 역할로 동작하므로
-- joyland_students 에 직접 쓰기 권한을 주면 누구나 전교생을 지울 수 있습니다.
-- 따라서 "반 비밀번호를 서버에서 검증하는" SECURITY DEFINER 함수로만 수정하게 합니다.
-- → 자기 반(p_class) 학생만, 비밀번호가 맞을 때만 변경 가능합니다.
--
-- ⚠ 선행 조건: supabase/fix_security.sql 을 먼저 실행해두는 것을 권장합니다.
-- ※ 함수 본문은 $$ 대신 $fn$ 으로 감쌉니다. 본문 안에 $ 기호가 있으면
--   $$ 가 조기 종료되어 "unterminated dollar-quoted string" 오류가 납니다.


-- ─────────────────────────────────────────────
-- 공통: 반 비밀번호 검증
-- ─────────────────────────────────────────────
create or replace function joyland_assert_class(p_class text, p_password text)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if not exists (
    select 1 from joyland_classes c
    where c.name = p_class and c.password = p_password
  ) then
    raise exception '반 비밀번호가 올바르지 않습니다.' using errcode = '28000';
  end if;
end;
$fn$;
revoke all on function joyland_assert_class(text, text) from public, anon, authenticated;


-- ─────────────────────────────────────────────
-- 1. 자기 반 명단 조회 (수정 화면용 — 연락처 포함)
-- ─────────────────────────────────────────────
create or replace function joyland_class_students(p_class text, p_password text)
returns table (
  id uuid, name text, grade text, gender text,
  phone text, birthday text, parent_name text, active boolean
)
language plpgsql
security definer
set search_path = public
as $fn$
begin
  perform joyland_assert_class(p_class, p_password);
  return query
    select s.id, s.name, s.grade, s.gender, s.phone, s.birthday, s.parent_name, s.active
    from joyland_students s
    where s.class_name = p_class
    order by s.grade, s.name;
end;
$fn$;
revoke all on function joyland_class_students(text, text) from public, anon, authenticated;
grant execute on function joyland_class_students(text, text) to anon, authenticated;


-- ─────────────────────────────────────────────
-- 2. 학생 등록 / 수정 (p_id 가 null 이면 신규)
--    PIN = 전화 뒤 4자리 + 생일 MMDD
--    ※ PIN 중복 검사 없음 — 쌍둥이는 같은 PIN 을 공유하며,
--      로그인 시 '어떤 자녀인가요?' 선택 화면으로 구분됩니다.
-- ─────────────────────────────────────────────
create or replace function joyland_class_save_student(
  p_class       text,
  p_password    text,
  p_id          uuid,
  p_name        text,
  p_grade       text,
  p_gender      text,
  p_phone       text,
  p_birthday    text,
  p_parent_name text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_digits text;
  v_bday   text;
  v_pin    text;
  v_id     uuid;
begin
  perform joyland_assert_class(p_class, p_password);

  if coalesce(trim(p_name), '') = '' then
    raise exception '이름을 입력해주세요.';
  end if;

  v_digits := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  if length(v_digits) < 4 then
    raise exception '보호자 전화번호를 정확히 입력해주세요.';
  end if;

  v_bday := coalesce(p_birthday, '');
  if length(v_bday) <> 4 or v_bday ~ '[^0-9]' then
    raise exception '생일은 MMDD 4자리 숫자로 입력해주세요. (예: 0305)';
  end if;

  v_pin := right(v_digits, 4) || v_bday;

  if p_id is null then
    insert into joyland_students
      (name, grade, gender, phone, birthday, pin, parent_name, class_name, active)
    values
      (trim(p_name), p_grade, p_gender, p_phone, v_bday, v_pin, p_parent_name, p_class, true)
    returning id into v_id;
  else
    -- 다른 반 학생을 건드리지 못하도록 class_name 조건 필수
    update joyland_students s
       set name        = trim(p_name),
           grade       = p_grade,
           gender      = p_gender,
           phone       = p_phone,
           birthday    = v_bday,
           pin         = v_pin,
           parent_name = p_parent_name
     where s.id = p_id and s.class_name = p_class
    returning s.id into v_id;

    if v_id is null then
      raise exception '우리 반 학생이 아니거나 존재하지 않습니다.';
    end if;
  end if;

  return v_id;
end;
$fn$;
revoke all on function joyland_class_save_student(text,text,uuid,text,text,text,text,text,text)
  from public, anon, authenticated;
grant execute on function joyland_class_save_student(text,text,uuid,text,text,text,text,text,text)
  to anon, authenticated;


-- ─────────────────────────────────────────────
-- 3. 학생 비활성화 / 복원
--    (기록 보존을 위해 완전 삭제가 아닌 active 플래그만 변경)
-- ─────────────────────────────────────────────
create or replace function joyland_class_set_active(
  p_class text, p_password text, p_id uuid, p_active boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $fn$
declare v_id uuid;
begin
  perform joyland_assert_class(p_class, p_password);
  update joyland_students s set active = p_active
   where s.id = p_id and s.class_name = p_class
  returning s.id into v_id;
  if v_id is null then
    raise exception '우리 반 학생이 아니거나 존재하지 않습니다.';
  end if;
  return true;
end;
$fn$;
revoke all on function joyland_class_set_active(text,text,uuid,boolean) from public, anon, authenticated;
grant execute on function joyland_class_set_active(text,text,uuid,boolean) to anon, authenticated;
