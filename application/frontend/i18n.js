const T = {
  ar: {
    login: "دخول", dash: "لوحتي", nav_f: "المزايا", nav_h: "كيف تعمل",
    hero_t: "اكتشف ما يفكر به الآخرون عنك، بصراحة",
    hero_s: "أنشئ حسابك، شارك رابطك الخاص، واستقبل رسائل صريحة من أصدقائك وزملائك دون أن تعرف من أرسلها.",
    cta1: "ابدأ الآن مجانًا", cta2: "كيف تعمل؟", anon: "مجهول",
    m1: "أسلوبك في الشرح رائع، استمر!", m2: "أتمنى لو تبتسم أكثر في الاجتماعات 😄",
    f_t: "لماذا صراحة؟",
    f1t: "رابط واحد", f1d: "تحصل على رابط خاص بك تشاركه في أي مكان.",
    f2t: "بلا تسجيل للمرسل", f2d: "أي شخص يكتب لك دون أن ينشئ حسابًا.",
    f3t: "لوحة خاصة بك", f3d: "رسائلك في مكان واحد لا يراه غيرك.",
    h_t: "ثلاث خطوات فقط", s1: "أنشئ حسابك", s2: "شارك رابطك", s3: "اقرأ الرسائل",
    foot: "© 2026 صراحة (Sarahah) — تطوير أحمد طلحه. جميع الحقوق محفوظة.",
    tag: "استقبل رسائل صريحة من أشخاص لا تعرفهم.",
    tab_l: "دخول", tab_r: "حساب جديد", l_u: "اسم المستخدم", l_e: "البريد الإلكتروني",
    l_p: "كلمة المرور", sub_l: "دخول", sub_r: "إنشاء الحساب", back: "← الرئيسية",
    footer_rights: "© 2026 صراحة (Sarahah) — تطوير أحمد طلحه. جميع الحقوق محفوظة."
  },
  en: {
    login: "Log in", dash: "Dashboard", nav_f: "Features", nav_h: "How it works",
    hero_t: "Find out what others really think of you",
    hero_s: "Create an account, share your private link, and receive honest messages from friends and colleagues without knowing who sent them.",
    cta1: "Get started free", cta2: "How it works", anon: "Anonymous",
    m1: "Your way of explaining things is great, keep going!", m2: "I wish you smiled more in meetings 😄",
    f_t: "Why Sarahah?",
    f1t: "One link", f1d: "Get a private link you can share anywhere.",
    f2t: "No sign-up for senders", f2d: "Anyone can write to you without creating an account.",
    f3t: "Your own dashboard", f3d: "All your messages in one place, visible only to you.",
    h_t: "Just three steps", s1: "Create your account", s2: "Share your link", s3: "Read your messages",
    foot: "© 2026 Sarahah — Developed by Ahmed Talha. All rights reserved .",
    tag: "Receive honest messages from people you don’t know.",
    tab_l: "Log in", tab_r: "Sign up", l_u: "Username", l_e: "Email",
    l_p: "Password", sub_l: "Log in", sub_r: "Create account", back: "← Home",
    footer_rights: "© 2026 Sarahah — Developed by Ahmed Talha. All rights reserved ."
  }
};

let LANG = localStorage.getItem("lang") || (navigator.language.startsWith("ar") ? "ar" : "en");
const t = k => T[LANG][k];

function setLang(l) {
  LANG = l;
  localStorage.setItem("lang", l);
  document.documentElement.lang = l;
  document.documentElement.dir = l === "ar" ? "rtl" : "ltr";
  document.querySelectorAll("[data-i18n]").forEach(e => e.textContent = T[l][e.dataset.i18n]);
  const b = document.getElementById("lang");
  if (b) b.textContent = l === "ar" ? "EN" : "عربي";
  if (window.onLang) window.onLang();
}
Object.assign(T.ar, {
  brand: "صراحة", logout: "خروج",
  d_share: "رابطك الخاص", d_hint: "أرسله لأصدقائك ليكتبوا لك دون أن تعرف من هم.",
  copy: "نسخ", copied: "تم النسخ", d_in: "الرسائل الواردة",
  d_empty: "لا رسائل بعد. شارك رابطك لتصلك أول رسالة.",
  d_count: "رسالة", d_err: "تعذّر تحميل الرسائل"
});
Object.assign(T.en, {
  brand: "Sarahah", logout: "Log out",
  d_share: "Your private link", d_hint: "Send it to your friends so they can write to you without you knowing who they are.",
  copy: "Copy", copied: "Copied", d_in: "Inbox",
  d_empty: "No messages yet. Share your link to get your first one.",
  d_count: "messages", d_err: "Could not load messages"
});
Object.assign(T.ar, {
  u_to: "اكتب رسالة صريحة إلى", u_text: "رسالتك", u_sender: "اسمك (اختياري)",
  u_ph: "اتركه فارغًا لتصل كمجهول", u_send: "إرسال", u_done: "وصلت رسالتك",
  u_done_s: "يمكنك إرسال رسالة أخرى متى شئت.", u_again: "رسالة أخرى",
  u_bad: "هذا الرابط غير صحيح", u_note: "رسالتك مجهولة ما لم تكتب اسمك.",
  u_get: "أنشئ رابطك الخاص أنت أيضًا"
});
Object.assign(T.en, {
  u_to: "Write an honest message to", u_text: "Your message", u_sender: "Your name (optional)",
  u_ph: "Leave empty to send as anonymous", u_send: "Send", u_done: "Your message was sent",
  u_done_s: "You can send another one anytime.", u_again: "Send another",
  u_bad: "This link is not valid", u_note: "Your message stays anonymous unless you add your name.",
  u_get: "Get your own private link"
});