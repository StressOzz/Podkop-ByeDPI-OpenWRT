[Русский](readme.md) | English

# Guide — Installing and configuring **Podkop** together with **ByeDPI** on OpenWrt

> [!IMPORTANT]
> If your ISP intercepts DNS requests, you must protect DNS or ByeDPI may not work.
> Podkop is incompatible with the `https-dns-proxy` package. Using a FakeIP scheme can also make it harder to counter DNS interception.

---

## 0. Installing Podkop

See Podkop’s repository [README](https://github.com/itdoginfo/podkop?tab=readme-ov-file) and the official website with documentation: [https://podkop.net/](https://podkop.net/)

---

## 1. Installing ByeDPI

### 1.1 Determine device architecture

```sh
opkg print-architecture
awk -F'"' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release
```

### 1.2 Download the package

Replace `aarch64_cortex-a53` with your architecture:

```sh
(cd /tmp && curl -LO https://github.com/DPITrickster/ByeDPI-OpenWrt/releases/download/v0.17.2-24.10/byedpi_0.17.2-r1_aarch64_cortex-a53.ipk)
```

### 1.3 Install the package

> [!NOTE]
> Remove the old version first if necessary.

```sh
opkg remove byedpi
opkg install /tmp/byedpi_0.17.2-r1_aarch64_cortex-a53.ipk
```

### 1.4 Edit ByeDPI configuration

Open the config (example uses `vi`, which is usually available):

```sh
vi /etc/config/byedpi
```

Add a working strategy (example):

```conf
config byedpi
    option enabled '1'
    option cmd_opts '-o 2 --auto=t,r,a,s -d 2'
```

> [!WARNING]
> Choose a strategy using [ByeByeDPI](https://github.com/romanvht/ByeByeDPI) or [ByeDPI Manager](https://github.com/romanvht/ByeDPIManager) in advance if possible.

### 1.5 Enable and start the service

```sh
/etc/init.d/byedpi enable
/etc/init.d/byedpi start
```

### 1.6 (OpenWrt 24.10) Disable dnsmasq local resolver

If you are on OpenWrt 24.10, disable `dnsmasq` local use:

```sh
uci set dhcp.@dnsmasq[0].localuse='0'
uci commit dhcp
```

---

## 2. Podkop configuration

### 2.1 Add an Outbound for ByeDPI

* Outbound type: `Proxy`
* Configuration type: `Outbound Config`

Example Outbound configuration (JSON):

```json
{
  "type": "socks",
  "server": "127.0.0.1",
  "server_port": 1080
}
```

> [!NOTE]
> Don’t forget to add the required [lists](https://podkop.net/docs/sections/) that ByeDPI should interact with.

---

## 3. Final steps

### 3.1 Reboot the router

```sh
reboot
```

### 3.2 Verify ByeDPI is running

Recommended checks:

```sh
pgrep -a byedpi || ps aux | grep [b]yedpi
ss -tulnp | grep 1080 || netstat -tulnp | grep 1080
```

If you see the process and a SOCKS5 listener on the configured port (1080 in examples), ByeDPI is up.

---

## Acknowledgements

Thanks to:

* **[itdoginfo](https://github.com/itdoginfo)** — Podkop
* **[hufrea](https://github.com/hufrea)** — ByeDPI
* **[spvkgn](https://github.com/spvkgn)** — GitHub Actions
* **[romanvht](https://github.com/romanvht)** — strategy testing
* **[StressOzz](https://github.com/StressOzz)** — setup instructions (Podkop + ByeDPI)
