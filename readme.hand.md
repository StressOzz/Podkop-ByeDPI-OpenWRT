Русский | [English](readme.en.md)

# Гайд по установке и настройке **Podkop** вместе с **ByeDPI** на OpenWrt.

> [!IMPORTANT]
> Если ваш провайдер перехватывает DNS-запросы - требуются меры по их защите, иначе ByeDPI не будет работать.
> Podkop несовместим с пакетом `https-dns-proxy` и схема FakeIP может затруднить поиск подходящего решения для противодействия перехвату DNS.
---

## 0. Установка Podkop

Вся нужная информация о Podkop находится в [readme](https://github.com/itdoginfo/podkop?tab=readme-ov-file) репозитория и на [сайте](https://podkop.net/) с документацией.

## 1. Установка ByeDPI

### Узнайте архитектуру устройства

```sh
opkg print-architecture
awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release
```

### Скачайте нужный пакет

Замените `aarch64_cortex-a53` на свою архитектуру:

```sh
(cd /tmp && curl -LO https://github.com/DPITrickster/ByeDPI-OpenWrt/releases/download/v0.17.2-24.10/byedpi_0.17.2-r1_aarch64_cortex-a53.ipk)
```

### Установите пакет

> [!NOTE]
> При необходимости удалите старую версию.

```sh
opkg remove byedpi
opkg install /tmp/byedpi_0.17.2-r1_aarch64_cortex-a53.ipk
```

### Оредактируйте конфиг ByeDPI

#### Откройте файл:

> [!NOTE]
> В примере используется текстовый редактор `vi`, так как он является предустановленным.

```sh
vi /etc/config/byedpi
```

#### Добавьте рабочую стратегию (пример):

```sh
config byedpi
    option enabled '1'
    option cmd_opts '-o 2 --auto=t,r,a,s -d 2'
```

> [!WARNING]
> Подберите стратегию при помощи [ByeByeDPI](https://github.com/romanvht/ByeByeDPI) или [ByeDPI Manager](https://github.com/romanvht/ByeDPIManager) (желательно заранее).

### Запустите сервис

```sh
/etc/init.d/byedpi enable
/etc/init.d/byedpi start
```

### Для OpenWrt 24.10 отключите использование `dnsmasq` в качестве локального резолвера

```sh
uci set dhcp.@dnsmasq[0].localuse='0'
uci commit dhcp
```

и вполнить
```
/etc/init.d/dnsmasq restart
```

---

## 2. Настройка Podkop

### Добавьте Outbound для ByeDPI

Тип Outbound'а - `Proxy`. Тип конфигурации - `Outbound Config`.

Outbound Configuration:

```json
{
  "type": "socks",
  "server": "127.0.0.1",
  "server_port": 1080
}
```

> [!NOTE]
> Не забудьте добавить нужные [списки](https://podkop.net/docs/sections/), с которыми будет взаимодействовать ByeDPI.

---

## 3. Финальные шаги

### Перезагрузите роутер

```sh
reboot
```

### Проверьте работу ByeDPI

```sh
ps | grep byedpi
netstat -tulnp | grep 1080
```

Если процессы активны — всё работает.

---

## Большое спасибо

- **[itdoginfo](https://github.com/itdoginfo)** за [podkop](https://github.com/itdoginfo/podkop)
- **[hufrea](https://github.com/hufrea)** за [byedpi](https://github.com/hufrea/byedpi)
- **[spvkgn](https://github.com/spvkgn)** за GitHub Actions
- **[romanvht](https://github.com/romanvht)** за возможность тестировать стратегии
- **[DPITrickster](https://github.com/DPITrickster)** за версию для OpenWRT и за написание этого гайда
