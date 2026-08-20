<?php
/* Actions triggered from the settings page.
   Only read-only checks are exposed here on purpose: switching over is the
   watcher's job, and a stray click should never move a live site. */

$script = "/usr/local/emhttp/plugins/failover-guard/scripts/failover-guard";
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
    default:
        http_response_code(400);
        echo "unknown action";
}
