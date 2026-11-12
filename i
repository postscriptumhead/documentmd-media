#!/usr/bin/env bash
# 1) показывает, откуда берётся проект postscriptum; 2) ставит «самовосстановление» блока documentmd.online
set -uo pipefail
P=/opt/postscriptum; CF=$P/deploy/Caddyfile; C=postscriptum-caddy-1; K=/root/documentmd
y(){ printf '\n\033[1;33m== %s\033[0m\n' "$*"; }
y "Проект postscriptum"
git -C $P remote -v 2>/dev/null | head -2
git -C $P log -3 --format='%cd  %an  %s' --date=short 2>/dev/null
ls $P | head -20
y "Сохраняю блок и убираю бэкап из папки проекта"
mkdir -p $K
mv -n $P/deploy/Caddyfile.bak-* $K/ 2>/dev/null
awk '/# --- documentmd.online/{f=1} f' "$CF" > $K/caddy-block.txt
wc -l $K/caddy-block.txt
cat > $K/heal.sh <<'H'
#!/usr/bin/env bash
CF=/opt/postscriptum/deploy/Caddyfile; C=postscriptum-caddy-1; B=/root/documentmd/caddy-block.txt
grep -q 'documentmd.online' "$CF" && exit 0
[ -s "$B" ] || exit 0
printf '\n' >> "$CF"; cat "$B" >> "$CF"
docker exec "$C" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile && logger "documentmd: блок восстановлен"
H
chmod +x $K/heal.sh
echo '*/5 * * * * root /root/documentmd/heal.sh >/dev/null 2>&1' > /etc/cron.d/documentmd-heal
y "Готово: каждые 5 минут блок documentmd.online проверяется и при необходимости восстанавливается"
cat /etc/cron.d/documentmd-heal
