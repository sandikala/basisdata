// ============================================================
// LMS TRACKING — mencatat aktivitas mahasiswa (kuis, polling, word
// cloud, playground SQL, waktu di deck) ke Supabase untuk penilaian
// otomatis. Dimuat di setiap pXX.html lewat shared/config.js + shared/tracking.js
// ============================================================
(function () {
  const CFG = window.LMS_CONFIG || {};
  const CONFIGURED = !!(CFG.SUPABASE_URL && !CFG.SUPABASE_URL.includes("YOUR-PROJECT"));
  const deckNo = (window.DECK && window.DECK.no) || 0;
  const deckTitle = (window.DECK && window.DECK.title) || document.title;
  const KEY = "lms_identitas_v1";

  function getIdentitas() {
    try { return JSON.parse(localStorage.getItem(KEY)); } catch (e) { return null; }
  }
  function setIdentitas(v) { localStorage.setItem(KEY, JSON.stringify(v)); }

  function insertRow(row, useBeacon) {
    if (!CONFIGURED) { console.warn("[LMS] Supabase belum dikonfigurasi (shared/config.js)."); return; }
    const url = CFG.SUPABASE_URL.replace(/\/$/, "") + "/rest/v1/log_aktivitas";
    const body = JSON.stringify(row);
    fetch(url, {
      method: "POST",
      keepalive: !!useBeacon,
      headers: {
        "Content-Type": "application/json",
        "apikey": CFG.SUPABASE_ANON_KEY,
        "Authorization": "Bearer " + CFG.SUPABASE_ANON_KEY,
        "Prefer": "return=minimal"
      },
      body
    }).catch(() => { /* offline / gagal kirim: diamkan, tidak mengganggu presentasi */ });
  }

  function track(event_type, detail, benar) {
    const id = getIdentitas();
    if (!id || id.role === "dosen") return;
    insertRow({
      nim: id.nim,
      nama: id.nama,
      kelas: id.kelas || null,
      pertemuan: deckNo,
      event_type,
      detail: detail || {},
      benar: typeof benar === "boolean" ? benar : null
    });
  }
  window.LMS = { track, getIdentitas };

  // ---------- gerbang identitas ----------
  function showGate() {
    if (document.getElementById("lms-gate")) return;
    const ov = document.createElement("div");
    ov.id = "lms-gate";
    ov.style.cssText = "position:fixed;inset:0;background:rgba(10,14,30,.92);z-index:99999;display:flex;align-items:center;justify-content:center;font-family:system-ui,sans-serif;color:#fff";
    ov.innerHTML =
      '<div style="background:#141b30;padding:32px 28px;border-radius:16px;max-width:420px;width:92%;box-shadow:0 20px 60px rgba(0,0,0,.5)">' +
      '<h2 style="margin:0 0 6px;font-size:20px">Selamat datang</h2>' +
      '<p style="margin:0 0 18px;font-size:13px;color:#9fb0d9;line-height:1.5">Masuk dulu untuk mengikuti pertemuan ini. Identitas dipakai mencatat kuis, polling, dan playground kamu untuk penilaian partisipasi.</p>' +
      '<div style="display:flex;gap:8px;margin-bottom:14px">' +
      '<button id="lms-role-mhs" style="flex:1;padding:10px;border-radius:8px;border:none;background:#2F5BEA;color:#fff;font-weight:600;cursor:pointer">Saya Mahasiswa</button>' +
      '<button id="lms-role-dsn" style="flex:1;padding:10px;border-radius:8px;border:1px solid #33406b;background:transparent;color:#cfd8f5;cursor:pointer">Mode Dosen</button>' +
      "</div>" +
      '<div id="lms-mhs-form" style="display:none">' +
      '<input id="lms-nim" placeholder="NIM" style="width:100%;margin-bottom:8px;padding:9px;border-radius:8px;border:1px solid #33406b;background:#0e1426;color:#fff;box-sizing:border-box">' +
      '<input id="lms-nama" placeholder="Nama lengkap" style="width:100%;margin-bottom:8px;padding:9px;border-radius:8px;border:1px solid #33406b;background:#0e1426;color:#fff;box-sizing:border-box">' +
      '<select id="lms-kelas" style="width:100%;margin-bottom:12px;padding:9px;border-radius:8px;border:1px solid #33406b;background:#0e1426;color:#fff;box-sizing:border-box"><option value="">Pilih Kelas</option><option value="4">Kelas 4</option><option value="5">Kelas 5</option></select>' +
      '<button id="lms-masuk" style="width:100%;padding:10px;border-radius:8px;border:none;background:#22c55e;color:#04210f;font-weight:700;cursor:pointer">Masuk</button>' +
      "</div>" +
      (CONFIGURED ? "" : '<p style="margin-top:12px;font-size:11px;color:#f0a">Supabase belum dikonfigurasi — aktivitas tidak akan tersimpan.</p>') +
      "</div>";
    document.body.appendChild(ov);
    ov.querySelector("#lms-role-mhs").onclick = () => { ov.querySelector("#lms-mhs-form").style.display = "block"; };
    ov.querySelector("#lms-role-dsn").onclick = () => { setIdentitas({ role: "dosen" }); ov.remove(); afterIdentified(true); };
    ov.querySelector("#lms-masuk").onclick = () => {
      const nim = ov.querySelector("#lms-nim").value.trim();
      const nama = ov.querySelector("#lms-nama").value.trim();
      const kelas = ov.querySelector("#lms-kelas").value.trim();
      if (!nim || !nama) { alert("NIM dan nama wajib diisi."); return; }
      setIdentitas({ role: "mahasiswa", nim, nama, kelas: kelas || null });
      ov.remove();
      afterIdentified(false);
    };
  }

  function badge() {
    const id = getIdentitas();
    if (!id || document.getElementById("lms-badge")) return;
    const b = document.createElement("div");
    b.id = "lms-badge";
    b.style.cssText = "position:fixed;bottom:10px;right:10px;z-index:9998;background:#141b30;color:#cfd8f5;font:12px system-ui,sans-serif;padding:6px 10px;border-radius:20px;opacity:.85;cursor:pointer";
    const kelasStr = id.kelas ? " · Kelas " + id.kelas : "";
    b.textContent = id.role === "dosen" ? "👩‍🏫 Mode dosen (tidak direkam)" : "🎓 " + id.nama + " · " + id.nim + kelasStr + " — ganti";
    b.onclick = () => { if (confirm("Ganti identitas?")) { localStorage.removeItem(KEY); location.reload(); } };
    document.body.appendChild(b);
  }

  function startTimeTracking() {
    const t0 = performance.now();
    let sent = false;
    const flush = () => {
      if (sent) return;
      sent = true;
      const durasi = Math.round((performance.now() - t0) / 1000);
      if (durasi < 3) return;
      const id = getIdentitas();
      if (!id || id.role === "dosen") return;
      insertRow({ nim: id.nim, nama: id.nama, kelas: id.kelas || null, pertemuan: deckNo, event_type: "deck_time", detail: { durasi_detik: durasi }, benar: null }, true);
    };
    document.addEventListener("visibilitychange", () => { if (document.hidden) { flush(); sent = false; } });
    window.addEventListener("pagehide", flush);
  }

  function attachDelegates() {
    document.addEventListener("click", function (e) {
      const qzBtn = e.target.closest(".qz button");
      if (qzBtn) {
        const qz = qzBtn.closest(".qz");
        if (!qz.dataset.lmsLogged) {
          qz.dataset.lmsLogged = "1";
          const ans = +qz.dataset.ans;
          const idx = Array.prototype.indexOf.call(qz.querySelectorAll("button"), qzBtn);
          const qq = qz.parentElement && qz.parentElement.querySelector(".qq");
          track("quiz", { soal: qq ? qq.textContent.slice(0, 200) : "", pilihan: qzBtn.textContent, index: idx }, idx === ans);
        }
        return;
      }
      const tallyBtn = e.target.closest(".tally .row button");
      if (tallyBtn) {
        const row = tallyBtn.closest(".row");
        const lbl = row.querySelector(".lbl");
        track("poll", { opsi: lbl ? lbl.textContent : "" });
        return;
      }
      const cloudBtn = e.target.closest(".cloudw button");
      if (cloudBtn) {
        const wrap = cloudBtn.closest(".cloudw");
        const inp = wrap.querySelector("input");
        if (inp && inp.value.trim()) track("cloud", { isi: inp.value.trim().slice(0, 300) });
        return;
      }
      const runBtn = e.target.closest('.pg [data-a="run"]');
      if (runBtn) {
        const pg = runBtn.closest(".pg");
        const ta = pg.querySelector("textarea");
        const sql = ta ? ta.value.trim() : "";
        if (sql) {
          setTimeout(() => {
            const out = pg.querySelector(".out");
            const gagal = !!(out && out.querySelector(".err"));
            track("playground", { sql: sql.slice(0, 500) }, !gagal);
          }, 80);
        }
      }
    }, true);
  }

  function afterIdentified() {
    badge();
    track("deck_open", { title: deckTitle });
    startTimeTracking();
    attachDelegates();
  }

  document.addEventListener("DOMContentLoaded", () => {
    const id = getIdentitas();
    if (!id) showGate(); else afterIdentified();
  });
})();
