#!/bin/sh
# ==========================================
# ByeDPI & Podkop Manager by StressOzz
# ==========================================

# Цвета
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
NC="\033[0m"
WHITE="\033[1;37m"
BLUE="\033[0;34m"
GRAY='\033[38;5;239m'
DGRAY="\033[38;5;244m"

WORKDIR="/tmp/byedpi"

PODKOP_LATEST_VER="0.7.10"

BYEDPI_VER="0.17.3-r1"
BYEDPI_ARCH="$LOCAL_ARCH"
BYEDPI_FILE="byedpi_${BYEDPI_VER}_${BYEDPI_ARCH}.ipk"
BYEDPI_URL="https://github.com/DPITrickster/ByeDPI-OpenWrt/releases/download/v0.17.3-24.10/${BYEDPI_FILE}"


# ==========================================
# AWG
# ==========================================
install_AWG() {
echo -e "\n${MAGENTA}Устанавливаем AWG + интерфейс${NC}"
echo -e "${GREEN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }
PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')
TARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f1)
SUBTARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f2)
VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.ipk"
BASE_URL="https://github.com/FreeRKN/awg-openwrt/releases/download/"
AWG_DIR="/tmp/amneziawg"
mkdir -p "$AWG_DIR"
install_pkg() {
local pkgname=$1
local filename="${pkgname}${PKGPOSTFIX}"
local url="${BASE_URL}v${VERSION}/${filename}"
    if wget -O "$AWG_DIR/$filename" "$url" >/dev/null 2>&1 ; then
        echo -e "${CYAN}Устанавливаем ${NC}$pkgname"
        if ! opkg install "$AWG_DIR/$filename" >/dev/null 2>&1 ; then
            echo -e "\n${RED}Ошибка установки $pkgname!${NC}\n"
            read -p "Нажмите Enter..." dummy; return
        fi
    else
        echo -e "\n${RED}Ошибка! Не удалось скачать $filename${NC}\n"
        read -p "Нажмите Enter..." dummy; return
    fi
}
install_pkg "kmod-amneziawg"
install_pkg "amneziawg-tools"
install_pkg "luci-proto-amneziawg"
install_pkg "luci-i18n-amneziawg-ru" >/dev/null 2>&1 || echo -e "${RED}Внимание: русская локализация не установлена (не критично)${NC}"
rm -rf "$AWG_DIR"
echo -e "${YELLOW}Перезапускаем сеть! Подождите...${NC}"
/etc/init.d/network restart >/dev/null 2>&1
echo -e "AmneziaWG ${GREEN}установлен!${NC}"

echo -e "${MAGENTA}Устанавливаем интерфейс AWG${NC}"
IF_NAME="AWG"
PROTO="amneziawg"
DEV_NAME="amneziawg0"
if grep -q "config interface '$IF_NAME'" /etc/config/network; then
echo -e "${RED}Интерфейс ${NC}$IF_NAME${RED} уже существует${NC}"
else
echo -e "${CYAN}Добавляем интерфейс ${NC}$IF_NAME"
uci batch <<EOF
set network.$IF_NAME=interface
set network.$IF_NAME.proto=$PROTO
set network.$IF_NAME.device=$DEV_NAME
commit network
EOF
fi
echo -e "${CYAN}Перезапускаем сеть${NC}"
/etc/init.d/network restart
/etc/init.d/firewall restart
/etc/init.d/uhttpd restart
echo -e "${GREEN}Интерфейс ${NC}$IF_NAME${GREEN} создан и активирован!${NC}"
echo -e "${YELLOW}Вставьте рабочий конфиг в Interfaces (Интерфейс) AWG!${NC}\n"
read -p "Нажмите Enter..." dummy
}

