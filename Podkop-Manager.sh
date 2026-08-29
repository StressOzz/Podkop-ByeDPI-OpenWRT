#!/bin/sh
# ==========================================
# ByeDPI & Podkop Manager by StressOzz
# ==========================================

GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
NC="\033[0m"
BLUE="\033[0;34m"
DGRAY="\033[38;5;244m"

if command -v opkg >/dev/null 2>&1; then PKG="opkg"; GO_SUF="1"; CONFZ="/etc/opkg/distfeeds.conf"; PKG_IS_APK=0; UPDATE="opkg update"; INSTALL="opkg install"
DELETE="opkg remove"; ARCH="$(opkg print-architecture | awk '{print $2}' | tail -n1)"; VER_SUF="r1-all"; SUF_MT=""; SPL_SUF="all"; RELEASE_TAG="v${BYEDPI_LATEST_VER}-24.10"
RAZ="ipk"; TMP_FILE_GO="/tmp/tg-ws-proxy.ipk"; else PKG="apk"; GO_SUF="r1"; CONFZ="/etc/apk/repositories.d/distfeeds.list"; PKG_IS_APK=1; SPL_SUF="noarch"; RELEASE_TAG="v${BYEDPI_LATEST_VER}-25.12"
UPDATE="apk update"; INSTALL="apk add --allow-untrusted"; DELETE="apk del"; ARCH="$(apk --print-arch 2>/dev/null)"; RAZ="apk"; VER_SUF="r1"; SUF_MT="r"; TMP_FILE_GO="/tmp/tg-ws-proxy.apk"; fi


tmpDIR="/tmp/PodkopManager"
rm -rf "$tmpDIR"
mkdir -p "$tmpDIR"


GH_RAW_HOST="https://raw.githubusercontent.com"; GH_MAIN_HOST="https://github.com"; GH_PROXY="https://gh-proxy.org/"; GH_CHECK_URL="${GH_RAW_HOST}/StressOzz/Zapret-Manager/refs/heads/main/Zapret-Manager.sh"
echo -e "${CYAN}Проверяем доступность ${NC}raw.githubusercontent.com"; if wget -q -T 4 -O /dev/null "$GH_CHECK_URL" 2>/dev/null; then GH_OK=1; GH_RAW="$GH_RAW_HOST"
GH_MAIN="$GH_MAIN_HOST"; echo -e "raw.githubusercontent.com ${GREEN}доступен!${NC}\n"; else GH_OK=0; GH_RAW="${GH_PROXY}${GH_RAW_HOST}"; GH_MAIN="${GH_PROXY}${GH_MAIN_HOST}"
echo -e "raw.githubusercontent.com ${RED}недоступен${CYAN} — ${YELLOW}используем прокси!${NC}\n"; fi


MIRROR=""
CURRENT_MIRROR=$(head -n1 "$CONFZ" | awk '{print $NF}' | sed 's|https://||;s|/releases/.*||')

if grep -qE 'mirror-03\.infra\.openwrt\.org|ftp\.snt\.utwente\.nl/pub/software/openwrt|mirror\.berlin\.freifunk\.net/downloads\.openwrt|mirror\.sjtu\.edu\.cn/openwrt|downloads\.openwrt\.org' "$CONFZ"; then

    echo -e "${CYAN}Проверяем доступность ${NC}$CURRENT_MIRROR"

    if ! wget -q --spider --timeout=2 "https://$CURRENT_MIRROR/releases/" >/dev/null 2>&1; then
        echo -e "$CURRENT_MIRROR ${RED}недоступен!${NC}"

        if wget -q --spider --timeout=3 "https://mirror-03.infra.openwrt.org/releases/" >/dev/null 2>&1; then
            MIRROR="mirror-03.infra.openwrt.org"
        elif wget -q --spider --timeout=3 "https://ftp.snt.utwente.nl/pub/software/openwrt/releases/" >/dev/null 2>&1; then
            MIRROR="ftp.snt.utwente.nl/pub/software/openwrt"
        elif wget -q --spider --timeout=3 "https://mirror.berlin.freifunk.net/downloads.openwrt/releases/" >/dev/null 2>&1; then
            MIRROR="mirror.berlin.freifunk.net/downloads.openwrt"
        elif wget -q --spider --timeout=3 "https://mirror.sjtu.edu.cn/openwrt/releases/" >/dev/null 2>&1; then
            MIRROR="mirror.sjtu.edu.cn/openwrt"
        elif wget -q --spider --timeout=3 "https://downloads.openwrt.org/releases/" >/dev/null 2>&1; then
            MIRROR="downloads.openwrt.org"
        fi

        if [ -n "$MIRROR" ]; then
            echo -e "${CYAN}Переключаемся на ${NC}$MIRROR"
            sed -i "s|https://.*/releases/|https://$MIRROR/releases/|g" "$CONFZ"
        else
            echo -e "${RED}Резервные зеркала недоступны!${NC}"
        fi
    else
        echo -e "$CURRENT_MIRROR ${GREEN}доступен!${NC}"
    fi
