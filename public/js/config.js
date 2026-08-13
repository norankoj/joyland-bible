// ✅ Supabase 설정값을 여기에 입력하세요
// Supabase 대시보드 > Project Settings > API 에서 복사
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