# ==========================================
# Интеграция AWG
# ==========================================
integration_AWG() {

echo -e "\n${MAGENTA}Интегрируем AWG в Podkop${NC}"

echo -e "${GREEN}Меняем конфигурацию в ${NC}Podkop${GREEN}...${NC}"
    # Создаём / меняем /etc/config/podkop
    cat <<EOF >/etc/config/podkop
config settings 'settings'
	option dns_type 'udp'
	option dns_server '8.8.8.8'
	option bootstrap_dns_server '77.88.8.8'
	option dns_rewrite_ttl '60'
	list source_network_interfaces 'br-lan'
	option enable_output_network_interface '0'
	option enable_badwan_interface_monitoring '0'
	option enable_yacd '0'
	option disable_quic '0'
	option update_interval '1d'
	option download_lists_via_proxy '0'
	option dont_touch_dhcp '0'
	option config_path '/etc/sing-box/config.json'
	option cache_path '/tmp/sing-box/cache.db'
	option exclude_ntp '0'
	option shutdown_correctly '0'

config section 'main'
	option connection_type 'vpn'
	option interface 'AWG'
	option domain_resolver_enabled '0'
	option user_domain_list_type 'disabled'
	option user_subnet_list_type 'disabled'
	option mixed_proxy_enabled '0'
	list community_lists 'russia_inside'
	list community_lists 'hodca'
EOF

echo -e "AWG ${GREEN}интегрирован в ${NC}Podkop${GREEN}.${NC}"
echo -e "${CYAN}Запускаем ${NC}Podkop${NC}"
podkop enable >/dev/null 2>&1
echo -e "${CYAN}Применяем конфигурацию${NC}"
podkop reload >/dev/null 2>&1
podkop restart >/dev/null 2>&1
echo -e "${CYAN}Обновляем списки${NC}"
podkop list_update >/dev/null 2>&1
echo -e "${CYAN}Перезапускаем сервис${NC}"
podkop restart >/dev/null 2>&1
echo -e "Podkop ${GREEN}готов к работе!${NC}\n"
read -p "Нажмите Enter..." dummy
}

