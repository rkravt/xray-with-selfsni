#!/bin/bash

# Удаление Xray через официальный скрипт установки
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

# Удаление конфигурационной директории Xray
rm -rf /usr/local/etc/xray

# Удаление пользовательских скриптов
rm -f /usr/local/bin/userlist
rm -f /usr/local/bin/mainuser
rm -f /usr/local/bin/newuser
rm -f /usr/local/bin/rmuser
rm -f /usr/local/bin/sharelink