fi

if ! curl --version >/dev/null 2>&1; then echo -e "\ncurl ${RED}отсутствует ${NC}или${RED} работает некорректно${NC}\n"; echo -e "${MAGENTA}Устанавливаем ${NC}curl"
$DELETE curl libcurl >/dev/null 2>&1; echo -e "${CYAN}Обновляем список пакетов${NC}"; if ! $UPDATE >/dev/null 2>&1; then echo -e "\n${RED}Ошибка обновления списка пакетов!${NC}\n"; else PACKAGES_UPDATED=1; fi
echo -e "${CYAN}Устанавливаем ${NC}curl"; if ! $INSTALL libcurl curl >/dev/null 2>&1; then echo -e "\n${RED}Не удалось установить curl!${NC}\n"; PAUSE; fi; fi

PODKOP_LATEST_VER="$(curl -Ls -o /dev/null -w '%{url_effective}' ${GH_MAIN}/itdoginfo/podkop/releases/latest | sed -E 's#.*/tag/v?##')"

BYEDPI_VER="0.17.3"

BYEDPI_LATEST_VER="$BYEDPI_VER"

BASE_URL="${GH_MAIN}/Slava-Shchipunov/awg-openwrt/releases/download/"

IF_NAME="AWG"
PROTO="amneziawg"
DEV_NAME="amneziawg0"

if command -v apk >/dev/null 2>&1; then
PKG_IS_APK=1
PKG_MANAGER="apk list -I 2>/dev/null"
else
PKG_IS_APK=0
PKG_MANAGER="opkg list-installed 2>/dev/null"
fi

PAUSE() { echo -ne "\nНажмите Enter..."; read dummy; }

pkg_remove() { local pkg_name="$1"; if [ "$PKG_IS_APK" -eq 1 ]; then apk del "$pkg_name" >/dev/null 2>&1 || true; else opkg remove --force-depends "$pkg_name" >/dev/null 2>&1 || true; fi; }

echo 'sh <(wget -O - ${GH_RAW}/StressOzz/Podkop-Manager/main/Podkop-Manager.sh)' > /usr/bin/pkm; chmod +x /usr/bin/pkm

# ==========================================
# AWG
# ==========================================
install_AWG() {

echo -e "\n${MAGENTA}Устанавливаем AWG и интерфейс AWG${NC}"

VERSION=$(ubus call system board | jsonfilter -e '@.release.version' | tr -d '\n')
MAJOR_VERSION=$(echo "$VERSION" | cut -d '.' -f1)

if [ -z "$VERSION" ]; then
echo -e "\n${RED}Не удалось определить версию OpenWrt!${NC}"
PAUSE
return
fi

TARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f1)
SUBTARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f2)

