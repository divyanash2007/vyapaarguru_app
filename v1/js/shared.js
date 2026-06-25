/* shared.js — ApniDukaan interactive behaviours */

// ── Scanner overlay ──────────────────────────────────────────────
function openScanner(onResult) {
  const overlay = document.getElementById('scanner-overlay');
  if (!overlay) return;
  overlay.style.display = 'flex';
  // Simulate a scan after 2.5s
  overlay._timer = setTimeout(() => {
    const codes = ['8901030874628','8906002480012','8901719110023','8901058851019','8901030874635'];
    const code = codes[Math.floor(Math.random() * codes.length)];
    closeScanner();
    if (onResult) onResult(code);
  }, 2500);
}

function closeScanner() {
  const overlay = document.getElementById('scanner-overlay');
  if (!overlay) return;
  clearTimeout(overlay._timer);
  overlay.style.display = 'none';
}

// ── Toggle ───────────────────────────────────────────────────────
document.addEventListener('click', e => {
  const t = e.target.closest('.toggle');
  if (t) t.classList.toggle('on');
});

// ── Qty stepper ──────────────────────────────────────────────────
document.addEventListener('click', e => {
  const btn = e.target.closest('.qty-btn');
  if (!btn) return;
  const val = btn.closest('.qty-stepper').querySelector('.qty-val');
  let n = parseInt(val.value || val.textContent) || 0;
  if (btn.dataset.dir === 'up')   n = Math.min(n + 1, 999);
  if (btn.dataset.dir === 'down') n = Math.max(n - 1, 0);
  if (val.tagName === 'INPUT') val.value = n;
  else val.textContent = n;
});

// ── Chip filter ──────────────────────────────────────────────────
document.addEventListener('click', e => {
  const chip = e.target.closest('.chip');
  if (!chip) return;
  const row = chip.closest('.chip-row');
  if (!row) return;
  row.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
  chip.classList.add('active');
});

// ── Bottom nav active ────────────────────────────────────────────
(function() {
  const items = document.querySelectorAll('.nav-item[data-screen]');
  const cur = location.pathname.split('/').pop();
  items.forEach(item => {
    if (item.dataset.screen && cur.includes(item.dataset.screen)) {
      item.classList.add('active');
    }
  });
})();

// ── Theme toggle (light / dark) ──────────────────────────────────
(function() {
  const STORAGE_KEY = 'apnidukaan-theme';
  function applyTheme(theme) {
    document.documentElement.classList.toggle('light', theme === 'light');
  }
  // Apply saved preference immediately
  const saved = localStorage.getItem(STORAGE_KEY) || 'dark';
  applyTheme(saved);

  document.addEventListener('click', function(e) {
    const btn = e.target.closest('.theme-toggle');
    if (!btn) return;
    const next = document.documentElement.classList.contains('light') ? 'dark' : 'light';
    localStorage.setItem(STORAGE_KEY, next);
    applyTheme(next);
  });
})();
