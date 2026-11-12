#!/usr/bin/env bash
# Установка сайта documentmd.online рядом с существующим сайтом. Запуск: curl -fsSL <url>/s | bash
set -uo pipefail
DOM=documentmd.online; ROOT=/var/www/$DOM
SRC=https://github.com/postscriptumhead/documentmd-media/archive/refs/heads/main.tar.gz
say(){ printf '\n\033[1;33m== %s\033[0m\n' "$*"; }
say "1. Что уже стоит на сервере"
command -v nginx apache2 caddy docker 2>/dev/null
ss -ltnp | grep -E ':80 |:443 ' || echo "(80/443 никто не слушает)"
PORT80=$(ss -ltnp | grep -E ':80 ' | head -1)
if echo "$PORT80" | grep -q docker-proxy || echo "$PORT80" | grep -q caddy || echo "$PORT80" | grep -q traefik; then
  say "Порт 80 занят Docker/Caddy/Traefik. Автонастройку останавливаю, пришлите этот экран."; exit 1; fi
if echo "$PORT80" | grep -q apache; then MODE=apache
elif echo "$PORT80" | grep -q nginx; then MODE=nginx
elif [ -z "$PORT80" ]; then MODE=newnginx
else say "Порт 80 занят неизвестной программой: $PORT80. Пришлите этот экран."; exit 1; fi
echo "Режим: $MODE"

say "2. Скачиваю файлы сайта"
TMP=$(mktemp -d); curl -fsSL "$SRC" | tar -xz -C "$TMP" || { echo "Не удалось скачать"; exit 1; }
mkdir -p "$ROOT"; cp -a "$TMP"/documentmd-media-main/site/. "$ROOT"/; rm -rf "$ROOT/_deploy"
chown -R www-data:www-data "$ROOT" 2>/dev/null; ls "$ROOT"

if [ "$MODE" = newnginx ]; then say "3. Ставлю nginx"; apt-get update -qq && apt-get install -y -qq nginx; MODE=nginx; fi
if [ "$MODE" = nginx ]; then
  say "3. Конфиг nginx"
  cp "$TMP"/documentmd-media-main/site/_deploy/nginx-documentmd.online.conf /etc/nginx/sites-available/$DOM
  ln -sf /etc/nginx/sites-available/$DOM /etc/nginx/sites-enabled/$DOM
  nginx -t && systemctl reload nginx || { echo "Ошибка конфига, откатываю"; rm -f /etc/nginx/sites-enabled/$DOM; systemctl reload nginx; exit 1; }
  PLUG=nginx; PKG=python3-certbot-nginx
else
  say "3. Конфиг Apache"
  cp "$TMP"/documentmd-media-main/site/_deploy/apache-documentmd.online.conf /etc/apache2/sites-available/$DOM.conf
  a2ensite $DOM >/dev/null && apache2ctl configtest && systemctl reload apache2 || { a2dissite $DOM; systemctl reload apache2; exit 1; }
  PLUG=apache; PKG=python3-certbot-apache
fi

say "4. Проверка DNS"
MYIP=$(curl -fsS -4 https://api.ipify.org || hostname -I | awk '{print $1}')
DNSIP=$(getent ahostsv4 $DOM | awk 'NR==1{print $1}')
echo "IP сервера: $MYIP, DNS $DOM: $DNSIP"
if [ "$MYIP" != "$DNSIP" ]; then say "DNS ещё не обновился. Сайт уже настроен, HTTPS запустите позже: повторите эту же команду через 30-60 минут."; exit 0; fi

say "5. HTTPS-сертификат"
command -v certbot >/dev/null || apt-get install -y -qq certbot $PKG
certbot --$PLUG -n --agree-tos --register-unsafely-without-email --redirect -d $DOM -d www.$DOM
say "Готово: https://$DOM"
curl -sS -o /dev/null -w "Проверка: HTTP %{http_code}\n" https://$DOM
