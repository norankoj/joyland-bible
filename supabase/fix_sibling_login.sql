-- =============================================
-- 형제·자매 묶어서 로그인 (Supabase SQL Editor에서 전체 실행)
-- =============================================
-- [기존] PIN(전화 뒤4자리+생일)이 완전히 같은 경우 = 쌍둥이만 함께 나왔습니다.
-- [변경] 보호자 이름과 전화번호가 같으면 형제로 보고 모두 함께 보여줍니다.
--        → 형의 PIN 으로 들어와도 동생이 같이 나오고,
--          '다른 자녀 선택'으로 오갈 수 있습니다.
--
-- 전화번호는 하이픈 유무와 상관없이 숫자만 비교합니다.
-- 보호자 이름이 비어 있는 경우끼리도 같은 값으로 취급합니다.

create or replace function joyland_login_pin(p_pin text)
returns table (id uuid, name text, grade text)
language sql
security definer
set search_path = public
as $fn$
  with me as (
    select regexp_replace(coalesce(s.phone, ''), '[^0-9]', '', 'g') as ph,
           coalesce(s.parent_name, '')                              as pn
    from joyland_students s
    where s.pin = p_pin and s.active
    limit 1
  )
  select s.id, s.name, s.grade
  from joyland_students s, me
  where s.active
    and regexp_replace(coalesce(s.phone, ''), '[^0-9]', '', 'g') = me.ph
    and coalesce(s.parent_name, '') = me.pn
  order by s.grade, s.name
  limit 10;
$fn$;

revoke all on function joyland_login_pin(text) from public, anon, authenticated;
grant execute on function joyland_login_pin(text) to anon, authenticated;
