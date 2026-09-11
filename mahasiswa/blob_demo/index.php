<?php
require 'db.php';
$izin = ['image/jpeg', 'image/png', 'audio/mpeg', 'application/pdf'];
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['berkas'])) {
  $f = $_FILES['berkas'];
  if ($f['error'] === UPLOAD_ERR_OK && $f['size'] <= 2 * 1024 * 1024) {
    $mime = mime_content_type($f['tmp_name']);   // cek isi, bukan ekstensi
    if (in_array($mime, $izin, true)) {
      $st = $pdo->prepare('INSERT INTO file_media (nama_file, mime, ukuran, isi)
                           VALUES (?, ?, ?, ?)');
      $st->execute([basename($f['name']), $mime, $f['size'],
                    file_get_contents($f['tmp_name'])]);
    }
  }
}
?>
<?php $rows = $pdo->query('SELECT id, nama_file, ukuran FROM file_media
                          ORDER BY id DESC')->fetchAll(); ?>
<form method="post" enctype="multipart/form-data">
  <input type="file" name="berkas" required>
  <button>Unggah</button>
</form>
<?php foreach ($rows as $r): ?>
  <p><a href="view.php?id=<?= $r['id'] ?>">
     <?= htmlspecialchars($r['nama_file']) ?></a>
     (<?= $r['ukuran'] ?> byte)</p>
<?php endforeach; ?>
