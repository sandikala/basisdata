-- ================================================================
-- Skema Supabase — GHK2AAB3 Basis Data
-- Jalankan seluruh file ini sekali di Supabase: SQL Editor -> New query
-- ================================================================

-- 1) Log mentah semua aktivitas mahasiswa (kuis, polling, cloud, playground, waktu)
create table if not exists log_aktivitas (
  id bigint generated always as identity primary key,
  nim text not null,
  nama text,
  kelas text,
  pertemuan int not null,
  event_type text not null check (event_type in ('deck_open','deck_time','quiz','poll','cloud','playground')),
  detail jsonb not null default '{}'::jsonb,
  benar boolean,
  created_at timestamptz not null default now()
);
create index if not exists idx_log_nim on log_aktivitas (nim);
create index if not exists idx_log_kelas on log_aktivitas (kelas);
create index if not exists idx_log_pertemuan on log_aktivitas (pertemuan);
create index if not exists idx_log_event on log_aktivitas (event_type);

alter table log_aktivitas enable row level security;

-- Mahasiswa (anon key di web publik) HANYA boleh menambah log, tidak boleh membaca
drop policy if exists "anon insert log" on log_aktivitas;
create policy "anon insert log" on log_aktivitas
  for insert to anon
  with check (true);

-- Hanya akun dosen yang sudah login (authenticated) yang boleh membaca semua log
drop policy if exists "dosen baca log" on log_aktivitas;
create policy "dosen baca log" on log_aktivitas
  for select to authenticated
  using (true);

-- ================================================================
-- 2) Nilai asesmen (diisi manual oleh dosen: Asesmen 1/2/3 tidak
--    otomatis karena dinilai dari studi kasus/presentasi, bukan dari deck)
create table if not exists nilai_manual (
  nim text not null,
  nama text,
  kelas text,
  komponen text not null check (komponen in ('asesmen1','asesmen2','asesmen3')),
  skor numeric not null check (skor >= 0 and skor <= 100),
  catatan text,
  updated_at timestamptz not null default now(),
  primary key (nim, komponen)
);
alter table nilai_manual enable row level security;
drop policy if exists "dosen kelola nilai manual" on nilai_manual;
create policy "dosen kelola nilai manual" on nilai_manual
  for all to authenticated
  using (true) with check (true);

-- ================================================================
-- 3) Bobot komponen nilai (sesuaikan dengan RPS resmi mata kuliah)
create table if not exists bobot_nilai (
  komponen text primary key,
  bobot_persen numeric not null check (bobot_persen >= 0 and bobot_persen <= 100)
);
insert into bobot_nilai (komponen, bobot_persen) values
  ('partisipasi', 20), ('asesmen1', 25), ('asesmen2', 25), ('asesmen3', 30)
on conflict (komponen) do nothing;

alter table bobot_nilai enable row level security;
drop policy if exists "dosen kelola bobot" on bobot_nilai;
create policy "dosen kelola bobot" on bobot_nilai for all to authenticated using (true) with check (true);
drop policy if exists "publik baca bobot" on bobot_nilai;
create policy "publik baca bobot" on bobot_nilai for select to authenticated using (true);

-- ================================================================
-- 4) View rekap: partisipasi per pertemuan
drop view if exists rekap_partisipasi_pertemuan;
create or replace view rekap_partisipasi_pertemuan as
select
  nim, max(nama) as nama, max(kelas) as kelas, pertemuan,
  count(*) filter (where event_type = 'quiz') as jml_kuis,
  count(*) filter (where event_type = 'quiz' and benar) as kuis_benar,
  count(*) filter (where event_type = 'poll') as jml_poll,
  count(*) filter (where event_type = 'cloud') as jml_cloud,
  count(*) filter (where event_type = 'playground') as jml_playground,
  coalesce(sum((detail->>'durasi_detik')::numeric) filter (where event_type = 'deck_time'), 0) as total_detik
from log_aktivitas
group by nim, pertemuan;

-- 5) View rekap: skor partisipasi keseluruhan (0-100)
--    60% dari akurasi kuis, 40% dari keterlibatan (poll/cloud/playground)
drop view if exists rekap_partisipasi;
create or replace view rekap_partisipasi as
select
  nim, max(nama) as nama, max(kelas) as kelas,
  round(avg(
    (case when jml_kuis > 0 then (kuis_benar::numeric / jml_kuis) else 0 end) * 60
    + least(1, (jml_poll + jml_cloud + jml_playground)::numeric / 3) * 40
  ), 1) as skor_partisipasi,
  count(distinct pertemuan) as pertemuan_diikuti
from rekap_partisipasi_pertemuan
group by nim;

-- 6) View rekap nilai akhir (partisipasi otomatis + 3 asesmen manual, sesuai bobot)
drop view if exists rekap_nilai_akhir;
create or replace view rekap_nilai_akhir as
select
  p.nim, p.nama, p.kelas, p.skor_partisipasi, p.pertemuan_diikuti,
  a1.skor as skor_asesmen1, a2.skor as skor_asesmen2, a3.skor as skor_asesmen3,
  round(
    p.skor_partisipasi * (select bobot_persen from bobot_nilai where komponen = 'partisipasi') / 100
    + coalesce(a1.skor, 0) * (select bobot_persen from bobot_nilai where komponen = 'asesmen1') / 100
    + coalesce(a2.skor, 0) * (select bobot_persen from bobot_nilai where komponen = 'asesmen2') / 100
    + coalesce(a3.skor, 0) * (select bobot_persen from bobot_nilai where komponen = 'asesmen3') / 100
  , 1) as nilai_akhir
from rekap_partisipasi p
left join nilai_manual a1 on a1.nim = p.nim and a1.komponen = 'asesmen1'
left join nilai_manual a2 on a2.nim = p.nim and a2.komponen = 'asesmen2'
left join nilai_manual a3 on a3.nim = p.nim and a3.komponen = 'asesmen3';

-- Batasi akses view rekap hanya untuk akun dosen yang login (mencegah anon membaca lewat view)
revoke all on rekap_partisipasi_pertemuan from public, anon;
grant select on rekap_partisipasi_pertemuan to authenticated;
revoke all on rekap_partisipasi from public, anon;
grant select on rekap_partisipasi to authenticated;
revoke all on rekap_nilai_akhir from public, anon;
grant select on rekap_nilai_akhir to authenticated;

-- ================================================================
-- PENTING setelah menjalankan skema ini:
-- 1. Authentication -> Providers -> Email: matikan "Allow new users to sign up"
--    supaya mahasiswa tidak bisa membuat akun dan membaca rekapan.
-- 2. Authentication -> Users -> Add user: buat SATU akun untuk dosen
--    (email + password, atau kirim magic link).
-- 3. Salin Project URL & anon public key (Settings -> API) ke shared/config.js
-- ================================================================
