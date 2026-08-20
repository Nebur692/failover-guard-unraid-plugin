<?php
/* Actions triggered from the settings page.
   Only read-only checks are exposed here on purpose: switching over is the
   watcher's job, and a stray click should never move a live site. */

$script = "/usr/local/emhttp/plugins/failover-guard/scripts/failover-guard";
$logfile = "/var/log/failover-guard.log";
$action = $_POST['action'] ?? '';

switch ($action) {
    case 'test':
        header('Content-Type: text/plain; charset=utf-8');
        echo shell_exec("bash " . escapeshellarg($script) . " test 2>&1");
        break;

    case 'status':
        header('Content-Type: application/json; charset=utf-8');
        echo shell_exec("bash " . escapeshellarg($script) . " status 2>&1");
        break;

    case 'log':
        header('Content-Type: text/plain; charset=utf-8');
        if (!file_exists($logfile)) { echo "No log yet / Todavía no hay registro"; break; }
        $lines = (int)($_POST['lines'] ?? 200);
        if ($lines < 20)   $lines = 20;
        if ($lines > 2000) $lines = 2000;
        echo shell_exec("tail -n $lines " . escapeshellarg($logfile) . " 2>&1");
        break;

    case 'clearlog':
        header('Content-Type: text/plain; charset=utf-8');
        file_put_contents($logfile, "");
        echo "Log cleared / Registro vaciado";
        break;

    default:
        http_response_code(400);
        echo "unknown action";
}