install_pkg() {
local pkgname=$1
local filename="${pkgname}${PKGPOSTFIX}"
local url="${BASE_URL}v${VERSION}/${filename}"

echo -e "${CYAN}Скачиваем:${NC} $filename"

if wget -O "$tmpDIR/$filename" "$url" >/dev/null 2>&1; then
echo -e "${CYAN}Устанавливаем:${NC} $pkgname"
if ! $INSTALL_CMD "$tmpDIR/$filename" >/dev/null 2>&1; then
echo -e "\n${RED}Ошибка установки $pkgname!${NC}"
PAUSE
return 1
fi
else
echo -e "\n${RED}Ошибка! Не удалось скачать $filename${NC}"
PAUSE
return 1
fi
}

if [ "$MAJOR_VERSION" -ge 25 ] 2>/dev/null; then
PKGARCH=$(cat /etc/apk/arch)
PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.apk"
INSTALL_CMD="apk add --allow-untrusted"
else
echo -e "${CYAN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1 || {
echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}"
PAUSE
return
}
PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max=$3; arch=$2}} END {print arch}')
PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.ipk"
INSTALL_CMD="opkg install"
fi

install_pkg "kmod-amneziawg"
install_pkg "amneziawg-tools"
install_pkg "luci-proto-amneziawg"
install_pkg "luci-i18n-amneziawg-ru"

echo -e "${CYAN}Создаем интерфейс AWG${NC}"

if uci show network.$IF_NAME >/dev/null 2>&1; then
echo -e "${RED}Интерфейс уже существует!${NC}"
else
uci set network.$IF_NAME=interface
uci set network.$IF_NAME.proto=$PROTO
uci set network.$IF_NAME.device=$DEV_NAME
uci commit network
fi

echo -e "${YELLOW}Перезапускаем сеть! Подождите...${NC}"
/etc/init.d/network restart >/dev/null 2>&1

echo -e "AWG ${GREEN}и${NC} интерфейс AWG ${GREEN}установлены!${NC}\n"
echo -e "${YELLOW}Необходимо в LuCI в интерфейс AWG загрузить конфиг:${NC}\nNetwork ${GREEN}→${NC} Interfaces ${GREEN}→${NC} AWG ${GREEN}→${NC} Edit ${GREEN}→${NC} Load configuration…${NC}"
PAUSE
}

# ==========================================
# Интеграция AWG
# ==========================================
integration_AWG() {

echo -e "\n${MAGENTA}Интегрируем AWG в Podkop${NC}"

if ! awg --version >/dev/null 2>&1; then
echo -e "\n${RED}AWG не установлен!${NC}"
PAUSE
return
fi

echo -e "${CYAN}Меняем конфигурацию в ${NC}Podkop${NC}"
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

echo -e "${CYAN}Запускаем ${NC}Podkop${NC}"
podkop enable >/dev/null 2>&1
echo -e "${CYAN}Применяем конфигурацию${NC}"
podkop reload >/dev/null 2>&1
podkop restart >/dev/null 2>&1
echo -e "${CYAN}Обновляем списки${NC}"
podkop list_update >/dev/null 2>&1
echo -e "${CYAN}Перезапускаем сервис${NC}"
podkop restart >/dev/null 2>&1
echo -e "AWG ${GREEN}интегрирован в ${NC}Podkop${GREEN}!${NC}\n"
echo -e "${YELLOW}Необходимо в LuCI в интерфейс AWG загрузить конфиг:${NC}\nNetwork ${GREEN}→${NC} Interfaces ${GREEN}→${NC} AWG ${GREEN}→${NC} Edit ${GREEN}→${NC} Load configuration…${NC}"
PAUSE
}

