# rkt-rules-data

## 资源下载

| 文件名 | GitHub | jsDelivr | TestingCF | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **geoip.rdb** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/geoip.rdb) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip.rdb) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip.rdb) | 标准全球 IP 数据库 |
| **geoip-lite.rdb** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/geoip-lite.rdb) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip-lite.rdb) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip-lite.rdb) | 复合精简 IP 数据库 |
| **BundleRRS.7z** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/BundleRRS.7z) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS.7z) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS.7z) | 全量 `.rrs` 压缩包 |
| **BundleRRS-lite.7z** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/BundleRRS-lite.7z) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS-lite.7z) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS-lite.7z) | 常用精简 `.rrs` 压缩包 |

### 独立规则集 (按需直连)

各分类原生二进制规则集位于 [rrs 分支](https://github.com/lparam/rkt-rules-data/tree/rrs)。

- **geosite**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/{name}.rrs`
- **geoip**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geoip/{name}.rrs`
- **asn**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/asn/{name}.rrs`

---

## 规则配置示例

```yaml
rules:
  # 广告拦截 (全能旗舰版，或使用轻量版 geosite-category-ads-lite)
  - RULE-SET,geosite-category-ads-all,REJECT

  # 本地直连
  - RULE-SET,geosite-cn,DIRECT
  - GEOIP,CN,DIRECT

  # 自治域分流 (依赖 geoip.rdb 或 asn/*.rrs)
  - IP-ASN,13335,CF-Proxy
  - IP-ASN,15169,Google-Proxy

  # 兜底分流
  - MATCH,PROXY
```

---

## 数据源说明

- **geosite**: 主力分流同步自 [@v2fly/domain-list-community](https://github.com/v2fly/domain-list-community) 官方社区一手源
- **geosite-category-ads-all**: 旗舰广告拦截，融合自 [@Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat/tree/release) 与 [@privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)（海内外全量通杀）
- **geosite-category-ads-lite**: 轻量精简广告拦截，基于 [@v2fly/domain-list-community](https://github.com/v2fly/domain-list-community) 原生广告集（极低内存、零误杀）
- **geoip**: 基础数据同步自 [@Dreamacro/maxmind-geoip](https://github.com/Dreamacro/maxmind-geoip/tree/release)
- **asn**: 自治域数据库同步自 [@xishang0128/geoip](https://github.com/xishang0128/geoip/tree/release)
