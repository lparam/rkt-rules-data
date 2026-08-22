# rkt-rules-data

`rkt-rules-data` 是 `rkt` 项目的官方规则集资产仓库，通过 GitHub Actions 实现 24 小时无人值守的自动化数据同步、清洗与编译，为 `rkt` 与 `rkt-desktop` 提供高性能、低内存、全自动构建的原生二进制规则集资产（`.rrs`）与经典兼容数据库。

---

## 🌟 核心特性

- **原生二进制 `.rrs` 极速加载**：基于压缩前缀树（Succinct Trie）与紧凑网段编码，微秒级匹配，内存占用对比传统文本降低 90%+。
- **复合数据库 `geoip.rdb` / `geoip-lite.rdb` 原生支持**：单个数据库同时包含全球 ISO 国家 IP、ASN 自治域与 Telegram/Cloudflare/Google/Private 等专有网段。
- **每日自动构建**：每日北京时间凌晨 04:00 自动同步上游权威数据源（`Loyalsoldier`、`MetaCubeX`、`xishang0128`、`P3TERX` 等）并编译最新规则。
- **全球 CDN 按需加速**：平铺数万个微型 `.rrs` 文件（通常 0.1~30 KB），客户端冷启动秒级拉取。
- **双梯队产物矩阵**：同时提供面向 PC/服务器的 **Full 全量产物**，以及专为 OpenWrt 软路由/嵌入式设备设计的 **Lite 精简产物**。

---

## 📦 分支组织与产物索引

### 1. `rrs` 分支（CDN 单文件按需加速层）
存放所有按语义分类平铺的 `.rrs` 规则集文件，支持 jsDelivr / Fastly 全球 CDN 直连：

```text
├── geosite/
│   ├── geosite-cn.rrs                     # 国内常用域名白名单 (443 KB)
│   ├── geosite-openai.rrs                 # OpenAI / ChatGPT 专用域名 (0.46 KB)
│   ├── geosite-google.rrs                 # Google 全系域名
│   ├── geosite-youtube.rrs                # YouTube 全系域名
│   ├── geosite-category-ads-all.rrs       # 全网去广告规则集 (1.6 MB)
│   └── ... (约 1,500+ 精细域名分类)
├── geoip/
│   ├── geoip-cn.rrs                       # 中国大陆 IP 网段 (33 KB)
│   ├── geoip-telegram.rrs                 # Telegram 官方全部 DC 网段 (0.15 KB)
│   ├── geoip-cloudflare.rrs               # Cloudflare 全网 IP 网段
│   ├── geoip-private.rrs                  # 局域网保留 IP
│   └── ... (约 260 个国家与区域 IP)
└── asn/
    ├── AS13335.rrs                        # Cloudflare 自治域 (9.5 KB)
    ├── AS15169.rrs                        # Google 自治域 (25 KB)
    └── ... (Top 热门自治域)
```

#### 🌐 常用 CDN 直连速查表 (jsDelivr / Fastly)
> 💡 请将 `<owner>` 替换为您的 GitHub 仓库所有者用户名。

```text
# 常用域名规则 (Geosite)
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-cn.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-openai.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-google.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-category-ads-all.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-geolocation-!cn.rrs

# 常用 IP 网段规则 (GeoIP)
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-cn.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-telegram.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-cloudflare.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-private.rrs
```

---

### 2. `release` 分支（离线大包与复合数据库）

| 产物名称 | 说明 | 适用场景 | 预估体积 |
| :--- | :--- | :--- | :--- |
| **`geoip.rdb`** / `geoip.metadb` | **复合三合一全量数据库**（国家 + 8.4 万 ASN + 专有标签） | 离线单文件全量首选 (PC/服务器) | ~8.4 MB |
| **`geoip-lite.rdb`** / `geoip-lite.metadb` | **复合三合一精简数据库**（核心国家 + 常用专有标签 + 主流 ASN 映射） | 软路由 / 低内存嵌入式设备首选 | **~386 KB** |
| **`BundleRRS.7z`** | 全量 1,800+ 个 `.rrs` 规则集归档总包 | PC / 桌面端离线部署 | ~9.2 MB |
| **`BundleRRS-lite.7z`** | 常用核心 `.rrs` 归档精简包 | 软路由离线极速安装 | ~2.6 MB |
| `country.mmdb` | MaxMind 全量国家库 | 传统 MMDB 兼容场景 | ~7.6 MB |
| `country-lite.mmdb` | MaxMind 精简国家库 | 软路由兼容场景 | ~385 KB |
| `GeoLite2-ASN.mmdb` | MaxMind 全量 ASN 自治域库 | 传统 ASN 兼容场景 | ~12 MB |
| `geosite.dat` / `geoip.dat` | V2Ray 全量兼容库 | 兼容传统客户端 | ~11 MB / ~17 MB |
| `geoip-lite.dat` | V2Ray 精简国家库 | 兼容传统轻量客户端 | ~203 KB |
| `sha256sums.txt` | 全量发布资产哈希校验和 | 完整性校验 | ~1.2 KB |

