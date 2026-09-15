#!/bin/bash
# Builds failover-guard.plg from the files under src/.
#
# Every FILE carries the SHA256 of its real content: Unraid's installer only
# rewrites a deployed file when the hash does not match, so "Update" actually
# redeploys what changed instead of silently keeping the first version forever.

set -e
cd "$(dirname "$0")"

VERSION="${1:?usage: build-plg.sh YYYY.MM.DD[.N]}"
NAME="failover-guard"
OUT="$NAME.plg"
SRC="src"

emit_file() {
    local target="$1" mode="$2" src="$SRC$1"
    local sha
    sha=$(sha256sum "$src" | awk '{print $1}')
    cat <<EOF
<FILE Name="$target" Mode="$mode">
 <INLINE>
<![CDATA[
$(cat "$src")
]]>
 </INLINE>
 <SHA256>$sha</SHA256>
</FILE>

EOF
}

{
cat <<'HEADER'
<?xml version='1.0' standalone='yes'?>

<!DOCTYPE PLUGIN [
<!ENTITY name      "failover-guard">
<!ENTITY author    "Nebur692">
HEADER

echo "<!ENTITY version   \"$VERSION\">"

cat <<'HEADER2'
<!ENTITY launch    "Settings/FailoverGuard">
<!ENTITY gitURL    "https://raw.githubusercontent.com/Nebur692/failover-guard-unraid-plugin/main">
<!ENTITY pluginURL "&gitURL;/&name;.plg">
<!ENTITY plugdir   "/usr/local/emhttp/plugins/&name;">
<!ENTITY cfgdir    "/boot/config/plugins/&name;">
]>

<PLUGIN name="&name;" author="&author;" version="&version;" launch="&launch;"
        pluginURL="&pluginURL;"
        support="https://github.com/Nebur692/failover-guard-unraid-plugin/issues"
        min="6.12.0">

<CHANGES>
HEADER2

# Escapado, no volcado tal cual: el 15-09-2026 un "<plugin>" dentro del propio
# changelog convirtio el .plg en XML invalido. Lo cazo xmllint al final, que para
# eso esta, pero el fallo vuelve cada vez que alguien escribe una etiqueta o un &
# al documentar. El contenido no puede romper el continente.
sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' CHANGES.md

cat <<'MID'
</CHANGES>

MID

emit_file "/usr/local/emhttp/plugins/failover-guard/scripts/failover-guard" "0755"
emit_file "/usr/local/emhttp/plugins/failover-guard/scripts/supervise"      "0755"
emit_file "/usr/local/emhttp/plugins/failover-guard/FailoverGuard.page"     "0644"
emit_file "/usr/local/emhttp/plugins/failover-guard/include/action.php"     "0644"

cat <<'TAIL'
<FILE Run="/bin/bash">
<INLINE>
mkdir -p &cfgdir;/state

# Seed a config on first install so the page has something to read.
if [ ! -f &cfgdir;/config ]; then
  cat &gt; &cfgdir;/config &lt;&lt;'CFG'
ENABLED="no"
ORIGIN_HOST=""
ORIGIN_PORTS="443"
HEALTH_PATH=""
HEALTH_EXPECT=""
DOMAIN=""
FAILOVER_TARGET=""
CF_TOKEN=""
CHECK_INTERVAL="10"
FAIL_THRESHOLD="3"
NPM_DATA=""
NPM_CONTAINER="Nginx-Proxy-Manager-Official"
NPM_HOST_ID=""
TARGET_HEALTH_URL=""
TARGET_EXPECT=""
TARGET_CHECK_INTERVAL="300"
HOOK_REPLICATE=""
HOOK_PRE_FAILBACK=""
REPLICATE_INTERVAL="3600"
RETRY_INTERVAL="60"
BOOT_GRACE="300"
NOTIFY="yes"
CFG
  chmod 600 &cfgdir;/config
fi

# The watcher is a long-lived process; this keeps it alive across crashes,
# array restarts and plugin updates.
#
# THE UNRAID WAY: a .cron file under the plugin's own config directory, and then
# update_cron. That script concatenates /boot/config/plugins/*/*.cron into root's
# crontab -- it does NOT read /etc/cron.d/, which on Unraid is dcron's spool
# (crontab -c /etc/cron.d), not Debian's drop-in directory.
#
# Writing straight into /etc/cron.d/ is what this plugin used to do, and it never
# worked: the entry also carried a user column, so every five minutes dcron tried
# to run a command called "root" and exited 127. The supervisor -- whose entire
# job is to bring the watcher back after a crash, an array restart or a plugin
# update -- had never run once. No user column here either: these lines end up in
# root's crontab, where the sixth field is already the command.
cat &gt; &cfgdir;/&name;.cron &lt;&lt;'CRON'
# Keep the watcher alive across crashes, array restarts and plugin updates:
*/5 * * * * /usr/local/emhttp/plugins/failover-guard/scripts/supervise &amp;&gt; /dev/null
CRON

# Clean up after the versions that wrote it in the wrong place, or dcron would
# keep firing the broken entry next to the good one.
rm -f /etc/cron.d/&name;

[ -x /usr/local/sbin/update_cron ] &amp;&amp; /usr/local/sbin/update_cron

&plugdir;/scripts/supervise >/dev/null 2>&amp;1 || true

echo ""
echo "----------------------------------------------------"
echo " failover-guard has been installed."
echo " Configure it at Settings -&gt; Failover Guard."
echo " Version: &version;"
echo "----------------------------------------------------"
echo ""
</INLINE>
</FILE>

<FILE Run="/bin/bash" Method="remove">
<INLINE>
PID=$(cat &cfgdir;/state/watcher.pid 2>/dev/null)
[ -n "$PID" ] &amp;&amp; kill "$PID" 2>/dev/null
rm -f &cfgdir;/&name;.cron
rm -f /etc/cron.d/&name;            # por si viene de una version anterior
[ -x /usr/local/sbin/update_cron ] &amp;&amp; /usr/local/sbin/update_cron
rm -rf &plugdir;
echo ""
echo " failover-guard removed. Settings kept in &cfgdir;"
echo ""
</INLINE>
</FILE>

</PLUGIN>
TAIL
} > "$OUT"

xmllint --noout "$OUT" && echo "Built $OUT (version $VERSION) — XML OK"
