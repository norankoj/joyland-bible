// Supabase 대시보드 > Project Settings > API 에서 복사
const SUPABASE_URL = "https://qdsajqulyqnsitdcevul.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkc2FqcXVseXFuc2l0ZGNldnVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2ODIzMDUsImV4cCI6MjA4ODI1ODMwNX0.BMZQLcSjXa1tq7QmnMAa8GdaAQ98nPsf0L6ZtrJSeG4";

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