# ==========================================
# Определение версий
# ==========================================
get_versions() {

 # --- ByeDPI установленная версия ---
    BYEDPI_VER=$(opkg list-installed | grep '^byedpi ' | awk '{print $3}' | sed 's/-r[0-9]\+$//')
    [ -z "$BYEDPI_VER" ] && BYEDPI_VER="не найдена"

    # --- Архитектура ---
    LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
    [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v noarch | tail -n1 | awk '{print $2}')

    # --- Последняя версия (фиксированная) ---
    BYEDPI_LATEST_VER="0.17.3"

    # --- Podkop ---
    if command -v podkop >/dev/null 2>&1; then
        PODKOP_VER=$(podkop show_version 2>/dev/null | sed 's/-r[0-9]\+$//')
        [ -z "$PODKOP_VER" ] && PODKOP_VER="не найдена"
    else
        PODKOP_VER="не установлен"
    fi
	
    [ -z "$PODKOP_LATEST_VER" ] && PODKOP_LATEST_VER="не найдена"

    # --- Нормализация версий ---
    PODKOP_VER=$(echo "$PODKOP_VER" | sed 's/^v//')
    PODKOP_LATEST_VER=$(echo "$PODKOP_LATEST_VER" | sed 's/^v//')
    BYEDPI_VER=$(echo "$BYEDPI_VER" | sed 's/^v//')
    BYEDPI_LATEST_VER=$(echo "$BYEDPI_LATEST_VER" | sed 's/^v//')

    if [ "$BYEDPI_VER" = "не найдена" ] || [ "$BYEDPI_VER" = "не установлен" ]; then
        BYEDPI_STATUS="${RED}$BYEDPI_VER${NC}"
    elif [ "$BYEDPI_VER" != "$BYEDPI_LATEST_VER" ]; then
        BYEDPI_STATUS="${RED}$BYEDPI_VER${NC}"
    else
        BYEDPI_STATUS="${GREEN}$BYEDPI_VER${NC}"
    fi

    if [ "$PODKOP_VER" = "не найдена" ] || [ "$PODKOP_VER" = "не установлен" ]; then
        PODKOP_STATUS="${RED}$PODKOP_VER${NC}"
    elif [ "$PODKOP_LATEST_VER" != "не найдена" ] && [ "$PODKOP_VER" != "$PODKOP_LATEST_VER" ]; then
        PODKOP_STATUS="${RED}$PODKOP_VER${NC}"
    else
        PODKOP_STATUS="${GREEN}$PODKOP_VER${NC}"
    fi
	
}
# ==========================================
# Установка  ByeDPI
# ==========================================
install_ByeDPI() {
    echo -e "\n${MAGENTA}Установка ByeDPI${NC}"

    BYEDPI_VER="0.17.3-r1"
    BYEDPI_ARCH="$LOCAL_ARCH"
    BYEDPI_FILE="byedpi_${BYEDPI_VER}_${BYEDPI_ARCH}.ipk"
    BYEDPI_URL="https://github.com/DPITrickster/ByeDPI-OpenWrt/releases/download/v0.17.3-24.10/${BYEDPI_FILE}"

    echo -e "${GREEN}Скачиваем ${NC}${WHITE}$BYEDPI_FILE${NC}"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR" || return

    wget -q -U "Mozilla/5.0" -O "$BYEDPI_FILE" "$BYEDPI_URL" || {
        echo -e "${RED}Ошибка загрузки ${NC}$BYEDPI_FILE"
        read -p "Нажмите Enter..." dummy
        return
    }

    echo -e "${GREEN}Устанавливаем${NC} ${WHITE}$BYEDPI_FILE${NC}"
    opkg install --force-reinstall "$BYEDPI_FILE" >/dev/null 2>&1

    rm -rf "$WORKDIR"
    /etc/init.d/byedpi enable >/dev/null 2>&1
    /etc/init.d/byedpi start >/dev/null 2>&1

    echo -e "ByeDPI ${GREEN}успешно установлен!${NC}\n"
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Удаление ByeDPI
# ==========================================
uninstall_byedpi() {
    echo -e "\n${MAGENTA}Удаление ByeDPI${NC}"
    [ -f /etc/init.d/byedpi ] && {
        /etc/init.d/byedpi stop >/dev/null 2>&1
        /etc/init.d/byedpi disable >/dev/null 2>&1
    }
    opkg remove --force-removal-of-dependent-packages byedpi >/dev/null 2>&1
	uci set dhcp.@dnsmasq[0].localuse='1'; uci commit dhcp; /etc/init.d/dnsmasq restart
    rm -rf /etc/init.d/byedpi /opt/byedpi /etc/config/byedpi
    echo -e "${GREEN}ByeDPI удалён!${NC}\n"
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Установка
# ==========================================
install_podkop() {
    echo -e "\n${MAGENTA}Установка Podkop${NC}"

    REPO="https://api.github.com/repos/itdoginfo/podkop/releases/latest"
    DOWNLOAD_DIR="/tmp/podkop"

    PKG_IS_APK=0
    command -v apk >/dev/null 2>&1 && PKG_IS_APK=1

    rm -rf "$DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"

    msg() {
        if [ -n "$2" ]; then
            printf "\033[32;1m%s \033[37;1m%s\033[0m\n" "$1" "$2"
        else
            printf "\033[32;1m%s\033[0m\n" "$1"
        fi
    }

    pkg_is_installed () {
        local pkg_name="$1"
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk list --installed | grep -q "$pkg_name"
        else
            opkg list-installed | grep -q "$pkg_name"
        fi
    }

    pkg_remove() {
        local pkg_name="$1"
        msg "Удаляем" "$pkg_name..."
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk del "$pkg_name" >/dev/null 2>&1
        else
            opkg remove --force-depends "$pkg_name" >/dev/null 2>&1
        fi
    }

    pkg_list_update() {
        msg "Обновляем список пакетов..."
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk update >/dev/null 2>&1
        else
            opkg update >/dev/null 2>&1
        fi
    }

    pkg_install() {
        local pkg_file="$1"
        msg "Устанавливаем" "$(basename "$pkg_file")"
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk add --allow-untrusted "$pkg_file" >/dev/null 2>&1
        else
            opkg install "$pkg_file" >/dev/null 2>&1
        fi
    }

    # Проверка системы
    MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "не определено")
    AVAILABLE_SPACE=$(df /overlay | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=26000
	
[ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ] && { 
    msg "Недостаточно свободного места"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}

nslookup google.com >/dev/null 2>&1 || { 
    msg "DNS не работает"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}


    if pkg_is_installed https-dns-proxy; then
        msg "Обнаружен конфликтный пакет" "https-dns-proxy. Удаляем..."
        pkg_remove luci-app-https-dns-proxy
        pkg_remove https-dns-proxy
        pkg_remove luci-i18n-https-dns-proxy*
    fi

    # Проверка sing-box
    if pkg_is_installed "^sing-box"; then
        sing_box_version=$(sing-box version | head -n 1 | awk '{print $3}')
        required_version="1.12.4"
        if [ "$(echo -e "$sing_box_version\n$required_version" | sort -V | head -n 1)" != "$required_version" ]; then
            msg "sing-box устарел. Удаляем..."
            service podkop stop >/dev/null 2>&1
            pkg_remove sing-box
        fi
    fi

    /usr/sbin/ntpd -q -p 194.190.168.1 -p 216.239.35.0 -p 216.239.35.4 -p 162.159.200.1 -p 162.159.200.123 >/dev/null 2>&1

pkg_list_update || { 
    msg "Не удалось обновить список пакетов"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}


    # Шаблон скачивания
    if [ "$PKG_IS_APK" -eq 1 ]; then
        grep_url_pattern='https://[^"[:space:]]*\.apk'
    else
        grep_url_pattern='https://[^"[:space:]]*\.ipk'
    fi

    download_success=0
    urls=$(wget -qO- "$REPO" 2>/dev/null | grep -o "$grep_url_pattern")
    for url in $urls; do
        filename=$(basename "$url")
        filepath="$DOWNLOAD_DIR/$filename"
        msg "Скачиваем" "$filename"
        if wget -q -O "$filepath" "$url" >/dev/null 2>&1 && [ -s "$filepath" ]; then
            download_success=1
        else
            msg "Ошибка скачивания" "$filename"
        fi
    done

[ $download_success -eq 0 ] && { 
    msg "Нет успешно скачанных пакетов"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}

    # Установка пакетов
    for pkg in podkop luci-app-podkop; do
        file=$(ls "$DOWNLOAD_DIR" | grep "^$pkg" | head -n 1)
        [ -n "$file" ] && pkg_install "$DOWNLOAD_DIR/$file"
    done

    # Русский интерфейс
    ru=$(ls "$DOWNLOAD_DIR" | grep "luci-i18n-podkop-ru" | head -n 1)
    if [ -n "$ru" ]; then
        if pkg_is_installed luci-i18n-podkop-ru; then
            msg "Обновляем русский язык..." "$ru"
            pkg_remove luci-i18n-podkop* >/dev/null 2>&1
            pkg_install "$DOWNLOAD_DIR/$ru"
        else
			pkg_install "$DOWNLOAD_DIR/$ru"

        fi
    fi

    # Очистка
    rm -rf "$DOWNLOAD_DIR"

    echo -e "Podkop ${GREEN}успешно установлен!${NC}\n"
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Интеграция ByeDPI в Podkop
# ==========================================
integration_byedpi_podkop() {
    echo -e "\n${MAGENTA}Интеграция ByeDPI в Podkop${NC}"

	# Проверяем установлен ли ByeDPI
    if ! command -v byedpi >/dev/null 2>&1 && [ ! -f /etc/init.d/byedpi ]; then
		echo -e "${YELLOW}ByeDPI не установлен.${NC}\n"
        read -p "Нажмите Enter..." dummy
        return
    fi
	echo -e "${GREEN}Отключаем локальный ${NC}DNS${GREEN}...${NC}"
	uci set dhcp.@dnsmasq[0].localuse='0'
    uci commit dhcp
	echo -e "${GREEN}Перезапускаем ${NC}dnsmasq${GREEN}...${NC}"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1

    # Меняем стратегию ByeDPI на интеграционную
	echo -e "${GREEN}Меняем стратегию ${NC}ByeDPI${GREEN} на рабочую...${NC}"
    if [ -f /etc/config/byedpi ]; then
        sed -i "s|option cmd_opts .*| option cmd_opts '-o2 --auto=t,r,a,s -d2'|" /etc/config/byedpi
    fi
echo -e "${GREEN}Меняем конфигурацию в ${NC}Podkop${GREEN}...${NC}"
    # Создаём / меняем /etc/config/podkop
    cat <<EOF >/etc/config/podkop
config settings 'settings'
	option dns_type 'udp'
	option dns_server '8.8.8.8'
	option bootstrap_dns_server '77.88.8.8'
	option dns_rewrite_ttl '60'
	list source_network_interfaces 'br-lan'
	option enable_output_network_interface '0'
	option enable_badwan_interface_monitoring '0'
	option enable_yacd '0'
	option disable_quic '0'
	option update_interval '1d'
	option download_lists_via_proxy '0'
	option dont_touch_dhcp '0'
	option config_path '/etc/sing-box/config.json'
	option cache_path '/tmp/sing-box/cache.db'
	option exclude_ntp '0'
	option shutdown_correctly '0'

config section 'main'
	option connection_type 'proxy'
	option proxy_config_type 'outbound'
	option enable_udp_over_tcp '0'
	option outbound_json '{
  "type": "socks",
  "server": "127.0.0.1",
  "server_port": 1080
}'
	option user_domain_list_type 'disabled'
	option user_subnet_list_type 'disabled'
	option mixed_proxy_enabled '0'
	list community_lists 'youtube'
EOF

    echo -e "${GREEN}Запуск ${NC}ByeDPI${GREEN}...${NC}"
    /etc/init.d/byedpi enable >/dev/null 2>&1
    /etc/init.d/byedpi start >/dev/null 2>&1
	echo -e "${GREEN}Запуск ${NC}Podkop${GREEN}...${NC}"
    podkop enable >/dev/null 2>&1
    echo -e "${GREEN}Применяем конфигурацию...${NC}"
    podkop reload >/dev/null 2>&1
    echo -e "${GREEN}Перезапускаем сервис...${NC}"
    podkop restart >/dev/null 2>&1
    echo -e "${GREEN}Обновляем списки...${NC}"
    podkop list_update >/dev/null 2>&1

    echo -e "Podkop ${GREEN}готов к работе.${NC}"

    echo -e "ByeDPI ${GREEN}интегрирован в ${NC}Podkop${GREEN}.${NC}"
    echo -ne "\nНужно ${RED}обязательно${NC} перезагрузить роутер. Перезагрузить сейчас? [y/N]: \n"
    read REBOOT_CHOICE
    case "$REBOOT_CHOICE" in
	y|Y)

        echo -e "\n${GREEN}Перезагрузка роутера...${NC}"
        sleep 1
        reboot
        ;;
    *)
        echo -e "${YELLOW}Перезагрузка отложена.${NC}\n"
		read -p "Нажмите Enter..." dummy
        ;;
esac
}

