-- ============================================================
-- Asesmen 3 GHK2AAB3 Basis Data — skrip data awal
-- Jalankan di client mysql:  SOURCE asesmen3_setup.sql;
-- ============================================================
DROP DATABASE IF EXISTS rental_kamera;
CREATE DATABASE rental_kamera;
USE rental_kamera;

CREATE TABLE pelanggan (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  nama  VARCHAR(100) NOT NULL,
  kota  VARCHAR(50)  NOT NULL,
  email VARCHAR(100) UNIQUE
);

CREATE TABLE kamera (
  kode       CHAR(5)       PRIMARY KEY,
  nama       VARCHAR(100)  NOT NULL,
  kategori   VARCHAR(30)   NOT NULL,
  harga_sewa DECIMAL(10,2) NOT NULL CHECK (harga_sewa > 0),
  stok       INT           NOT NULL DEFAULT 0 CHECK (stok >= 0)
);

CREATE TABLE peminjaman (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  id_pelanggan INT     NOT NULL,
  kode_kamera  CHAR(5) NOT NULL,
  tgl_pinjam   DATE    NOT NULL,
  lama_hari    INT     NOT NULL CHECK (lama_hari > 0),
  status       ENUM('dipinjam','kembali','terlambat') NOT NULL DEFAULT 'dipinjam',
  FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id),
  FOREIGN KEY (kode_kamera)  REFERENCES kamera(kode)
);

CREATE TABLE log_stok (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  kode_kamera CHAR(5),
  stok_lama   INT,
  stok_baru   INT,
  waktu       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO pelanggan (nama, kota, email) VALUES
('Rani Oktaviani','Bandung','rani@mail.test'),
('Dimas Prasetyo','Cimahi','dimas@mail.test'),
('Salsa Nabila','Bandung',NULL),
('Yusuf Hakim','Sumedang','yusuf@mail.test'),
('Tia Anggraini','Bandung','tia@mail.test'),
('Rizky Maulana','Cimahi','rizky@mail.test'),
('Nadia Putri','Sumedang',NULL),
('Arif Gunawan','Bandung','arif@mail.test');

INSERT INTO kamera (kode, nama, kategori, harga_sewa, stok) VALUES
('MR001','Mirrorless APS-C Kit','Mirrorless',175000,3),
('MR002','Mirrorless Full Frame','Mirrorless',350000,1),
('DS001','DSLR Entry Kit','DSLR',125000,4),
('DS002','DSLR Pro Body','DSLR',275000,0),
('LN001','Lensa 50mm f/1.8','Lensa',60000,5),
('LN002','Lensa Tele 70-200mm','Lensa',200000,2),
('AC001','Action Cam 4K','Action Cam',90000,3),
('AC002','Action Cam + Gimbal','Action Cam',140000,2);

INSERT INTO peminjaman (id_pelanggan, kode_kamera, tgl_pinjam, lama_hari, status) VALUES
(1,'MR001','2026-08-01',2,'kembali'),
(2,'DS001','2026-08-03',3,'kembali'),
(1,'LN001','2026-08-05',1,'kembali'),
(3,'AC001','2026-08-10',4,'terlambat'),
(4,'MR002','2026-08-12',2,'kembali'),
(5,'LN002','2026-08-15',3,'dipinjam'),
(2,'AC002','2026-08-18',2,'kembali'),
(6,'DS001','2026-08-20',5,'terlambat'),
(1,'MR001','2026-09-01',3,'dipinjam'),
(7,'AC001','2026-09-02',2,'dipinjam'),
(5,'LN001','2026-09-03',1,'kembali'),
(4,'DS001','2026-09-05',2,'dipinjam');
-- Catatan: pelanggan 8 (Arif Gunawan) sengaja belum pernah meminjam.