# ==========================================
# Определение версий
# ==========================================
get_versions() {

if command -v apk >/dev/null 2>&1; then
BYEDPI_VER_OWRT=$(apk list -I 2>/dev/null | grep '^byedpi-' | awk -F'-' '{print $2}' | sed 's/-r[0-9]\+$//' | head -1)
else
BYEDPI_VER_OWRT=$(opkg list-installed 2>/dev/null | grep '^byedpi ' | awk '{print $3}' | sed 's/-r[0-9]\+$//')
fi
[ -z "$BYEDPI_VER_OWRT" ] && BYEDPI_VER_OWRT="не найдена"

if [ -f /etc/config/byedpi ]; then
CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
[ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="${RED}не задана${NC}"
else
CURRENT_STRATEGY="${RED}не найдена${NC}"
fi

LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)

if command -v podkop >/dev/null 2>&1; then
PODKOP_VER=$(podkop show_version 2>/dev/null | sed 's/-r[0-9]\+$//')
[ -z "$PODKOP_VER" ] && PODKOP_VER="не найдена"
else
PODKOP_VER="не установлен"
fi

[ -z "$PODKOP_LATEST_VER" ] && PODKOP_LATEST_VER="не найдена"

PODKOP_VER=$(echo "$PODKOP_VER" | sed 's/^v//')
PODKOP_LATEST_VER=$(echo "$PODKOP_LATEST_VER" | sed 's/^v//')
BYEDPI_VER_OWRT=$(echo "$BYEDPI_VER_OWRT" | sed 's/^v//')
BYEDPI_LATEST_VER=$(echo "$BYEDPI_LATEST_VER" | sed 's/^v//')

if [ "$BYEDPI_VER_OWRT" = "не найдена" ] || [ "$BYEDPI_VER_OWRT" = "не установлен" ]; then
BYEDPI_STATUS="${RED}$BYEDPI_VER_OWRT${NC}"
elif [ "$BYEDPI_VER_OWRT" != "$BYEDPI_LATEST_VER" ]; then
BYEDPI_STATUS="${RED}$BYEDPI_VER_OWRT${NC}"
else
BYEDPI_STATUS="${GREEN}$BYEDPI_VER_OWRT${NC}"
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

if command -v apk >/dev/null 2>&1; then
OPENWRT_VER="25"
PKG_EXT="apk"
RELEASE_TAG="v${BYEDPI_VER}-25.12"
INSTALL_CMD="apk add --allow-untrusted"
else
OPENWRT_VER="24"
PKG_EXT="ipk"
RELEASE_TAG="v${BYEDPI_VER}-24.10"
INSTALL_CMD="opkg install --force-reinstall"
fi

BYEDPI_FILE="byedpi_${BYEDPI_VER}-r1_${LOCAL_ARCH}.${PKG_EXT}"
BYEDPI_URL="${GH_MAIN}/DPITrickster/ByeDPI-OpenWrt/releases/download/${RELEASE_TAG}/${BYEDPI_FILE}"

echo -e "${CYAN}Скачиваем ${NC}$BYEDPI_FILE${NC}"

cd "$tmpDIR" || return

wget -q -U "Mozilla/5.0" -O "$BYEDPI_FILE" "$BYEDPI_URL" || {
echo -e "\n${RED}Ошибка загрузки ${NC}$BYEDPI_FILE"
PAUSE
return
}

echo -e "${CYAN}Устанавливаем${NC} $BYEDPI_FILE${NC}"
$INSTALL_CMD "$BYEDPI_FILE" >/dev/null 2>&1

[ $? -eq 0 ] || echo -e "\n${RED}Ошибка установки!${NC}"

if [ -f /etc/init.d/byedpi ]; then
/etc/init.d/byedpi enable >/dev/null 2>&1
/etc/init.d/byedpi start >/dev/null 2>&1
echo -e "ByeDPI ${GREEN}установлен!${NC}"
else
echo -e "\n${RED}Сервис byedpi не найден!${NC}"
fi

PAUSE
}

# ==========================================
# Удаление ByeDPI
# ==========================================
uninstall_byedpi() {
echo -e "\n${MAGENTA}Удаление ByeDPI${NC}"
/etc/init.d/byedpi stop >/dev/null 2>&1
/etc/init.d/byedpi disable >/dev/null 2>&1

pkg_remove byedpi

uci delete dhcp.@dnsmasq[0].localuse >/dev/null 2>&1; uci commit dhcp >/dev/null 2>&1; /etc/init.d/dnsmasq restart >/dev/null 2>&1
rm -rf /etc/init.d/byedpi /opt/byedpi /etc/config/byedpi
echo -e "ByeDPI ${GREEN}удалён!${NC}"
PAUSE
}

