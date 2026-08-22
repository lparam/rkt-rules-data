#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../rkt" && pwd)"

echo "============================================================"
echo "🚀 开始本地构建与测试 rkt-rules-data 流水线"
echo "============================================================"

# 1. 编译本地 rkt-rules-compiler 二进制
echo "📦 正在编译 rkt-rules-compiler..."
cargo build --release --manifest-path "${WORKSPACE_ROOT}/Cargo.toml" -p rkt-rules --bin rkt-rules-compiler
COMPILER="${WORKSPACE_ROOT}/target/release/rkt-rules-compiler"
if [ ! -f "${COMPILER}" ]; then
    echo "❌ 编译器构建失败，未找到 ${COMPILER}"
    exit 1
fi
echo "✅ 编译器就绪: ${COMPILER}"

# 2. 准备目录
mkdir -p "${SCRIPT_DIR}/raw" "${SCRIPT_DIR}/dist/geosite" "${SCRIPT_DIR}/dist/geoip" "${SCRIPT_DIR}/dist/asn" "${SCRIPT_DIR}/publish"

# 3. 下载上游数据
echo "🌐 正在下载上游清洗规则数据源 (带重试)..."
cd "${SCRIPT_DIR}/raw"

# 全量数据
curl -fsSL --retry 3 --retry-delay 2 -o GeoLite2-ASN.mmdb https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o Country.mmdb https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o geoip.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat
curl -fsSL --retry 3 --retry-delay 2 -o geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat
curl -fsSL --retry 3 --retry-delay 2 -o geoip.metadb https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.metadb

# 精简数据 (Lite)
curl -fsSL --retry 3 --retry-delay 2 -o Country-lite.mmdb https://raw.githubusercontent.com/xishang0128/geoip/release/Country.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o geoip-lite.dat https://github.com/xishang0128/geoip/raw/release/geoip.dat
curl -fsSL --retry 3 --retry-delay 2 -o geoip-lite.metadb https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip-lite.metadb
echo "✅ 上游数据下载完毕"

# 4. 调用编译器生成 .rrs
echo "⚡ 正在批量编译规则集为 .rrs 二进制格式..."
cd "${SCRIPT_DIR}"

"${COMPILER}" convert site --input raw/geosite.dat --output-dir dist/geosite/
"${COMPILER}" convert ip --input raw/geoip.dat --output-dir dist/geoip/
"${COMPILER}" convert asn --input raw/GeoLite2-ASN.mmdb --output-dir dist/asn/ --hot-only
echo "✅ 规则集编译完成"

# 5. 校验与审查产物
echo "🔍 正在抽样审查编译产物与复合数据库..."
"${COMPILER}" inspect dist/geosite/geosite-cn.rrs
"${COMPILER}" inspect dist/geosite/geosite-openai.rrs
"${COMPILER}" inspect dist/geoip/geoip-cn.rrs
"${COMPILER}" inspect dist/asn/AS13335.rrs
"${COMPILER}" inspect raw/geoip.metadb
"${COMPILER}" inspect raw/geoip-lite.metadb

# 6. 规则命中测试
echo "🧪 正在执行规则匹配测试..."
"${COMPILER}" test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
"${COMPILER}" test domain --ruleset dist/geosite/geosite-openai.rrs --target "api.openai.com"
"${COMPILER}" test ip --ruleset dist/geoip/geoip-cn.rrs --target "114.114.114.114"
"${COMPILER}" test ip --ruleset dist/asn/AS13335.rrs --target "1.1.1.1"
"${COMPILER}" test ip --ruleset raw/geoip.metadb --target "114.114.114.114"
"${COMPILER}" test ip --ruleset raw/geoip-lite.metadb --target "114.114.114.114"

# 7. 打包归档 Full 与 Lite 总包
echo "📦 正在打包归档资产..."
cd "${SCRIPT_DIR}/dist"
7z a -mx=9 "${SCRIPT_DIR}/publish/BundleRRS.7z" ./*/*.rrs

mkdir -p /tmp/lite_rrs
cp geosite/geosite-cn.rrs geosite/geosite-openai.rrs geosite/geosite-google.rrs geosite/geosite-category-ads-all.rrs geoip/geoip-cn.rrs geoip/geoip-private.rrs /tmp/lite_rrs/ 2>/dev/null || true
cd /tmp/lite_rrs && 7z a -mx=9 "${SCRIPT_DIR}/publish/BundleRRS-lite.7z" ./*.rrs && cd -
rm -rf /tmp/lite_rrs

# 复制常用数据库与单文件
cd "${SCRIPT_DIR}"
cp raw/Country.mmdb publish/country.mmdb
cp raw/Country-lite.mmdb publish/country-lite.mmdb
cp raw/GeoLite2-ASN.mmdb publish/GeoLite2-ASN.mmdb
cp raw/geoip.dat publish/geoip.dat
cp raw/geoip-lite.dat publish/geoip-lite.dat
cp raw/geosite.dat publish/geosite.dat
cp raw/geoip.metadb publish/geoip.metadb
cp raw/geoip.metadb publish/geoip.rdb
cp raw/geoip-lite.metadb publish/geoip-lite.metadb
cp raw/geoip-lite.metadb publish/geoip-lite.rdb

# 生成校验和
cd publish
sha256sum * > sha256sums.txt

# 8. 自动同步交付物到本地 rrs 与 release 分支 (Orphan 单 Commit 覆盖，根绝 Git 历史体积膨胀)
echo "🌿 正在将生成交付物同步至本地 rrs 与 release 分支 (Orphan 单 Commit 覆盖模式)..."
rm -rf /tmp/rkt_data_dist /tmp/rkt_data_pub
mkdir -p /tmp/rkt_data_dist /tmp/rkt_data_pub
cp -r "${SCRIPT_DIR}/dist"/* /tmp/rkt_data_dist/
cp -r "${SCRIPT_DIR}/publish"/* /tmp/rkt_data_pub/

# 同步 rrs 分支 (无历史父提交，永远单 Commit，仅保留纯净产物)
git -C "${SCRIPT_DIR}" checkout --orphan rrs-temp >/dev/null 2>&1
find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -r /tmp/rkt_data_dist/* "${SCRIPT_DIR}/"
git -C "${SCRIPT_DIR}" checkout master -- README.md >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" add .
git -C "${SCRIPT_DIR}" commit -m "Auto-compiled rulesets: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >/dev/null 2>&1
git -C "${SCRIPT_DIR}" branch -D rrs >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" branch -m rrs

# 同步 release 分支 (无历史父提交，永远单 Commit，仅保留纯净资产包与数据库)
git -C "${SCRIPT_DIR}" checkout --orphan release-temp >/dev/null 2>&1
find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -r /tmp/rkt_data_pub/* "${SCRIPT_DIR}/"
git -C "${SCRIPT_DIR}" checkout master -- README.md >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" add .
git -C "${SCRIPT_DIR}" commit -m "Release assets: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >/dev/null 2>&1
git -C "${SCRIPT_DIR}" branch -D release >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" branch -m release

git -C "${SCRIPT_DIR}" checkout -f master
rm -rf /tmp/rkt_data_dist /tmp/rkt_data_pub

# 自动修剪悬空历史对象，保持 .git 极度轻巧
git -C "${SCRIPT_DIR}" gc --prune=now --quiet 2>/dev/null || true

echo "============================================================"
echo "🎉 全流程构建成功！rrs 与 release 交付分支已由单 Commit 重置就绪！"
echo "📊 publish/ 目录产物概览："
ls -lh "${SCRIPT_DIR}/publish"
echo "============================================================"