# ==========================================
# Изменение стратегии ByeDPI
# ==========================================
fix_strategy() {

    echo -e "\n${MAGENTA}Изменение стратегии ByeDPI${NC}"

    if [ -f /etc/config/byedpi ]; then
        # Получаем текущую стратегию
        CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
        [ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"
        echo -e "\n${GREEN}Текущая стратегия:${NC} ${WHITE}$CURRENT_STRATEGY${NC}"
        echo -ne "\n${YELLOW}Введите новую стратегию (Enter — оставить текущую):${NC} "
		read NEW_STRATEGY
        echo
        if [ -z "$NEW_STRATEGY" ]; then
            echo -e "${GREEN}Стратегия не изменена.${NC}\n"
        else
            sed -i "s|option cmd_opts .*| option cmd_opts '$NEW_STRATEGY'|" /etc/config/byedpi
			/etc/init.d/byedpi enable >/dev/null 2>&1
			/etc/init.d/byedpi start >/dev/null 2>&1
            echo -e "${GREEN}Стратегия изменена на:${NC} ${WHITE}$NEW_STRATEGY${NC}\n"
        fi
    else
        echo -e "\n${YELLOW}ByeDPI не установлен.${NC}\n"
    fi
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Удаление Podkop
# ==========================================
uninstall_podkop() {
    echo -e "\n${MAGENTA}Удаление Podkop${NC}"
    
    # Удаляем пакеты
    opkg remove luci-i18n-podkop-ru luci-app-podkop podkop --autoremove >/dev/null 2>&1 || true

    # Удаляем конфиги и временные папки
    rm -rf /etc/config/podkop /tmp/podkop_installer

    # Удаляем все файлы в /etc/config с именем содержащим podkop
    rm -f /etc/config/*podkop* >/dev/null 2>&1

    echo -e "Podkop ${GREEN}удалён полностью.${NC}\n"
    read -p "Нажмите Enter..." dummy
}



# ==========================================
# uninstall_AWG
# ==========================================
uninstall_AWG() {
echo -e "\n${MAGENTA}Удаление AWG + интерфейс${NC}"
opkg remove --force-removal-of-dependent-packages luci-i18n-amneziawg-ru luci-proto-amneziawg amneziawg-tools kmod-amneziawg >/dev/null 2>&1
echo -e "AWG ${GREEN}удалён.${NC}"
echo -e "${MAGENTA}Удаляем интерфейс AWG${NC}"
uci -q delete network.AWG
uci commit network
/etc/init.d/network reload >/dev/null 2>&1
echo -e "AWG ${GREEN}удалён.${NC}\n"
read -p "Нажмите Enter..." dummy
}

# ==========================================
# Меню
# ==========================================
show_menu() {
get_versions

if [ -f /etc/config/byedpi ]; then
    CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
    [ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"
else
    CURRENT_STRATEGY="не найдена"
fi


	clear
	echo -e "╔═══════════════════════════════╗"
	echo -e "║         ${BLUE}Podkop Manager${NC}        ║"
	echo -e "╚═══════════════════════════════╝"
	echo -e "                ${DGRAY}by StressOzz v2.5${NC}"


	echo -e "${MAGENTA}--- Podkop ---${NC}"
	echo -e "${YELLOW}Установленная версия:${NC} $PODKOP_STATUS"
	echo -e "${MAGENTA}--- ByeDPI ---${NC}"
	echo -e "${YELLOW}Установленная версия:${NC} $BYEDPI_STATUS"
	echo -e "${YELLOW}Текущая стратегия:${NC} ${WHITE}$CURRENT_STRATEGY${NC}"
	echo -e "${MAGENTA}--- AWG ---${NC}"
if command -v amneziawg >/dev/null 2>&1 || opkg list-installed | grep -q "^amneziawg-tools"; then
    echo -e "${YELLOW}AWG: ${GREEN}установлен${NC}"
else
    echo -e "${YELLOW}AWG: ${RED}не установлен${NC}"
fi

if uci -q get network.AWG >/dev/null; then
    echo -e "${YELLOW}Интерфейс AWG: ${GREEN}установлен${NC}"
else
    echo -e "${YELLOW}Интерфейс AWG: ${RED}не установлен${NC}"
fi


 	echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}Podkop"
	echo -e "${CYAN}2) ${GREEN}Удалить ${NC}Podkop"
	echo -e "${CYAN}3) ${GREEN}Установить ${NC}ByeDPI"
    echo -e "${CYAN}4) ${GREEN}Удалить ${NC}ByeDPI"
    echo -e "${CYAN}5) ${GREEN}Интегрировать ${NC}ByeDPI ${GREEN}в ${NC}Podkop"
    echo -e "${CYAN}6) ${GREEN}Изменить текущую стратегию ${NC}ByeDPI"
	echo -e "${CYAN}7) ${GREEN}Установить ${NC}AWG ${GREEN}+${NC} интерфейс"
	echo -e "${CYAN}8) ${GREEN}Удалить ${NC}AWG ${GREEN}+${NC} интерфейс"
	echo -e "${CYAN}9) ${GREEN}Интегрировать ${NC}AWG ${GREEN}в ${NC}Podkop"
	echo -e "${CYAN}0) ${GREEN}Перезагрузить устройство${NC}"
	echo -e "${CYAN}Enter) ${GREEN}Выход${NC}"
    echo -ne "\n${YELLOW}Выберите пункт:${NC} "
    read choice

    case "$choice" in
        1) install_podkop ;;
		2) uninstall_podkop ;;
        3) install_ByeDPI ;;
        4) uninstall_byedpi ;;
		5) integration_byedpi_podkop ;;
        6) fix_strategy ;;
		7) install_AWG ;;
		8) uninstall_AWG ;;
		9) integration_AWG ;;
		0) echo -e "\n${RED}Перезагрузка${NC}\n"; reboot ;;
        *) exit 0 ;;
    esac
}

# ==========================================
# Запуск
# ==========================================
while true; do
    show_menu
done
