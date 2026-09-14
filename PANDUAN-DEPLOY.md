# Panduan Deploy — GHK2AAB3 Basis Data (GitHub Pages + Supabase)

Paket di folder ini sudah siap dipublikasikan sebagai situs statis dengan pencatatan aktivitas mahasiswa otomatis. Ikuti langkah berikut sekali di awal.

> ⚠️ **Penting soal privasi.** Folder ini **sengaja tidak berisi** `panduan-dosen.md` dan `dosen/kunci_asesmen*.sql` (kunci jawaban), karena repo GitHub gratis untuk GitHub Pages bersifat publik — siapa pun bisa membukanya. Simpan dua berkas itu terpisah (mis. di Google Drive/laptop pribadi), **jangan** commit ke repo `sandikala/basisdata`.

## 1. Buat project Supabase gratis

1. Buka [supabase.com](https://supabase.com) → **Start your project** → **Sign in with GitHub**, pakai akun GitHub yang sama (`sandikala`).
2. **New project**: beri nama misalnya `basisdata`, buat password database (simpan baik-baik), pilih region terdekat (mis. Singapore), plan **Free**.
3. Tunggu ±2 menit sampai project siap.

Sebelum lanjut, cek juga isi `KELAS_LIST` di `shared/config.js` (default `["4","5"]`) — inilah yang muncul sebagai pilihan dropdown kelas saat mahasiswa login. Tambah angka lain kapan saja dengan mengedit array itu; mahasiswa juga bisa pilih **"Lainnya…"** di dropdown untuk mengetik kelas sendiri kalau belum ada di daftar.

## 2. Jalankan skema database

1. Di dashboard Supabase, buka **SQL Editor** → **New query**.
2. Salin seluruh isi `supabase/schema.sql` dari paket ini, tempel, lalu **Run**.
3. Ini membuat tabel `log_aktivitas`, `nilai_manual`, `bobot_nilai`, beserta tiga *view* rekap nilai, lengkap dengan Row Level Security (mahasiswa hanya bisa menulis, tidak bisa membaca data mahasiswa lain).
4. **Sudah pernah menjalankan skema versi sebelumnya (tanpa kolom kelas)?** Tidak masalah — jalankan ulang saja seluruh isi `schema.sql` yang baru. Baris `alter table ... add column if not exists kelas ...` dan `create or replace view ...` di dalamnya aman dijalankan berkali-kali dan tidak menghapus data yang sudah ada.

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

Pilih salah satu cara di bawah, sesuai kenyamanan.

### 5a. Cara termudah tanpa command line: upload lewat browser

1. Buka `https://github.com/sandikala/basisdata`. Kalau repo belum ada, buat dulu: **New repository** → nama `basisdata` → Public → **Create repository**.
2. Klik **Add file → Upload files**.
3. Seret **seluruh isi** folder paket ini (bukan foldernya sendiri — masuk dulu ke dalamnya) ke kotak upload: `index.html`, `p01.html`…`p16.html`, `dashboard.html`, folder `shared/`, `supabase/`, `mahasiswa/`, `wayground/`, `bank-soal-wayground-semua.xlsx`. Browser bisa upload sub-folder sekaligus (drag folder, bukan hanya file, biasanya didukung Chrome/Edge terbaru).
4. Tulis pesan commit, misalnya "Setup situs interaktif + pelacakan aktivitas", lalu **Commit changes**.
5. Kalau repo sudah berisi file lama dengan nama sama, GitHub akan menimpanya secara otomatis saat upload — tidak perlu menghapus manual dulu.

Kekurangan cara ini: kalau nanti ada revisi deck (mis. perbaikan typo), harus upload ulang manual. Cocok untuk sekali setup di awal semester.

### 5b. Cara command line (git)

Sejak Agustus 2021, GitHub **tidak lagi menerima password akun** untuk `git push` — wajib pakai **Personal Access Token (PAT)** atau SSH key. Siapkan dulu token:

1. GitHub → foto profil (kanan atas) → **Settings → Developer settings → Personal access tokens → Tokens (classic)** → **Generate new token (classic)**.
2. Beri nama bebas, centang scope **repo**, atur masa berlaku (mis. 90 hari), **Generate token**.
3. **Salin token itu sekarang juga** — hanya ditampilkan sekali. Simpan sementara di catatan aman.

Lalu, dari terminal, masuk ke folder paket ini (yang berisi `index.html`, `p01.html`…`p16.html`, `shared/`, `dashboard.html`, dll — **tanpa** `panduan-dosen.md`/`dosen/`):

```bash
git init
git add .
git commit -m "Setup situs interaktif + pelacakan aktivitas"
git branch -M main
git remote add origin https://github.com/sandikala/basisdata.git
git push -u origin main
```

Saat diminta **username**, isi username GitHub (`sandikala`). Saat diminta **password**, tempel **token PAT** dari langkah di atas (bukan password akun).

**Kalau repo `sandikala/basisdata` sudah ada isinya** (mis. dari upload zip lama) dan `git push` ditolak dengan pesan *"rejected... fetch first"* atau *"Updates were rejected"*, itu artinya riwayat di GitHub dan di komputer kamu berbeda. Dua opsi:

- **Kalau isi lama di GitHub sudah tidak dipakai lagi** (paket baru ini menggantikannya sepenuhnya): paksa timpa dengan
  ```bash
  git push -u origin main --force
  ```
  Gunakan opsi ini hanya kalau yakin tidak ada file penting di repo lama yang belum dibackup.
- **Kalau ingin menggabungkan riwayat lama**:
  ```bash
  git pull origin main --allow-unrelated-histories
  # selesaikan konflik file kalau ada, lalu:
  git push -u origin main
  ```

### 5c. Alternatif tanpa terminal: GitHub Desktop

Kalau tidak terbiasa command line, install [GitHub Desktop](https://desktop.github.com), login dengan akun GitHub yang sama, **File → Add local repository** arahkan ke folder paket ini, isi ringkasan commit, klik **Commit to main**, lalu **Publish repository** (atau **Push origin** kalau repo remote sudah ada). Autentikasi token ditangani otomatis oleh aplikasinya.

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
