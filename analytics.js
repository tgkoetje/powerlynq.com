/**
 * PowerlynQ — load GA4 when POWERLYNQ_GA_ID is set (see analytics-config.js)
 */
(function () {
  var id = window.POWERLYNQ_GA_ID;
  if (!id || typeof id !== "string" || id.indexOf("G-") !== 0) {
    return;
  }

  window.dataLayer = window.dataLayer || [];
  function gtag() {
    window.dataLayer.push(arguments);
  }
  window.gtag = gtag;

  gtag("js", new Date());
  gtag("config", id, {
    anonymize_ip: true,
    send_page_view: true,
  });

  var s = document.createElement("script");
  s.async = true;
  s.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(id);
  document.head.appendChild(s);
})();