# ==========================================
# Установка
# ==========================================

install_podkop() {
echo -e "\n${MAGENTA}Установка Podkop${NC}"

if [ "$GH_OK" -eq 1 ]; then
    REPO="https://api.github.com/repos/itdoginfo/podkop/releases/latest"
else
    REPO="${GH_PROXY}https://api.github.com/repos/itdoginfo/podkop/releases/latest"
fi

PKG_IS_APK=0
command -v apk >/dev/null 2>&1 && PKG_IS_APK=1

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
echo -e "${CYAN}Удаляем ${NC}$pkg_name"
if [ "$PKG_IS_APK" -eq 1 ]; then
apk del "$pkg_name" >/dev/null 2>&1
else
opkg remove --force-depends "$pkg_name" >/dev/null 2>&1
fi
}

pkg_list_update() {
echo -e "${CYAN}Обновляем список пакетов${NC}"
if [ "$PKG_IS_APK" -eq 1 ]; then
apk update >/dev/null 2>&1
else
opkg update >/dev/null 2>&1
fi
}

pkg_install() {
local pkg_file="$1"
echo -e "${CYAN}Устанавливаем ${NC}$(basename "$pkg_file")"
if [ "$PKG_IS_APK" -eq 1 ]; then
apk add --allow-untrusted "$pkg_file" >/dev/null 2>&1
else
opkg install "$pkg_file" >/dev/null 2>&1
fi
}

MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "не определено")
AVAILABLE_SPACE=$(df /overlay | awk 'NR==2 {print $4}')
REQUIRED_SPACE=26000

[ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ] && {
echo -e "\n${RED}Недостаточно свободного места!${NC}"
PAUSE
return
}

nslookup google.com >/dev/null 2>&1 || {
echo -e "\n${RED}DNS не работает!${NC}"
PAUSE
return
}


if pkg_is_installed https-dns-proxy; then
echo -e "${RED}Обнаружен конфликтный пакет ${NC}https-dns-proxy${RED}. Удаляем...${NC}"
pkg_remove luci-app-https-dns-proxy
pkg_remove https-dns-proxy
pkg_remove luci-i18n-https-dns-proxy*
fi

if pkg_is_installed "^sing-box"; then
sing_box_version=$(sing-box version | head -n 1 | awk '{print $3}')
required_version="1.12.4"
if [ "$(echo -e "$sing_box_version\n$required_version" | sort -V | head -n 1)" != "$required_version" ]; then
echo -e "sing-box ${RED}устарел. Удаляем...${NC}"
service podkop stop >/dev/null 2>&1
pkg_remove sing-box
fi
fi

/usr/sbin/ntpd -q -p 194.190.168.1 -p 216.239.35.0 -p 216.239.35.4 -p 162.159.200.1 -p 162.159.200.123 >/dev/null 2>&1

pkg_list_update || {
echo -e "\n${RED}Не удалось обновить список пакетов!${NC}"
PAUSE
return
}

if [ "$PKG_IS_APK" -eq 1 ]; then
grep_url_pattern='https://[^"[:space:]]*\.apk'
else
grep_url_pattern='https://[^"[:space:]]*\.ipk'
fi

download_success=0
urls=$(wget -qO- "$REPO" 2>/dev/null | grep -o "$grep_url_pattern")
for url in $urls; do
filename=$(basename "$url")
filepath="$tmpDIR/$filename"
dl_url=$(echo "$url" | sed "s|https://github.com|${GH_MAIN}|")
echo -e "${CYAN}Скачиваем ${NC}$filename"
if wget -q -O "$filepath" "$dl_url" >/dev/null 2>&1 && [ -s "$filepath" ]; then
download_success=1
else
echo -e "\n${RED}Ошибка скачивания ${NC}$filename"
fi
done

[ $download_success -eq 0 ] && {
echo -e "\n${RED}Нет успешно скачанных пакетов${NC}"
PAUSE
return
}

