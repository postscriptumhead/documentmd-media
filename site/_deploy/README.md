# Запуск documentmd.online на сервере (рядом с уже работающим сайтом)

1. DNS (у регистратора домена): A-запись `documentmd.online` → IP сервера, A-запись (или CNAME) `www` → то же.
   Если домен у SpaceWeb, это делается в их панели, раздел DNS. Обновление занимает от нескольких минут до суток.
2. На сервере: `sudo mkdir -p /var/www/documentmd.online && sudo chown $USER /var/www/documentmd.online`
3. С компьютера, из папки site: `bash _deploy/deploy.sh user@IP` (или залить файлы любым FTP/SFTP-клиентом).
4. Конфиг веб-сервера: `nginx-documentmd.online.conf` (nginx) или `apache-documentmd.online.conf` (Apache), команды в шапке файла.
5. HTTPS: `sudo certbot --nginx -d documentmd.online -d www.documentmd.online`
6. Проверка: https://documentmd.online, https://documentmd.online/privacy.html, несуществующая страница → 404.

Перед запуском заполнить в privacy.html: оператор, IDNO, адрес, e-mail, сроки хранения.
