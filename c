#!/usr/bin/env bash
# Подключает documentmd.online к уже работающему Caddy (postscriptum) без перезапуска контейнеров.
set -uo pipefail
C=postscriptum-caddy-1
CF=/opt/postscriptum/deploy/Caddyfile
VOL=/var/lib/docker/volumes/postscriptum_caddy_data/_data
DST=$VOL/sites/documentmd.online
y(){ printf '\n\033[1;33m== %s\033[0m\n' "$*"; }

y "1. Проверки"
docker ps --format '{{.Names}}' | grep -qx "$C" || { echo "Контейнер $C не найден"; exit 1; }
[ -f "$CF" ] && [ -d "$VOL" ] || { echo "Нет Caddyfile или тома"; exit 1; }
BK="$CF.bak-$(date +%Y%m%d-%H%M%S)"; cp -a "$CF" "$BK"; echo "Резервная копия: $BK"

y "2. Файлы сайта"
TMP=$(mktemp -d)
curl -fsSL https://github.com/postscriptumhead/documentmd-media/archive/refs/heads/main.tar.gz | tar -xz -C "$TMP" || { echo "Не удалось скачать"; exit 1; }
rm -rf "$DST"; mkdir -p "$DST"; cp -a "$TMP"/documentmd-media-main/site/. "$DST"/; rm -rf "$DST/_deploy"
docker exec "$C" ls /data/sites/documentmd.online | head -20

y "3. Блок в Caddyfile"
if grep -q 'documentmd.online' "$CF"; then echo "Блок уже есть, не дублирую"; else
cat >> "$CF" <<'BLOCK'

# --- documentmd.online (статический сайт) ---
documentmd.online {
	root * /data/sites/documentmd.online
	encode zstd gzip
	file_server
	handle_errors {
		rewrite * /404.html
		file_server
	}
	header {
		X-Content-Type-Options nosniff
		Referrer-Policy strict-origin-when-cross-origin
		X-Frame-Options SAMEORIGIN
		Permissions-Policy "camera=(), microphone=(), geolocation=()"
		-Server
	}
	@static path /assets/* /favicon.svg /og.png /apple-touch-icon.png
	header @static Cache-Control "public, max-age=2592000"
}

www.documentmd.online {
	redir https://documentmd.online{uri} permanent
}
BLOCK
fi

y "4. Проверка конфига и перезагрузка Caddy (без остановки)"
if docker exec "$C" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/tmp/cv.log 2>&1 && \
   docker exec "$C" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile; then
  echo "Caddy перезагружен"
else
  tail -5 /tmp/cv.log; echo "ОШИБКА: возвращаю прежний Caddyfile"; cat "$BK" > "$CF"
  docker exec "$C" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile; exit 1
fi

y "5. Проверка сайта (сертификат выпускается до минуты)"
for i in 1 2 3 4 5 6; do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://documentmd.online/) && [ "$code" = 200 ] && break; sleep 10; done
echo "https://documentmd.online -> $code"
curl -s -o /dev/null -w "www -> %{http_code} %{redirect_url}\n" https://www.documentmd.online/
y "6. Git в /opt/postscriptum (если есть)"
cd /opt/postscriptum 2>/dev/null && git status --short 2>/dev/null | head -5
echo "Готово"
