const getToken = () => localStorage.getItem("token");

async function api(path, opts = {}) {
  const headers = { "Content-Type": "application/json" };
  if (getToken()) headers.Authorization = "Bearer " + getToken();
  const res = await fetch(path, { ...opts, headers });
  let data = null;
  try { data = await res.json(); } catch {}
  if (!res.ok) {
    const d = data && data.detail;
    const err = new Error(typeof d === "string" ? d : "تحقق من البيانات المدخلة");
    err.status = res.status;
    throw err;
  }
  return data;
}