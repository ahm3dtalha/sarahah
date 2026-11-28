(function () {
  const host = document.getElementById("site-header");
  if (!host) return;
  host.className = "bar";

  const logo = `<svg viewBox="0 0 48 48" aria-hidden="true">
    <rect class="b" x="3" y="4" width="42" height="33" rx="13"/>
    <path class="b" d="M13 35v9l10-9z"/>
    <circle class="d" cx="16" cy="20.5" r="3"/>
    <circle class="d" cx="24" cy="20.5" r="3"/>
    <circle class="d" cx="32" cy="20.5" r="3"/>
  </svg>`;

  const authed = !!getToken();

  host.innerHTML = `
  <div class="nav">
    <a class="logo" href="index.html">${logo}<span class="wordmark" data-i18n="brand"></span></a>
    <nav class="links">
      <a href="index.html#features" data-i18n="nav_f"></a>
      <button class="lang" id="lang" type="button" aria-label="Language"></button>
      ${authed
        ? `<a href="dashboard.html" data-i18n="dash"></a>
           <span class="chip"><span class="av" id="av">·</span><span id="uname">…</span></span>
           <button class="btn ghost sm" id="logout" type="button" data-i18n="logout"></button>`
        : `<a class="btn sm" href="login.html" data-i18n="login"></a>`}
    </nav>
  </div>`;

  document.getElementById("lang").onclick = () => setLang(LANG === "ar" ? "en" : "ar");
  if (!authed) return;

  const out = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("uname");
    location.href = "index.html";
  };
  document.getElementById("logout").onclick = out;

  const show = n => {
    document.getElementById("uname").textContent = "@" + n;
    document.getElementById("av").textContent = n[0].toUpperCase();
  };
  const cached = localStorage.getItem("uname");
  if (cached) show(cached);

  api("/me")
    .then(me => { localStorage.setItem("uname", me.username); show(me.username); })
    .catch(e => { if (e.status === 401) out(); });
})();



document.addEventListener("DOMContentLoaded", () => {
  if (!document.querySelector(".site-footer")) {
    const footer = document.createElement("footer");
    
    footer.className = "site-footer";
    footer.innerHTML = `
      <footer class="site" data-i18n="foot"></footer>
    `;
    document.body.appendChild(footer);
  }
});
