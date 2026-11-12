#!/usr/bin/env bash
# Диагностика: какой Docker-контейнер держит 80/443 и как он настроен (ничего не меняет)
y(){ printf '\033[1;33m== %s\033[0m\n' "$*"; }
y "контейнеры"; docker ps --format '{{.Names}} | {{.Image}} | {{.Ports}}'
for c in $(docker ps --format '{{.Names}}'); do
  if docker port "$c" 2>/dev/null | grep -qE '^(80|443)/'; then
    y "прокси: $c"
    docker inspect "$c" --format 'image={{.Config.Image}} compose={{index .Config.Labels "com.docker.compose.project.working_dir"}}'
    docker inspect "$c" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' | head -8
    docker inspect "$c" --format '{{range .Config.Cmd}}{{.}} {{end}}' | cut -c1-300
  fi
done
y "домены в labels/env других контейнеров"
for c in $(docker ps --format '{{.Names}}'); do
  docker inspect "$c" --format '{{range $k,$v := .Config.Labels}}{{if or (eq $k "caddy") (printf "%.15s" $k | eq "traefik.http.ro")}}{{$k}}={{$v}}{{println}}{{end}}{{end}}{{range .Config.Env}}{{if or (printf "%.12s" . | eq "VIRTUAL_HOST") (printf "%.13s" . | eq "LETSENCRYPT_H")}}{{.}}{{println}}{{end}}{{end}}' 2>/dev/null | grep . | sed "s/^/$c: /" | head -6
done
