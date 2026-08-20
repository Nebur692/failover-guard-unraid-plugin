###2026.08.20.5
- The origin health is now the first and biggest thing on the page, on the same
  row as the rest of the state instead of dropped onto its own line below it.
- Every field has a "?" next to its label that unfolds a plain-language
  explanation of what it does and what happens if you get it wrong. The previous
  notes only showed up if you found the global help toggle, and several fields
  had no explanation at all.

###2026.08.20.4
- The settings page now shows what the watcher is seeing: origin healthy, origin
  down, or inconclusive because this server itself has no internet, plus the
  consecutive failure count and how many seconds ago it was checked. Until now
  that only appeared if you pressed the check button. The value is published by
  the watcher rather than probed on page load, so the page is instant and always
  agrees with what the watcher is acting on, and it is shown as "no recent
  reading" if the watcher stopped updating it.

###2026.08.20.3
- The "enabled" line in the checks output showed the raw yes/no from the config
  file instead of the translated word.

###2026.08.20.2
- The settings page, the checks output and the notifications now follow the
  language selected in Unraid (Settings -> Display Settings), instead of showing
  both languages at once. Spanish when the locale starts with "es", English
  otherwise, so any other language still gets a readable page. The log file
  stays in English on purpose: it is what gets pasted into a bug report.

###2026.08.20.1
- The settings page now shows the log: last 100 to 2000 lines, with refresh,
  clear, and an optional 5 second auto-refresh that keeps the newest lines in
  view. Until now the page only told you where the file was.

###2026.08.20
- First release. Watches a remote origin from your Unraid box and fails over
  automatically when it dies: switches the Cloudflare DNS records of a zone to a
  failover target and enables the matching Nginx Proxy Manager host, then returns
  everything when the origin comes back.
- Detection in about interval x threshold seconds (10s x 3 by default), not the
  several minutes a cron job would take.
- Three guards against false positives: a failure is not counted when this
  server itself has no internet, an open port alone is not accepted as healthy
  when a health path is configured, and a configurable number of consecutive
  failures is required before anything is switched.
- Refuses to switch when the failover target is not reachable or its dynamic DNS
  has not caught up with the current public IP, since sending users nowhere is
  worse than leaving the outage alone.
- Your data is moved by your own hook scripts, never by the plugin. The
  pre-failback hook runs with the local host already disabled, so nothing can be
  written while the copy is in flight, and a failing hook aborts the failback
  instead of losing whatever arrived during the outage.
