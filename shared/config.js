// ============================================================
// KONFIGURASI SUPABASE
// Isi dua nilai di bawah ini setelah membuat project di supabase.com
// (Project Settings -> API -> "Project URL" dan "anon public" key)
//
// Nilai ini AMAN ditaruh di repo publik selama Row Level Security (RLS)
// sudah diaktifkan sesuai supabase/schema.sql — anon key hanya boleh
// INSERT log aktivitas, tidak bisa membaca data mahasiswa lain.
// ============================================================
window.LMS_CONFIG = {
  SUPABASE_URL: "https://shaewuwsrhkmzrxbwbyd.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_Ld9CwVYVigRIgZCRMd1LSQ_A0sm_0aR",
  // Daftar kelas yang tampil di dropdown saat mahasiswa login.
  // Tambah/kurangi angka sesuai kebutuhan (mis. tambah "6" kalau ada kelas baru).
  KELAS_LIST: ["4", "5"]
};