for pkg in podkop luci-app-podkop; do
file=$(ls "$tmpDIR" | grep "^$pkg" | head -n 1)
[ -n "$file" ] && pkg_install "$tmpDIR/$file"
done

ru=$(ls "$tmpDIR" | grep "luci-i18n-podkop-ru" | head -n 1)
if [ -n "$ru" ]; then
if pkg_is_installed luci-i18n-podkop-ru; then
echo -e "${CYAN}Обновляем русский язык ${NC}$ru"
pkg_remove luci-i18n-podkop* >/dev/null 2>&1
pkg_install "$tmpDIR/$ru"
else
pkg_install "$tmpDIR/$ru"

fi
fi

echo -e "Podkop ${GREEN}установлен!${NC}"
PAUSE
}
# ==========================================
# Интеграция ByeDPI в Podkop
# ==========================================
integration_byedpi_podkop() {
echo -e "\n${MAGENTA}Интеграция ByeDPI в Podkop${NC}"

if ! command -v byedpi >/dev/null 2>&1 && [ ! -f /etc/init.d/byedpi ]; then
echo -e "\n${RED}ByeDPI не установлен!${NC}"
PAUSE
return
fi

echo -e "${CYAN}Отключаем локальный ${NC}DNS"
uci set dhcp.@dnsmasq[0].localuse='0'
uci commit dhcp
echo -e "${CYAN}Перезапускаем ${NC}dnsmasq"
/etc/init.d/dnsmasq restart >/dev/null 2>&1

echo -e "${CYAN}Меняем стратегию ${NC}ByeDPI${CYAN} на рабочую${NC}"
if [ -f /etc/config/byedpi ]; then
sed -i "s|option cmd_opts .*| option cmd_opts '-o1 -r-5+se -a1 -At,r,s -d1 -n google.com -Qr -f-1 -a1'|" /etc/config/byedpi
fi
echo -e "${CYAN}Меняем конфигурацию в ${NC}Podkop"
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

echo -e "${CYAN}Запускаем ${NC}ByeDPI"
/etc/init.d/byedpi enable >/dev/null 2>&1
/etc/init.d/byedpi start >/dev/null 2>&1
echo -e "${CYAN}Запускаем ${NC}Podkop"
podkop enable >/dev/null 2>&1
echo -e "${CYAN}Применяем конфигурацию${NC}"
podkop reload >/dev/null 2>&1
echo -e "${CYAN}Перезапускаем сервис${NC}"
podkop restart >/dev/null 2>&1
echo -e "${CYAN}Обновляем списки${NC}"
podkop list_update >/dev/null 2>&1
echo -e "ByeDPI ${GREEN}интегрирован в ${NC}Podkop${GREEN}!${NC}"
echo -ne "\nНужно ${RED}обязательно${NC} перезагрузить роутер!\nПерезагрузить сейчас? [y/N]: "
read REBOOT_CHOICE
case "$REBOOT_CHOICE" in
y|Y)

echo -e "\n${GREEN}Перезагрузка роутера!${NC}"
reboot
exit 0
;;
*)
echo -e "${YELLOW}Перезагрузка отложена!${NC}"
PAUSE
;;
esac
}

