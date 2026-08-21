###2026.08.21.1
- The standby copy is watched too. Until now the only thing ever checked about
  plan B was that a DNS record resolved, so a replica could sit for days
  answering errors and nothing noticed until the day it had to take over — which
  is exactly what happened here. Set TARGET_HEALTH_URL to a URL where the copy on
  this box answers (the backend directly: at rest the proxy host is disabled, so
  the site is not reachable locally by its public name) and it is asked every
  TARGET_CHECK_INTERVAL. Its state shows next to the origin on the page, and only
  changes are notified.
- A broken standby warns, it never vetoes. Refusing to switch would turn a
  degraded site into an offline one, and this probe can be wrong too; the failover
  goes ahead with a loud notification instead.
- A failover target whose address does not match this box's public IP no longer
  blocks the switch on its own when the standby answers. On a box behind two
  internet lines there is no single "our public IP", and the line traffic leaves
  by is not necessarily the one the record points at.

###2026.08.21
- The settings page never saved anything. The form posted to /update.htm, which
  is only the progress page; the file is written by /update.php. Every field
  looked like it was applied and nothing reached the config file.
- The watcher read the configuration once at start and never again, so a change
  made on the page did nothing until someone restarted it. It is now reloaded
  whenever the file changes, and the reload is logged.
- A broken resolver was reported as a dead origin. Every probe reaches the origin
  by name, but the "do we have internet" check only opened a socket to an IP, so
  with DNS down all of them failed and the origin was declared dead. That check
  now also requires a name to resolve, and returns "inconclusive" instead.
- Failures are ignored for the first few minutes after this box boots
  (BOOT_GRACE, 300s). Right after a reboot the network stack and Docker are still
  coming up and anything measured says more about us than about the origin: a
  real reboot produced four failover attempts in six minutes.

###2026.08.20.8
- The watcher could die together with the shell that started it: setsid only
  creates a new session when the caller is not already a process group leader, so
  starting it by hand from a terminal left it attached to that terminal. Started
  from cron it survived, which is why it went unnoticed. It now always forks.

###2026.08.20.7
- A hook that refuses to run (because the site is busy and copying would capture
  a half-written state) left the copy pending, which meant it was retried on
  every pass of the watcher — a connection to the origin every few seconds for as
  long as the site stayed busy. There is now a configurable wait between retries,
  60 seconds by default.

###2026.08.20.6
- The per-field help is back to Unraid's own mechanism: plain blockquotes that
  the built-in Help button in the top bar unfolds, instead of the custom question
  mark widget added in .5, which was not how Unraid does this.

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
