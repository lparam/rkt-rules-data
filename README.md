# rkt-rules-data

## 资源下载

| 文件名 | GitHub Release | jsDelivr CDN | TestingCF CDN | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **geoip.rdb** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/geoip.rdb) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip.rdb) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip.rdb) | 标准全球 IP 数据库 (~3.76 MB) |
| **geoip-lite.rdb** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/geoip-lite.rdb) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip-lite.rdb) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/geoip-lite.rdb) | 复合精简 IP 数据库 (~380 KB) |
| **BundleRRS.7z** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/BundleRRS.7z) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS.7z) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS.7z) | 全量 `.rrs` 规则集压缩包 (~9.1 MB) |
| **BundleRRS-lite.7z** | [下载](https://github.com/lparam/rkt-rules-data/releases/download/latest/BundleRRS-lite.7z) | [下载](https://cdn.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS-lite.7z) | [下载](https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@release/BundleRRS-lite.7z) | 常用精简 `.rrs` 压缩包 (~2.2 MB) |

### 独立规则集 (按需直连)

各分类原生二进制规则集位于 [rrs 分支](https://github.com/lparam/rkt-rules-data/tree/rrs)。

- **geosite**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geosite/{name}.rrs`
- **geoip**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/geoip/{name}.rrs`
- **asn**: `https://testingcf.jsdelivr.net/gh/lparam/rkt-rules-data@rrs/asn/{name}.rrs`

---

## 规则配置示例

```yaml
rules:
  # 广告拦截
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

- **geosite**: 上游同步自 [@v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)
- **geoip**: 基础数据同步自 [@Dreamacro/maxmind-geoip](https://github.com/Dreamacro/maxmind-geoip)
- **asn**: 自治域数据库同步自 [@xishang0128/geoip](https://github.com/xishang0128/geoip)
