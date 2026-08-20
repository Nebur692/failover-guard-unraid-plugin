<div align="center">

# failover-guard-unraid-plugin

*Your Unraid box watches the site you host elsewhere, and takes over when it dies*

![Release](https://img.shields.io/github/v/release/Nebur692/failover-guard-unraid-plugin?label=release&color=blue)
[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/nebur69265723)
[![PayPal](https://img.shields.io/badge/PayPal-donate-00457C?logo=paypal&logoColor=white)](https://paypal.me/0SkillS)

🇬🇧 [English](#english) · 🇪🇸 [Español](#español)

</div>

---

## English

An Unraid plugin that watches a remote origin — a VPS, a dedicated server, anything
that serves a domain — and, when it stops responding, switches the domain's
Cloudflare DNS records to your Unraid box and enables the matching Nginx Proxy
Manager host. When the origin comes back, it returns everything.

The rule that governs the whole design: **at any moment only one side accepts
writes**, and data always moves from that side to the other, never both ways.

### ✨ Features

- **Detection in seconds, not minutes.** A permanent watcher checks every 10
  seconds by default, so a dead origin is caught in about 30 seconds. A cron job
  polling every five minutes would take up to fifteen.
- **Three guards against false positives.** A failure is not counted when your own
  server has no internet — the origin may be perfectly fine and you simply cannot
  see it, and failing over would be pointless because nobody could reach you
  either. An open TCP port is not accepted as proof of health when a health path
  is configured, because a machine can boot with its web server dead. And a
  configurable number of consecutive failures is required before anything moves.
- **It will not switch to a dead end.** Before touching DNS it checks that the
  failover target actually resolves and that your dynamic DNS has caught up with
  your current public IP. Sending users nowhere is worse than leaving the outage
  alone.
- **Nginx Proxy Manager, without its API.** The local host stays disabled while
  the origin is healthy, so two copies never accept writes at once. It is enabled
  only during a failover. Done the same way NPM does it internally, so no
  credentials are needed and the GUI stays consistent.
- **Your data is yours.** The plugin never touches it. You provide hook scripts,
  because only you know what your data is.

### 📦 Installation

Plugins → Install Plugin, and paste:

```
https://raw.githubusercontent.com/Nebur692/failover-guard-unraid-plugin/main/failover-guard.plg
```

Then go to **Settings → Failover Guard**.

### ⚙️ Configuration

| Setting | What it does |
|---|---|
| `ORIGIN_HOST` | Real host name of the remote server. **Not** the public domain: if your domain sits behind a CDN it answers even when the origin is dead. |
| `ORIGIN_PORTS` | TCP ports that prove the machine is alive. |
| `HEALTH_PATH` | Optional but strongly recommended. An HTTP path on the origin, requested by IP so any CDN is bypassed. |
| `HEALTH_EXPECT` | String the response must contain to count as healthy. |
| `DOMAIN` | The Cloudflare zone to switch. |
| `FAILOVER_TARGET` | Host name (becomes a CNAME) or IP (becomes an A record) pointing at your Unraid box. A dynamic DNS name with a short TTL works best. |
| `CF_TOKEN` | Cloudflare API token. Needs Zone:Read and DNS:Edit on that zone only. |
| `CHECK_INTERVAL` / `FAIL_THRESHOLD` | Detection time is roughly interval × threshold. |
| `NPM_*` | Optional. Data path, container name and the proxy host ID to enable during a failover. |
| `HOOK_REPLICATE` | Runs while the origin is healthy: copies origin → here. |
| `HOOK_PRE_FAILBACK` | Runs before returning: copies here → origin. |

#### A note on DNS speed

If your Cloudflare records are proxied, visitors always resolve to Cloudflare's
own addresses, which never change — what changes is the origin Cloudflare talks
to behind the scenes. That means **the switch does not wait for any TTL to expire
on the client side**, which is what normally makes DNS failover slow.

#### Hooks, and why they matter

The plugin moves DNS and toggles a proxy host. It does not move databases or
files, because it has no way of knowing what yours are.

The **pre-failback hook** is the important one. It runs *after* the local host has
already been disabled, so nothing can be written while the copy is in flight, and
it copies **from your Unraid box to the origin** — never the other way around.
While the domain pointed here, this is where new data was written; pulling from
the origin would erase it. If the hook fails, the failback is aborted and your
box keeps serving, rather than losing whatever arrived during the outage.

### 🧭 Usage

Use **Run checks** on the settings page to see every probe evaluated at once
without changing anything. It reports the local network, the origin ports, the
application health check, whether the failover target is ready, the NPM host
state and whether the watcher is running.

The log lives at `/var/log/failover-guard.log`.

### 🩹 Troubleshooting

- **The watcher shows as stopped.** It only runs when the plugin is enabled. A
  supervisor re-launches it every five minutes, so it also recovers by itself
  after a crash or an array restart.
- **"Failover NOT performed".** The failover target was not reachable, or your
  dynamic DNS still points at an old public IP.
- **Nothing switched even though the origin is down.** If a replicate hook is
  configured but has never run successfully, the plugin refuses to switch: it
  would be serving an empty copy, which is worse than the outage.

### 💙 Support

None of this would be possible without the community's support. If this project
has been useful to you, consider supporting it on
[Ko-fi](https://ko-fi.com/nebur69265723) or [PayPal](https://paypal.me/0SkillS) —
every bit helps keep it maintained.

### ⚠️ Disclaimer

This plugin changes public DNS records and can take a live site offline if it is
misconfigured. Test it with **Run checks** before enabling it, and read the note
about hooks above: data loss during a failback is the one mistake this design
cannot undo for you.

---

## Español

Un plugin de Unraid que vigila un origen remoto — un VPS, un servidor dedicado,
cualquier cosa que sirva un dominio — y, cuando deja de responder, cambia los
registros DNS de Cloudflare de ese dominio a tu servidor Unraid y habilita el host
correspondiente en Nginx Proxy Manager. Cuando el origen vuelve, lo devuelve todo.

La regla que gobierna todo el diseño: **en cada momento solo un lado acepta
escrituras**, y los datos van siempre desde ese lado hacia el otro, nunca en las
dos direcciones.

### ✨ Características

- **Detección en segundos, no en minutos.** Un vigilante permanente comprueba cada
  10 segundos por defecto, así que un origen caído se detecta en unos 30 segundos.
  Un cron cada cinco minutos tardaría hasta quince.
- **Tres barreras contra los falsos positivos.** No se cuenta el fallo cuando es tu
  propio servidor el que no tiene salida a Internet: el origen puede estar
  perfectamente y ser cosa tuya, y además conmutar sería inútil porque nadie
  podría llegar hasta ti. No se acepta un puerto TCP abierto como prueba de salud
  cuando hay una ruta de salud configurada, porque una máquina puede arrancar con
  el servidor web muerto. Y hacen falta varios fallos seguidos antes de mover nada.
- **No conmuta hacia un callejón sin salida.** Antes de tocar el DNS comprueba que
  el destino resuelve de verdad y que tu DNS dinámico está al día con tu IP pública
  actual. Mandar a los usuarios a ninguna parte es peor que dejar la caída como está.
- **Nginx Proxy Manager, sin usar su API.** El host local permanece deshabilitado
  mientras el origen está sano, para que nunca haya dos copias aceptando
  escrituras. Solo se habilita durante un failover. Se hace igual que lo hace NPM
  por dentro, así que no hacen falta credenciales y el GUI queda coherente.
- **Tus datos son tuyos.** El plugin no los toca. Tú pones los scripts de enganche,
  porque solo tú sabes cuáles son tus datos.

### 📦 Instalación

Plugins → Install Plugin, y pega:

```
https://raw.githubusercontent.com/Nebur692/failover-guard-unraid-plugin/main/failover-guard.plg
```

Después ve a **Settings → Failover Guard**.

### ⚙️ Configuración

| Ajuste | Qué hace |
|---|---|
| `ORIGIN_HOST` | Nombre real del servidor remoto. **No** el dominio público: si el dominio pasa por un CDN, responde aunque el origen esté muerto. |
| `ORIGIN_PORTS` | Puertos TCP que demuestran que la máquina está viva. |
| `HEALTH_PATH` | Opcional pero muy recomendable. Una ruta HTTP del origen, pedida por IP para saltarse cualquier CDN. |
| `HEALTH_EXPECT` | Texto que debe contener la respuesta para darla por sana. |
| `DOMAIN` | La zona de Cloudflare que se conmuta. |
| `FAILOVER_TARGET` | Nombre de host (se pone como CNAME) o IP (registro A) que apunte a tu Unraid. Lo ideal es un DNS dinámico con TTL corto. |
| `CF_TOKEN` | Token de API de Cloudflare. Necesita Zone:Read y DNS:Edit solo sobre esa zona. |
| `CHECK_INTERVAL` / `FAIL_THRESHOLD` | El tiempo de detección es aproximadamente intervalo × fallos. |
| `NPM_*` | Opcional. Ruta de datos, nombre del contenedor y el ID del proxy host que se habilita durante el failover. |
| `HOOK_REPLICATE` | Se ejecuta mientras el origen está sano: copia origen → aquí. |
| `HOOK_PRE_FAILBACK` | Se ejecuta antes de volver: copia aquí → origen. |

#### Una nota sobre la velocidad del DNS

Si tus registros de Cloudflare están en modo *proxied*, los visitantes resuelven
siempre a direcciones de Cloudflare, que no cambian nunca — lo que cambia es el
origen con el que habla Cloudflare por detrás. Eso significa que **la conmutación
no espera a que caduque ningún TTL en el lado del cliente**, que es justo lo que
suele hacer lento un failover por DNS.

#### Los enganches, y por qué importan

El plugin mueve el DNS y enciende o apaga un proxy host. No mueve bases de datos
ni ficheros, porque no tiene forma de saber cuáles son los tuyos.

El **enganche previo al failback** es el importante. Se ejecuta *después* de haber
deshabilitado el host local, así que nada puede escribirse mientras la copia está
en vuelo, y copia **desde tu Unraid hacia el origen** — nunca al revés. Mientras
el dominio apuntaba aquí, es aquí donde se escribieron los datos nuevos; traerlos
del origen los borraría. Si el enganche falla, el failback se aborta y tu servidor
sigue sirviendo, en vez de perder lo que llegó durante la caída.

### 🧭 Uso

Usa **Comprobar** en la página de ajustes para ver todas las sondas evaluadas de
una vez sin cambiar nada. Informa de la red local, los puertos del origen, la
comprobación de salud de la aplicación, si el destino del failover está listo, el
estado del host de NPM y si el vigilante está corriendo.

El registro está en `/var/log/failover-guard.log`.

### 🩹 Resolución de problemas

- **El vigilante aparece parado.** Solo corre con el plugin activado. Un supervisor
  lo relanza cada cinco minutos, así que también se recupera solo tras un fallo o
  un reinicio de la matriz.
- **"Failover NOT performed".** El destino no era alcanzable, o tu DNS dinámico
  sigue apuntando a una IP pública antigua.
- **No ha conmutado aunque el origen está caído.** Si hay un enganche de réplica
  configurado que nunca ha llegado a ejecutarse con éxito, el plugin se niega a
  conmutar: estaría sirviendo una copia vacía, que es peor que la caída.

### 💙 Apoya el proyecto

Sin el apoyo de la comunidad estos proyectos no serían posibles. Si te ha resultado
útil, puedes apoyarlo en [Ko-fi](https://ko-fi.com/nebur69265723) o
[PayPal](https://paypal.me/0SkillS) — cualquier aportación ayuda a seguir
manteniéndolo.

### ⚠️ Aviso

Este plugin cambia registros DNS públicos y puede tirar un sitio en producción si
está mal configurado. Pruébalo con **Comprobar** antes de activarlo, y lee la nota
sobre los enganches: la pérdida de datos en un failback es el único error que este
diseño no puede deshacer por ti.
