-- =============================================
-- 쌍둥이(같은 전화·같은 생일) 등록/수정 허용 (Supabase SQL Editor에서 실행)
-- =============================================
-- [문제]
--  PIN = 전화 뒤4자리 + 생일 이라서 쌍둥이는 PIN 이 같습니다.
--  이 앱은 원래 "같은 PIN 으로 로그인 → 자녀 선택 화면"으로 이를 지원하고,
--  실제로 이미 쌍둥이 가정이 등록되어 있습니다.
--  그런데 joyland_class_save_student 가 PIN 중복을 오류로 막고 있어서
--   · 선생님이 쌍둥이를 새로 등록할 수 없고
--   · 기존 쌍둥이의 정보를 "수정"만 하려 해도 오류가 났습니다.
--     (자기 자신을 제외해도 형제가 같은 PIN 이라 중복으로 걸림)
--
-- [조치] PIN 중복 검사를 제거합니다. 중복은 로그인 시 자녀 선택으로 해결됩니다.

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
as $$
declare
  v_digits text;
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
  if coalesce(p_birthday, '') !~ '^[0-9]{4}$' then
    raise exception '생일은 MMDD 4자리로 입력해주세요. (예: 0305)';
  end if;
  v_pin := right(v_digits, 4) || p_birthday;

  -- ※ PIN 중복 검사 없음 — 쌍둥이는 같은 PIN 을 공유하며,
  --    로그인 시 '어떤 자녀인가요?' 선택 화면으로 구분됩니다.

  if p_id is null then
    insert into joyland_students (name, grade, gender, phone, birthday, pin, parent_name, class_name, active)
    values (trim(p_name), p_grade, p_gender, p_phone, p_birthday, v_pin, p_parent_name, p_class, true)
    returning id into v_id;
  else
    update joyland_students s
       set name = trim(p_name), grade = p_grade, gender = p_gender,
           phone = p_phone, birthday = p_birthday, pin = v_pin,
           parent_name = p_parent_name
     where s.id = p_id and s.class_name = p_class
    returning s.id into v_id;

    if v_id is null then
      raise exception '우리 반 학생이 아니거나 존재하지 않습니다.';
    end if;
  end if;

  return v_id;
end;
$$;

revoke all on function joyland_class_save_student(text,text,uuid,text,text,text,text,text,text) from public, anon, authenticated;
grant execute on function joyland_class_save_student(text,text,uuid,text,text,text,text,text,text) to anon, authenticated;
