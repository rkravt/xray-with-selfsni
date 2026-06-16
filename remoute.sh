#!/bin/bash

# ============================================
# 1. Удаление Xray (официальный скрипт)
# ============================================
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

# Удаление конфигурационной директории Xray
rm -rf /usr/local/etc/xray

# Удаление пользовательских скриптов
rm -f /usr/local/bin/userlist
rm -f /usr/local/bin/mainuser
rm -f /usr/local/bin/newuser
rm -f /usr/local/bin/rmuser
rm -f /usr/local/bin/sharelink

# ============================================
# 2. Удаление nginx
# ============================================
# Останавливаем службу, если запущена
systemctl stop nginx 2>/dev/null

# Удаляем пакеты nginx и зависимости (purge удаляет конфиги)
apt purge -y nginx nginx-common nginx-core 2>/dev/null

# Дополнительно удаляем вручную оставшиеся файлы (на всякий случай)
rm -rf /etc/nginx
rm -rf /var/log/nginx
rm -rf /var/www/html/*   # чистим стандартную веб-директорию (включая index.html)

# Удаляем конкретные index-файлы, если они ещё где-то есть (повторно)
rm -f /var/www/html/index.nginx-debian.html
rm -f /var/www/html/index.html

# Убираем неиспользуемые зависимости (автоочистка)
apt autoremove -y

echo "Удаление Xray и nginx завершено."