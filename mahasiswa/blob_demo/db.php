<?php
// db.php — koneksi yang dipakai ulang
$pdo = new PDO(
  'mysql:host=localhost;dbname=praktikum_db;charset=utf8mb4',
  'root', '',
  [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
