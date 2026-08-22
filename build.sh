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

curl -fsSL --retry 3 --retry-delay 2 -o GeoLite2-ASN.mmdb https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o Country.mmdb https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o geoip.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat
curl -fsSL --retry 3 --retry-delay 2 -o geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat

curl -fsSL --retry 3 --retry-delay 2 -o Country-lite.mmdb https://raw.githubusercontent.com/xishang0128/geoip/release/Country.mmdb
curl -fsSL --retry 3 --retry-delay 2 -o geoip-lite.dat https://github.com/xishang0128/geoip/raw/release/geoip.dat
curl -fsSL --retry 3 --retry-delay 2 -o geoip.metadb https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.metadb

curl -fsSL --retry 3 --retry-delay 2 -o direct-list.txt https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt
curl -fsSL --retry 3 --retry-delay 2 -o proxy-list.txt https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt
curl -fsSL --retry 3 --retry-delay 2 -o reject-list.txt https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt
echo "✅ 上游数据下载完毕"

# 4. 调用编译器生成 .rrs
echo "⚡ 正在批量编译规则集为 .rrs 二进制格式..."
cd "${SCRIPT_DIR}"

"${COMPILER}" convert site --input raw/geosite.dat --output-dir dist/geosite/
"${COMPILER}" convert ip --input raw/geoip.dat --output-dir dist/geoip/
"${COMPILER}" convert asn --input raw/GeoLite2-ASN.mmdb --output-dir dist/asn/ --hot-only

"${COMPILER}" convert text --input raw/direct-list.txt --output dist/direct-list.rrs --type domain
"${COMPILER}" convert text --input raw/proxy-list.txt --output dist/proxy-list.rrs --type domain
"${COMPILER}" convert text --input raw/reject-list.txt --output dist/reject-list.rrs --type domain
echo "✅ 规则集编译完成"

# 5. 校验与审查产物
echo "🔍 正在抽样审查编译产物与复合数据库..."
"${COMPILER}" inspect dist/geosite/geosite-cn.rrs
"${COMPILER}" inspect dist/geosite/geosite-openai.rrs
"${COMPILER}" inspect dist/geoip/geoip-cn.rrs
"${COMPILER}" inspect dist/asn/AS13335.rrs
"${COMPILER}" inspect raw/geoip.metadb

# 6. 规则命中测试
echo "🧪 正在执行规则匹配测试..."
"${COMPILER}" test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
"${COMPILER}" test domain --ruleset dist/geosite/geosite-openai.rrs --target "api.openai.com"
"${COMPILER}" test ip --ruleset dist/geoip/geoip-cn.rrs --target "114.114.114.114"
"${COMPILER}" test ip --ruleset dist/asn/AS13335.rrs --target "1.1.1.1"

# 7. 打包归档 Full 与 Lite 总包
echo "📦 正在打包归档资产..."
cd "${SCRIPT_DIR}/dist"
7z a -mx=9 "${SCRIPT_DIR}/publish/BundleRRS.7z" ./*.rrs ./*/*.rrs

mkdir -p /tmp/lite_rrs
cp geosite/geosite-cn.rrs geosite/geosite-openai.rrs geosite/geosite-google.rrs geosite/geosite-category-ads-all.rrs geoip/geoip-cn.rrs geoip/geoip-private.rrs ./*.rrs /tmp/lite_rrs/ 2>/dev/null || true
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
cp dist/*.rrs publish/

# 生成校验和
cd publish
sha256sum * > sha256sums.txt

echo "============================================================"
echo "🎉 全流程构建与测试成功完成！"
echo "📊 publish/ 目录产物概览："
ls -lh "${SCRIPT_DIR}/publish"
echo "============================================================"