---

### 💡 `geoip.rdb` (Full) vs `geoip-lite.rdb` (Lite) 深度对比

| 特性 / 维度 | 全量复合库 `geoip.rdb` (~8.4 MB) | 精简复合库 `geoip-lite.rdb` (~386 KB) |
| :--- | :--- | :--- |
| **国家 IP 支持** | 全球 260+ 国家与地区 (包含全部长尾国家) | 核心国家与地区 (CN, US, HK, JP, TW, SG, GB, DE 等) |
| **专有服务商标签** | ✅ 包含 `telegram`, `cloudflare`, `google`, `facebook`, `private` 等 | ✅ 包含 `telegram`, `cloudflare`, `google`, `facebook`, `private` 等 |
| **ASN 匹配支持** | ✅ 原生内置全球 **8.4 万个所有 ASN** (如 `IP-ASN,4134`, `IP-ASN,13335`) | ✅ 在 `rkt` 中自动映射支持 **Top 主流大厂 ASN** (如 `IP-ASN,13335` Cloudflare、`IP-ASN,15169` Google、`IP-ASN,62041` Telegram 等) |
| **内存开销** | 约 10~15 MB 常驻内存 | **仅 ~500 KB 极低内存** |
| **最佳推荐设备** | PC 桌面端、云服务器、高性能网关 | OpenWrt 软路由、嵌入式开发板、低闪存/低内存路由器 |

---

## ⚙️ 在 rkt 中使用

### 1. 在线 Rule Provider 自动更新配置（推荐）
在 `config.yaml` 中声明远程规则源：

```yaml
rule-providers:
  # 广告拦截
  geosite-ads:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-category-ads-all.rrs"
    interval: 86400

  # OpenAI 专属分流
  geosite-openai:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-openai.rrs"
    interval: 86400

  # 国内直连域名与 IP
  geosite-cn:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-cn.rrs"
    interval: 86400

  geoip-cn:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-cn.rrs"
    interval: 86400

rules:
  - RULE-SET,geosite-ads,REJECT
  - RULE-SET,geosite-openai,OpenAI-Proxy
  - RULE-SET,geosite-cn,DIRECT
  - RULE-SET,geoip-cn,DIRECT
  - GEOIP,telegram,TG-Proxy
  - GEOIP,cloudflare,DIRECT
  - GEOIP,private,DIRECT
  - MATCH,PROXY
```

### 2. 离线全量放置使用
1. 下载 `BundleRRS.7z`（或精简版 `BundleRRS-lite.7z`）解压至 `rulesets/` 目录。
2. 或下载单个 `geoip.rdb`（或软路由专用的 `geoip-lite.rdb`）放入 `rulesets/` 目录。
3. `rkt` 启动时将自动扫描并挂载，微秒级加载所有规则。

---

## 🛠️ 本地编译与开发者工具

本项目使用 `rkt-rules-compiler`（基于 Rust 构建）进行高效清洗与压缩：

```bash
# 1. 审查任意 .rrs 规则集或 .rdb 复合数据库
rkt-rules-compiler inspect dist/geosite/geosite-cn.rrs
rkt-rules-compiler inspect publish/geoip.rdb
rkt-rules-compiler inspect publish/geoip-lite.rdb

# 2. 测试目标域名/IP 匹配结果
rkt-rules-compiler test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
rkt-rules-compiler test ip --ruleset publish/geoip.rdb --target "114.114.114.114"
rkt-rules-compiler test ip --ruleset publish/geoip-lite.rdb --target "1.1.1.1"
```