# ==========================================
# Изменение стратегии ByeDPI
# ==========================================
fix_strategy() {

echo -e "\n${MAGENTA}Изменение стратегии ByeDPI${NC}"

if [ -f /etc/config/byedpi ]; then
CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
[ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"
echo -e "\n${GREEN}Текущая стратегия:${NC} $CURRENT_STRATEGY${NC}"
echo -ne "\n${YELLOW}Введите новую стратегию (Enter — оставить текущую):${NC} "
read NEW_STRATEGY
echo
if [ -z "$NEW_STRATEGY" ]; then
echo -e "${GREEN}Стратегия не изменена!${NC}"
else
sed -i "s|option cmd_opts .*| option cmd_opts '$NEW_STRATEGY'|" /etc/config/byedpi
/etc/init.d/byedpi enable >/dev/null 2>&1
/etc/init.d/byedpi start >/dev/null 2>&1
echo -e "${GREEN}Стратегия изменена на:${NC} $NEW_STRATEGY${NC}"
fi
else
echo -e "\n${RED}ByeDPI не установлен!${NC}"
fi
PAUSE
}

# ==========================================
# Удаление Podkop
# ==========================================
uninstall_podkop() {
echo -e "\n${MAGENTA}Удаление Podkop${NC}"

pkg_remove luci-i18n-podkop-ru
pkg_remove luci-app-podkop podkop
pkg_remove podkop

rm -rf /etc/config/podkop /tmp/podkop_installer
rm -f /etc/config/*podkop* >/dev/null 2>&1

echo -e "Podkop ${GREEN}удалён!${NC}"
PAUSE
}

# ==========================================
# uninstall_AWG
# ==========================================
uninstall_AWG() {
echo -e "\n${MAGENTA}Удаление AWG и интерфейс AWG${NC}"
echo -e "${CYAN}Удаляем ${NC}AWG"
pkg_remove luci-i18n-amneziawg-ru
pkg_remove luci-proto-amneziawg
pkg_remove amneziawg-tools
pkg_remove kmod-amneziawg

uci delete network.AWG >/dev/null 2>&1
uci commit network >/dev/null 2>&1

for peer in $(uci show network | grep "interface='AWG'" | cut -d. -f2); do
    uci delete network.$peer
done
uci commit network >/dev/null 2>&1
echo -e "${CYAN}Удаляем ${NC}интерфейс AWG"
echo -e "${YELLOW}Перезапускаем сеть! Подождите...${NC}"
/etc/init.d/network restart

echo -e "AWG ${GREEN}и${NC} интерфейс AWG ${GREEN}удалены!${NC}"
PAUSE
}

# ==========================================
# Зеркало
# ==========================================
set_mirror() { NEW_BASE="$1"; echo -e "\n${CYAN}Проверяем доступность ${NC}$NEW_BASE"
if ! wget -q --spider --timeout=5 "https://$NEW_BASE/releases/" >/dev/null 2>&1; then echo -e "${RED}Зеркало недоступно!${NC}\n"; PAUSE; return 1; fi
sed -i "s|https://.*/releases/|https://$NEW_BASE/releases/|g" "$CONFZ"; echo -e "${GREEN}Зеркало доступно!${NC}\n${CYAN}Обновляем список пакетов${NC}"
if ! $UPDATE >/dev/null 2>&1; then echo -e "\n${RED}Ошибка обновления списка пакетов!${NC}\n${GREEN}Зеркало сброшено на ${NC}default ${GREEN}/${NC} OpenWrt${GREEN}!${NC}\n"
sed -i "s|https://.*/releases/|https://downloads.openwrt.org/releases/|g" "$CONFZ"; PAUSE; return 1; fi; echo -e "${GREEN}Пакеты обновлены! Зеркало работает!${NC}\n"; PAUSE; }


curr_MIR() { if [ -f "$CONFZ" ]; then URL=$(head -n1 "$CONFZ"); case "$URL" in
*mirror-03.infra.openwrt.org*) echo "infra.openwrt.org" ;;
*tiguinet.net*) echo "Belgium" ;;
*utwente.nl*) echo "Netherlands" ;;
*freifunk.net*) echo "Germany" ;;
*ps.kz*) echo "Kazakhstan" ;;
*sjtu.edu.cn*) echo "China" ;;
*downloads.openwrt.org*) echo "default / OpenWrt" ;;
*) echo "неизвестное" ;;
esac; else echo "файл не найден"; fi; }

