#!/usr/bin/env bash
# Заливка сайта на сервер. Запуск из папки site:  bash _deploy/deploy.sh user@IP_СЕРВЕРА
set -euo pipefail
SERVER="${1:?укажите user@ip}"
rsync -avz --delete --exclude '_deploy' --exclude '.DS_Store' ./ "$SERVER":/var/www/documentmd.online/
echo "Готово: файлы на сервере в /var/www/documentmd.online"
