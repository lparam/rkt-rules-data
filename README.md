# rkt-rules-data

`rkt-rules-data` 是 `rkt` 项目的官方规则集资产仓库，通过 GitHub Actions 实现 24 小时无人值守的自动化数据同步、清洗与编译，为 `rkt` 与 `rkt-desktop` 提供高性能、低内存、全自动构建的原生二进制规则集资产（`.rrs`）与经典兼容数据库。

---

## 🌟 核心特性

- **原生二进制 `.rrs` 极速加载**：基于压缩前缀树（Succinct Trie）与紧凑网段编码，微秒级匹配，内存占用对比传统文本降低 90%+。
- **每日自动构建**：每日北京时间凌晨 04:00 自动同步上游权威数据源（`Loyalsoldier`、`xishang0128`、`P3TERX` 等）并编译最新规则。
- **全球 CDN 按需加速**：平铺数万个微型 `.rrs` 文件（通常 1~10 KB），客户端冷启动秒级拉取。
- **双梯队产物**：同时提供面向 PC/服务器的 **Full 全量产物**，以及专为 OpenWrt 软路由/嵌入式设备设计的 **Lite 精简产物**。

---

## 📦 分支组织与产物索引

### 1. `rrs` 分支（CDN 单文件按需加速层）
存放所有单独平铺的 `.rrs` 规则集文件，支持 jsDelivr / Fastly 全球 CDN 直连：

```text
├── geosite/
│   ├── geosite-cn.rrs
│   ├── geosite-openai.rrs
│   ├── geosite-google.rrs
│   ├── geosite-category-ads-all.rrs
│   └── ... (约 3,000+ 域名分类规则集)
├── geoip/
│   ├── geoip-cn.rrs
│   ├── geoip-private.rrs
│   └── ... (200+ 国家与区域 IP 规则集)
└── asn/
    ├── AS13335.rrs (Cloudflare)
    ├── AS15169.rrs (Google)
    └── ... (Top 1,000+ 热门自治域)
```

**CDN 引用格式**：
```text
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-openai.rrs
https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-cn.rrs
```

---

### 2. `release` 分支（全量与精简发布包）

| 产物名称 | 说明 | 适用场景 | 预估体积 |
| :--- | :--- | :--- | :--- |
| `BundleRRS.7z` | 全量 8.4 万个 `.rrs` 规则集归档总包 | PC / 桌面端离线部署 | ~6 MB |
| `BundleRRS-lite.7z` | 200+ 高频核心 `.rrs` 归档精简包 | OpenWrt 软路由首选 | ~300 KB |
| `direct-list.rrs` | 国内直连白名单 | 开箱即用三件套 | ~500 KB |
| `proxy-list.rrs` | 常用代理名单 | 开箱即用三件套 | ~13 KB |
| `reject-list.rrs` | 广告拦截名单 | 开箱即用三件套 | ~8 KB |
| `country-lite.mmdb` | MaxMind 精简国家库 | 软路由低内存首选 | ~390 KB |
| `country.mmdb` | MaxMind 全量国家库 | 服务器 / PC 首选 | ~7.8 MB |
| `GeoLite2-ASN.mmdb`| MaxMind 全量 ASN 自治域库 | 服务器 / PC 首选 | ~12 MB |
| `geosite.dat` / `geoip.dat` | V2Ray 全量兼容库 | 兼容传统客户端 | ~4.2 MB / ~17 MB |

---

## ⚙️ 在 rkt 中使用

### 1. 声明远程 Rule Provider
在 `config.yaml` 中配置自动更新：

```yaml
rule-providers:
  geosite-cn:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-cn.rrs"
    interval: 86400

  geosite-openai:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geosite/geosite-openai.rrs"
    interval: 86400

  geoip-cn:
    type: http
    format: rrs
    url: "https://fastly.jsdelivr.net/gh/<owner>/rkt-rules-data@rrs/geoip/geoip-cn.rrs"
    interval: 86400

rules:
  - RULE-SET,geosite-openai,PROXY
  - RULE-SET,geosite-cn,DIRECT
  - RULE-SET,geoip-cn,DIRECT
  - MATCH,PROXY
```

### 2. 本地离线放置
将 `BundleRRS.7z` 或单个 `.rrs` 文件解压至 `rulesets/` 目录即可，`rkt` 与 `rkt-desktop` 启动时会自动扫描并关联。
