# rkt-rules-data

`rkt-rules-data` 为 `rkt` 提供高性能、低内存的原生二进制规则集（`.rrs`）与 GeoIP 数据库（`.rdb`）。每日北京时间凌晨 04:00 自动从权威一手源清洗编译。

---

## 📦 分支产物概览

### 1. `release` 分支（归档总包与数据库）

| 文件名 | 说明 | 体积 |
| :--- | :--- | :--- |
| **`geoip.rdb`** | **标准全球 IP 数据库**（对齐 sing-box 纯净基数树，65.7 万节点） | **~3.76 MB** |
| **`geoip-lite.rdb`** | **复合精简 IP 库**（核心国家 + 常用大厂标签 + 主流 ASN 映射，软路由首选） | **~380 KB** |
| **`BundleRRS.7z`** | 全量 1,800+ 原生 `.rrs` 规则集归档压缩包 | **~9.1 MB** |
| **`BundleRRS-lite.7z`** | 常用核心 `.rrs` 规则集归档压缩包 | **~2.2 MB** |
| **`sha256sums.txt`** | 全量资产 SHA256 校验和 | ~1 KB |

---

### 2. `rrs` 分支（单文件按需下载 / CDN 加速）

所有 `.rrs` 规则集按类别平铺，支持 jsDelivr 全球 CDN 直连：

#### 常用域名规则 (Geosite)
- 全网去广告: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/geosite-category-ads-all.rrs`
- 国内直连: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/geosite-cn.rrs`
- 国外非大陆: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/geosite-geolocation-!cn.rrs`
- OpenAI: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/geosite-openai.rrs`
- Google: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/geosite-google.rrs`

#### 常用 IP / ASN 规则 (GeoIP & ASN)
- 中国大陆 IP: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geoip/geoip-cn.rrs`
- 局域网保留 IP: `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geoip/geoip-private.rrs`
- Cloudflare (AS13335): `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/asn/AS13335.rrs`
- Google (AS15169): `https://fastly.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/asn/AS15169.rrs`

---

## ⚙️ 在 rkt 中使用

将下载的 `.rrs` 规则集或 `geoip.rdb` 放置在配置目录的 `rulesets/` 下即可生效：

```yaml
rules:
  # 广告拦截
  - RULE-SET,geosite-category-ads-all,REJECT

  # 国内直连
  - RULE-SET,geosite-cn,DIRECT
  - GEOIP,CN,DIRECT

  # 热门自治域分流 (依赖 geoip.rdb 或按需引入 asn/AS*.rrs)
  - IP-ASN,13335,CF-Proxy
  - IP-ASN,15169,Google-Proxy

  # 兜底代理
  - MATCH,PROXY
```

---

## 🛠️ 本地编译与校验

```bash
# 全流程自动化编译与测试
bash build.sh

# 审查规则集或数据库条目
tools/bin/rkt-rules-compiler inspect publish/geoip.rdb
tools/bin/rkt-rules-compiler inspect dist/geosite/geosite-cn.rrs

# 规则命中测试
tools/bin/rkt-rules-compiler test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
tools/bin/rkt-rules-compiler test ip --ruleset publish/geoip.rdb --target "114.114.114.114"
```
