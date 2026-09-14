<?php
// view.php — kirim isi BLOB ke browser
require 'db.php';
$st = $pdo->prepare('SELECT mime, isi FROM file_media WHERE id = ?');
$st->execute([(int) ($_GET['id'] ?? 0)]);
$r = $st->fetch();
if (!$r) { http_response_code(404); exit('File tidak ditemukan'); }
header('Content-Type: ' . $r['mime']);
echo $r['isi'];
