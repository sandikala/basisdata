# Panduan Deploy — GHK2AAB3 Basis Data (GitHub Pages + Supabase)

Paket di folder ini sudah siap dipublikasikan sebagai situs statis dengan pencatatan aktivitas mahasiswa otomatis. Ikuti langkah berikut sekali di awal.

> ⚠️ **Penting soal privasi.** Folder ini **sengaja tidak berisi** `panduan-dosen.md` dan `dosen/kunci_asesmen*.sql` (kunci jawaban), karena repo GitHub gratis untuk GitHub Pages bersifat publik — siapa pun bisa membukanya. Simpan dua berkas itu terpisah (mis. di Google Drive/laptop pribadi), **jangan** commit ke repo `sandikala/basisdata`.

## 1. Buat project Supabase gratis

1. Buka [supabase.com](https://supabase.com) → **Start your project** → **Sign in with GitHub**, pakai akun GitHub yang sama (`sandikala`).
2. **New project**: beri nama misalnya `basisdata`, buat password database (simpan baik-baik), pilih region terdekat (mis. Singapore), plan **Free**.
3. Tunggu ±2 menit sampai project siap.

## 2. Jalankan skema database

1. Di dashboard Supabase, buka **SQL Editor** → **New query**.
2. Salin seluruh isi `supabase/schema.sql` dari paket ini, tempel, lalu **Run**.
3. Ini membuat tabel `log_aktivitas`, `nilai_manual`, `bobot_nilai`, beserta tiga *view* rekap nilai, lengkap dengan Row Level Security (mahasiswa hanya bisa menulis, tidak bisa membaca data mahasiswa lain).

## 3. Kunci akses supaya hanya dosen yang bisa lihat nilai

1. **Authentication → Providers → Email** → matikan **"Allow new users to sign up"**. Ini mencegah mahasiswa membuat akun sendiri dan ikut membaca rekap nilai.
2. **Authentication → Users → Add user** → buat satu akun dosen (email + password). Akun inilah yang dipakai login di `dashboard.html`.

## 4. Ambil kredensial Supabase

1. **Project Settings → API**.
2. Salin **Project URL** dan **anon public key**.
3. Buka `shared/config.js` di paket ini, isi:
   ```js
   window.LMS_CONFIG = {
     SUPABASE_URL: "https://xxxxxxxx.supabase.co",
     SUPABASE_ANON_KEY: "eyJhbGciOi..."
   };
   ```
   Nilai ini aman ditaruh di repo publik karena dilindungi Row Level Security dari langkah 2.

## 5. Push ke GitHub

Dari folder paket ini (yang sudah berisi `index.html`, `p01.html`…`p16.html`, `shared/`, `dashboard.html`, dll — **tanpa** `panduan-dosen.md`/`dosen/`):

```bash
git init
git add .
git commit -m "Setup situs interaktif + pelacakan aktivitas"
git branch -M main
git remote add origin https://github.com/sandikala/basisdata.git
git push -u origin main
```

Kalau repo `sandikala/basisdata` sudah ada isinya (mis. dari zip lama), samakan dulu dengan `git pull --rebase` atau upload manual lewat menu **Add file → Upload files** di GitHub.

## 6. Aktifkan GitHub Pages (gratis)

1. Di repo GitHub → **Settings → Pages**.
2. **Source**: pilih branch `main`, folder `/ (root)` → **Save**.
3. Tunggu 1–2 menit. Situs akan aktif di:
   `https://sandikala.github.io/basisdata/`

## 7. Uji coba

1. Buka `https://sandikala.github.io/basisdata/` di HP/laptop → klik salah satu pertemuan.
2. Muncul gerbang identitas: isi NIM + nama (mode mahasiswa) atau pilih **Mode Dosen** kalau kamu presentasi di depan kelas (aktivitas mode dosen tidak direkam).
3. Jawab satu kuis atau klik +1 pada polling di deck itu.
4. Buka `https://sandikala.github.io/basisdata/dashboard.html`, login dengan akun dosen dari langkah 3 → tab **Log Aktivitas Mentah** harus menampilkan baris yang barusan tercatat.

## 8. Alur penilaian akhir

- **Partisipasi & kuis** dihitung **otomatis** dari `log_aktivitas` (akurasi kuis + keikutsertaan polling/word cloud/playground), lihat tab **Rekap Nilai Akhir**.
- **Asesmen 1/2/3** tetap dinilai manual oleh dosen (studi kasus, presentasi/demo, ujian komprehensif) — masukkan skornya di tab **Input Nilai Asesmen** pada dashboard; sistem otomatis menggabungkannya dengan partisipasi sesuai bobot pada tab **Bobot Komponen**.
- Nilai akhir bisa diunduh sebagai CSV dari tab **Rekap Nilai Akhir** untuk diinput ke sistem akademik kampus.

## Catatan teknis & batasan

- Pelacakan berbasis identitas yang **diketik sendiri oleh mahasiswa** (bukan login resmi kampus) — cukup untuk keperluan pembelajaran/partisipasi, tapi tidak seaman SSO kampus. Kalau butuh identitas terverifikasi, tambahkan integrasi SSO/Google Workspace kampus lewat Supabase Auth (bisa dibantu lebih lanjut).
- Rekap partisipasi dihitung sederhana (60% akurasi kuis + 40% keterlibatan). Formulanya ada di `supabase/schema.sql` (view `rekap_partisipasi`) dan bisa diubah sesuai selera dengan mengedit `create or replace view`.
- Playground SQL dan sebagian besar interaksi tetap berjalan offline (memakai SQLite di browser); pencatatan ke Supabase butuh internet. Jika mahasiswa offline, aktivitas hari itu tidak masuk log — tidak ada antrian pengiriman ulang otomatis.
- Supabase Free tier: 500 MB database, 2 GB bandwidth/bulan, project idle otomatis pause setelah 7 hari tanpa aktivitas (tinggal buka dashboard Supabase untuk mengaktifkan lagi). Untuk satu kelas dalam satu semester ini jauh lebih dari cukup.
