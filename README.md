> [!IMPORTANT] 
> Можете воспользоваться [Zapret Manager](https://github.com/StressOzz/Zapret-Manager)
>
> В нём реализована установка [**NetShift**](https://github.com/yandexru45/netshift) и [**Mixomo**](https://github.com/Internet-Helper/mixomo-openwrt) - с возможностью интеграции [**VPN подписки**](https://github.com/StressOzz/StressKVN), а также генерации и интеграции **WARP** и интеграции **ByeDPI**...

<h1 align="center">Podkop Manager</h1>

<div align="center">

![Platform](https://img.shields.io/badge/Platform-OpenWrt-orange)
![Architecture](https://img.shields.io/badge/Architecture-All%20(OpenWrt)-yellow)
![Script](https://img.shields.io/badge/Script-sh-informational)
![Status](https://img.shields.io/badge/Status-Active-success)
![Community](https://img.shields.io/badge/Community-Enabled-green)
[![Views](https://views.whatilearened.today/views/github/StressOzz/Podkop-Manager.svg)](https://github.com/StressOzz/Podkop-Manager)
![GitHub last commit](https://img.shields.io/github/last-commit/StressOzz/Zapret-Manager)

</div>

<p align="center">
  <a href="https://t.me/stressozz_manager">💬 Telegram Community</a>
</p>


---

### **StressKVN** - умный VPN для стабильного доступа в любых условиях

- ✅ Работает даже при жёсткой фильтрации и в условиях белых списков
- 🌍 Умная маршрутизация: иностранные ресурсы через VPN, российский трафик напрямую
- ⚡ Высокая скорость и безлимитный трафик
- 📶 Можно использовать на роутере (OpenWRT)
- ▶️ YouTube без рекламы
- 🎁 Бесплатный тест — 3 дня без оплаты

Подробнее: **https://github.com/StressOzz/StressKVN**

---

## Запуск менеджера

Подключитесь по **SSH** к роутеру и выполните команду:
> [!IMPORTANT]
> Если у Вас доступен **githubusercontent.com**:
```
sh <(wget -qO - 'https://raw.githubusercontent.com/StressOzz/Podkop-Manager/main/Podkop-Manager.sh')
```
> [!IMPORTANT]
> Если у Вас **НЕ** доступен **githubusercontent.com**:
```
sh <(wget -qO - 'https://gh-proxy.org/https://raw.githubusercontent.com/StressOzz/Podkop-Manager/main/Podkop-Manager.sh')
```

> [!NOTE]
> Рекомендуется устанавливать на "чистый" роутер !

> [!WARNING]
> Все настройки Podkop будут сброшены !

---

<table>
  <tr>
    <td>
      <a href="https://github.com/StressOzz#-поддержать-проект">
        <img width="280" height="130" src="https://github.com/user-attachments/assets/2999757b-fbf3-4149-bf6c-48bf3e241529">
      </a>
    </td>
    <td>
      <a href="https://github.com/StressOzz/StressKVN">
        <img width="280" height="130" alt="image" src="https://github.com/user-attachments/assets/519a126e-bd39-4f46-8a09-3f0d6e1dd8af">
      </a>
    </td>
  </tr>
</table>

---

## Основные функции

### 1) Установить Podkop
Устанавливает последнию версию Podkop
### 2) Удалить Podkop
Удаляеет Podkop
### 3) Установить ByeDPI
Устанавливает последнию версию ByeDPI
### 4) Удалить ByeDPI
Удаляеет ByeDPI
### 5) Интегрировать ByeDPI в Podkop
Настривает Podkop для работы с ByeDPI (все настройки Podkop будут сброшены)
### 6) Изменить текущую стратегию ByeDPI
Позволяет изменить стратегию ByeDPI
### 7) Установить AWG и интерфейс AWG
Устанавливает AmneziaWG и интерфейс AWG
### 8) Удалить AWG и интерфейс AWG
Удаляеет AmneziaWG и интерфейс AWG
### 9) Интегрировать AWG в Podkop
Настривает Podkop для работы с AWG (все настройки Podkop будут сброшены)
### 0) Меню выбора зеркала OpenWrt
Позволяет выбрать зеркало для пакетов OpenWRT
### r) Перезагрузить устройство
Reboot

## Советы по использованию

- После первой интеграции ByeDPI обязательно перезагрузите роутер

- Необходимо загрузить конфиг Amnezia в **Network → Interfaces → AWG → Edit → Load configuration…**

- В конфиге Amnezia, обязательно должна быть строчка `PersistentKeepalive = 25`

- Рекомендовано подождать 30 секунд после перезагрузки устройства, чтобы все службы (ByeDPI, Podkop, sing-box, DNS и маршрутизация) полностью запустились и вступили в силу

- Если **GitHub** выдаёт ошибку лимита запросов — подождите 30–60 минут

- При смене стратегии **ByeDPI** (пункт 4) можно не перезагружать устройство

- Всё что связанно с **Podkop** можно прочитать в [Документация](https://podkop.net/)

---

## Большое спасибо

- **[itdoginfo](https://github.com/itdoginfo)** за [podkop](https://github.com/itdoginfo/podkop)
- **[hufrea](https://github.com/hufrea)** за [byedpi](https://github.com/hufrea/byedpi)
- [**Slava-Shchipunov**](https://github.com/Slava-Shchipunov) за [AmneziaWG for OpenWrt](https://github.com/Slava-Shchipunov/awg-openwrt)
- **[spvkgn](https://github.com/spvkgn)** за GitHub Actions
- **[romanvht](https://github.com/romanvht)** за возможность тестировать стратегии
- **[DPITrickster](https://github.com/DPITrickster)** за версию ByeDPI для OpenWRT и за написание гайда по ручной установке
