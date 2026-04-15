# WiFi Manager для OpenWrt

Веб-интерфейс для управления WiFi устройствами на роутерах с OpenWrt.

## Структура версий

- `openwrt24/` — упаковка и артефакты для OpenWrt 24.
- `openwrt25/` — скрипты установки для OpenWrt 25.
- `cgi-bin/` и `luci/` — общие исходники приложения для обеих версий.

## Возможности

- 📡 Список подключённых устройств
- ⛔ Блокировка/разблокировка устройств по MAC
- 🔒 Блокировка всех устройств (кроме белого списка)
- ⚪ Белый список
- ⏰ Расписание блокировки
- 🕐 Часы реального времени

## Установка

### OpenWrt 24

```sh
wget -O /tmp/install_openwrt24.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install_openwrt24.sh
chmod +x /tmp/install_openwrt24.sh
/tmp/install_openwrt24.sh
```

### OpenWrt 25

```sh
wget -O /tmp/install_openwrt25.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install_openwrt25.sh
chmod +x /tmp/install_openwrt25.sh
/tmp/install_openwrt25.sh
```

### Авто-определение версии (рекомендуется)

```sh
wget -O /tmp/install.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install.sh
chmod +x /tmp/install.sh
/tmp/install.sh auto
```

## Установка через пакет

Пакетная установка поддерживается только для OpenWrt 24.

### OpenWrt 24 (`.ipk`)

Для обычной установки используйте готовый `.ipk` из релиза:

- [Releases](https://github.com/DjgaaD/RusControl/releases)

Установка:

Через LuCI:

- `Система -> ПО -> Загрузить пакет`, выбрать `.ipk`.

Через SSH:

```sh
opkg install /tmp/luci-app-ruscontrol-owrt24_1.0.0-1_all.ipk
```

### OpenWrt 25

Для OpenWrt 25 используйте установку через команды:

```sh
wget -O /tmp/install_openwrt25.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install_openwrt25.sh
chmod +x /tmp/install_openwrt25.sh
/tmp/install_openwrt25.sh
```

## Примечания

- `install.sh` поддерживает параметры: `24`, `25`, `auto`.
- Установщик скачивает файлы с GitHub и автоматически использует fallback на `main`, если версия-ветка недоступна.
