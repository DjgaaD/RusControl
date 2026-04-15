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

В репозитории есть сборщик:

- `openwrt24/packaging/ipk/build_ipk.sh`

Пример:

```sh
chmod +x openwrt24/packaging/ipk/build_ipk.sh
./openwrt24/packaging/ipk/build_ipk.sh 24 1.0.0 1
```

Будет создан файл:

- `dist/luci-app-ruscontrol-owrt24_<version>-<release>_all.ipk`

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
- Для версий 24/25 используются отдельные ветки: `openwrt-24` и `openwrt-25`.
- Если версия не определена, установщик использует ветку `main`.
