# rkt-rules-data

`rkt-rules-data` 是 `rkt` 项目的官方规则集资产仓库，通过 GitHub Actions 实现 24 小时无人值守的自动化数据同步、清洗与编译，为 `rkt` 与 `rkt-desktop` 提供高性能、低内存、全自动构建的原生二进制规则集资产（`.rrs`）与复合原生数据库（`.rdb`）。

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
    ├── AS4134.rrs                         # 中国电信 163 骨干网 (5.6 KB)
    ├── AS4837.rrs                         # 中国联通 169 骨干网 (4.8 KB)
    ├── AS9808.rrs                         # 中国移动 CMNET 骨干网 (3.2 KB)
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

# 常用 ASN 自治域规则 (ASN)
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS13335.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS15169.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS4134.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS4837.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS9808.rrs
```

---

### 2. `release` 分支（离线大包与复合数据库）
存放离线打包、全量归档压缩包与复合三合一原生数据库：

| 产物名称 | 说明 | 适用场景 | 预估体积 |
| :--- | :--- | :--- | :--- |
| **`geoip.rdb`** | **复合三合一全量数据库**（国家 + 8.4 万全量 ASN + 专有标签） | 离线单文件全量首选 (PC/服务器) | **~8.4 MB** |
| **`geoip-lite.rdb`** | **复合三合一精简数据库**（核心国家 + 常用专有标签 + 主流 ASN 映射） | 软路由 / 低内存嵌入式设备首选 | **~386 KB** |
| **`BundleRRS.7z`** | 全量 1,800+ 个原生 `.rrs` 规则集归档总包 | PC / 桌面端离线部署 | **~9.2 MB** |
| **`BundleRRS-lite.7z`** | 常用核心 `.rrs` 规则集归档精简包 | 软路由离线极速安装 | **~2.6 MB** |
| **`sha256sums.txt`** | 全量发布资产哈希校验和 | 完整性校验 | ~1.2 KB |

---

## 🌐 ASN（自治系统）规则使用指南

ASN（Autonomous System Number）是互联网底层 BGP 路由的自治域编号。通过 ASN 进行分流比单纯的域名规则更底层、更精确，能够直接识别目标 IP 属于哪家运营商或云服务巨头。

### 1. 常见热门 ASN 编号速查表

| ASN 编号 | 所属机构 / 服务商 | 常见分流策略 |
| :--- | :--- | :--- |
| **AS4134** | **中国电信** (Chinanet 163 骨干网) | `DIRECT` 国内直连 |
| **AS4837** | **中国联通** (China169 骨干网) | `DIRECT` 国内直连 |
| **AS9808** | **中国移动** (CMNET 骨干网) | `DIRECT` 国内直连 |
| **AS37963** | **阿里云** (Alibaba Cloud) | `DIRECT` 国内云直连 |
| **AS45090** | **腾讯云** (Tencent Cloud) | `DIRECT` 国内云直连 |
| **AS13335** | **Cloudflare** (全球 CDN / 边缘节点) | `CF-Proxy` 专属代理/直连 |
| **AS15169** | **Google** (Alphabet 全系 IP) | `Google-Proxy` 专线代理 |
| **AS16509** | **Amazon AWS** (境外云主机/流媒体) | `Proxy` 代理 |
| **AS8075** | **Microsoft** (Azure / Office / Bing) | `Proxy` / `DIRECT` |
| **AS62041** / **AS44907** | **Telegram** (全球数据中心) | `TG-Proxy` 专线代理 |
| **AS32934** | **Meta** (Facebook / Instagram) | `Proxy` 代理 |

---

### 2. 在 `rkt` 中使用 ASN 的两种方式

#### 方式 A：使用 `IP-ASN` 规则（推荐，依赖 `geoip.rdb` 或 `geoip-lite.rdb`）
直接通过 ASN 编号进行动态匹配，语法与 Clash / sing-box 一致：

```conf
# 匹配国内运营商骨干网直连
IP-ASN,4134,DIRECT
IP-ASN,4837,DIRECT
IP-ASN,9808,DIRECT

# 匹配海外大厂与 CDN 走指定代理策略组
IP-ASN,13335,CF-Proxy
IP-ASN,15169,Google-Proxy
IP-ASN,62041,TG-Proxy
```

#### 方式 B：使用 `RULE-SET` 单体规则集（极致性能，依赖 `asn/*.rrs`）
如果不想加载大型数据库，只需按需拉取单个 ASN 规则集（每个仅几 KB，内存占用 < 20 KB，匹配速度 < 50 纳秒）：

```yaml
rule-providers:
  as-cloudflare:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/asn/AS13335.rrs"
    interval: 86400

rules:
  - RULE-SET,as-cloudflare,CF-Proxy
```

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
  - IP-ASN,13335,CF-Proxy
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
rkt-rules-compiler inspect dist/asn/AS13335.rrs
rkt-rules-compiler inspect publish/geoip.rdb
rkt-rules-compiler inspect publish/geoip-lite.rdb

# 2. 测试目标域名/IP 匹配结果
rkt-rules-compiler test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
rkt-rules-compiler test ip --ruleset publish/geoip.rdb --target "114.114.114.114"
rkt-rules-compiler test ip --ruleset publish/geoip-lite.rdb --target "1.1.1.1"
```
