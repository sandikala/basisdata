USE praktikum_db;
CREATE TABLE file_media (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nama_file VARCHAR(255) NOT NULL,
  mime      VARCHAR(100) NOT NULL,
  ukuran    INT NOT NULL,
  isi       MEDIUMBLOB NOT NULL,
  diunggah  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