menu_MIR() { while true; do clear; CURR=$(curr_MIR); echo -e "${MAGENTA}Меню выбора зеркала OpenWrt${NC}\n\n${YELLOW}Используется зеркало: ${GREEN}$CURR${NC}\n\n${CYAN}1)${NC} infra.openwrt.org\n${CYAN}2)${NC} China"
echo -e "${CYAN}3)${NC} Germany\n${CYAN}4)${NC} Belgium\n${CYAN}5)${NC} Kazakhstan\n${CYAN}6)${NC} Netherlands\n${CYAN}7)${NC} default / OpenWrt${NC}"
echo -en "\n${YELLOW}Выберите зеркало: ${NC}"; read -r z; case "$z" in
1) set_mirror "mirror-03.infra.openwrt.org" ;;
2) set_mirror "mirror.sjtu.edu.cn/openwrt" ;;
3) set_mirror "mirror.berlin.freifunk.net/downloads.openwrt.org" ;;
4) set_mirror "mirror.tiguinet.net/openwrt" ;;
5) set_mirror "mirror.ps.kz/openwrt" ;;
6) set_mirror "ftp.snt.utwente.nl/pub/software/openwrt" ;;
7) set_mirror "downloads.openwrt.org" ;;
*) break ;;
esac; done; }

# ==========================================
# Меню
# ==========================================
show_menu() {
get_versions; CURR=$(curr_MIR)

clear
echo -e "╔═══════════════════════════════╗"
echo -e "║         ${BLUE}Podkop Manager${NC}        ║"
echo -e "╚═══════════════════════════════╝"
echo -e "                ${DGRAY}by StressOzz v3.0${NC}"

echo -e "${MAGENTA}--- Podkop ---${NC}"
echo -e "${YELLOW}Установленная версия:${NC} $PODKOP_STATUS"
echo -e "${MAGENTA}--- ByeDPI ---${NC}"
echo -e "${YELLOW}Установленная версия:${NC} $BYEDPI_STATUS"
echo -e "${YELLOW}Текущая стратегия:${NC} $CURRENT_STRATEGY${NC}"
echo -e "${MAGENTA}--- AWG ---${NC}"

if command -v amneziawg >/dev/null 2>&1 || eval "$PKG_MANAGER" | grep -q "amneziawg-tools"; then
echo -e "${YELLOW}AWG: ${GREEN}установлен${NC}"
else
echo -e "${YELLOW}AWG: ${RED}не установлен${NC}"
fi
if uci -q get network.AWG >/dev/null; then
    echo -e "${YELLOW}Интерфейс AWG: ${GREEN}установлен${NC}"
else
    echo -e "${YELLOW}Интерфейс AWG: ${RED}не установлен${NC}"
fi
echo -e "${MAGENTA}--- зеркало OpenWRT ---${NC}"
echo -e "${YELLOW}Зеркало: ${GREEN}$CURR${NC}"

echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}Podkop"
echo -e "${CYAN}2) ${GREEN}Удалить ${NC}Podkop"
echo -e "${CYAN}3) ${GREEN}Установить ${NC}ByeDPI"
echo -e "${CYAN}4) ${GREEN}Удалить ${NC}ByeDPI"
echo -e "${CYAN}5) ${GREEN}Интегрировать ${NC}ByeDPI ${GREEN}в ${NC}Podkop"
echo -e "${CYAN}6) ${GREEN}Изменить стратегию ${NC}ByeDPI"
echo -e "${CYAN}7) ${GREEN}Установить ${NC}AWG ${GREEN}и${NC} интерфейс AWG"
echo -e "${CYAN}8) ${GREEN}Удалить ${NC}AWG ${GREEN}и${NC} интерфейс AWG"
echo -e "${CYAN}9) ${GREEN}Интегрировать ${NC}AWG ${GREEN}в ${NC}Podkop"
echo -e "${CYAN}0) ${GREEN}Меню выбора зеркала ${NC}OpenWrt"
echo -e "${CYAN}r) ${GREEN}Перезагрузить устройство${NC}"
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
0) menu_MIR ;;
r|R|к|К) echo -e "\n${GREEN}Перезагрузка!${NC}\n"; reboot; exit 0 ;;
*) exit 0 ;;
esac
}

# ==========================================
# Запуск
# ==========================================
while true; do
show_menu
done
