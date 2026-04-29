# WiFi Manager для OpenWrt

Веб-интерфейс для управления WiFi устройствами на роутерах с OpenWrt.

## Возможности

- 📡 Список подключённых устройств
- ⛔ Блокировка/разблокировка устройств по MAC
- 🔒 Блокировка всех устройств (кроме белого списка)
- ⚪ Белый список
- ⏰ Расписание блокировки
- 🕐 Часы реального времени
- ✏️ Переименовывание устройств (понятные имена вместо DHCP hostname)
- 🔁 Множественные интервалы расписания для одного устройства
- 🕐 Одноразовые правила по дате и времени (с автоудалением после выполнения)

## Установка

### Авто-определение версии (рекомендуется)

```sh
wget -O /tmp/install.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install.sh
chmod +x /tmp/install.sh
/tmp/install.sh auto
```

### OpenWrt 24

## Установка через пакет

Пакетная установка поддерживается только для OpenWrt 24.

Для обычной установки используйте готовый `.ipk` из релиза:

- [Releases](https://github.com/DjgaaD/RusControl/releases)

Установка:

Через LuCI:

- `Система -> ПО -> Загрузить пакет`, выбрать `.ipk`.

Через SSH:

```sh
opkg install /tmp/luci-app-ruscontrol-owrt24_1.5.0-1_all.ipk
```
или
```sh
wget -O /tmp/install_openwrt24.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install_openwrt24.sh
chmod +x /tmp/install_openwrt24.sh
/tmp/install_openwrt24.sh
```

### OpenWrt 25

Для OpenWrt 25 используйте установку через команды по SSH:

```sh
wget -O /tmp/install_openwrt25.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install_openwrt25.sh
chmod +x /tmp/install_openwrt25.sh
/tmp/install_openwrt25.sh
```

### Обновление существующей установки

```sh
wget -O /tmp/install.sh https://raw.githubusercontent.com/DjgaaD/RusControl/main/install.sh
chmod +x /tmp/install.sh
/tmp/install.sh auto
```

## Примечания

- `install.sh` поддерживает параметры: `24`, `25`, `auto`.
- Установщик скачивает файлы с GitHub и автоматически использует fallback на `main`, если версия-ветка недоступна.
