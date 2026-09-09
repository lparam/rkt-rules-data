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

# 3. 下载上游数据 (直接对接 MaxMind, Loyalsoldier 与 xishang0128 一手数据源)
echo "🌐 正在下载上游清洗规则数据源 (带多级容灾与镜像加速)..."
cd "${SCRIPT_DIR}/raw"

download_file() {
    local target="$1"
    local primary_url="$2"
    local backup_url="$3"

    if [ -s "${target}" ]; then
        echo "⚡ ${target} 已存在且非空，跳过重复下载"
        return 0
    fi

    echo "⬇️ 正在下载 ${target}..."
    if ! curl -fL --retry 2 --retry-delay 2 -C - -o "${target}" "${primary_url}"; then
        echo "⚠️ 首选源连接异常，正在尝试备用镜像..."
        if [ -n "${backup_url}" ] && curl -fL --retry 2 --retry-delay 2 -C - -o "${target}" "${backup_url}"; then
            return 0
        fi
        echo "⚠️ 备用镜像连接异常，正在通过加速镜像 ghproxy.net 获取..."
        curl -fL --retry 3 --retry-delay 2 -C - -o "${target}" "https://ghproxy.net/${primary_url}"
    fi
}

# 编译原材料全量数据
download_file "Country.mmdb" \
    "https://github.com/Dreamacro/maxmind-geoip/raw/release/Country.mmdb" \
    "https://fastly.jsdelivr.net/gh/Dreamacro/maxmind-geoip@release/Country.mmdb"

download_file "GeoLite2-ASN.mmdb" \
    "https://raw.githubusercontent.com/xishang0128/geoip/release/GeoLite2-ASN.mmdb" \
    "https://fastly.jsdelivr.net/gh/xishang0128/geoip@release/GeoLite2-ASN.mmdb"

download_file "geoip.dat" \
    "https://github.com/Loyalsoldier/geoip/raw/release/geoip.dat" \
    "https://fastly.jsdelivr.net/gh/Loyalsoldier/geoip@release/geoip.dat"

download_file "geosite.dat" \
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat" \
    "https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat"

# 软路由精简数据 (Lite)
download_file "geoip-lite.dat" \
    "https://github.com/xishang0128/geoip/raw/release/geoip.dat" \
    "https://fastly.jsdelivr.net/gh/xishang0128/geoip@release/geoip.dat"

echo "✅ 上游数据准备完毕"

# 4. 调用编译器生成 .rrs
echo "⚡ 正在批量编译规则集为 .rrs 二进制格式..."
cd "${SCRIPT_DIR}"

"${COMPILER}" convert site --input raw/geosite.dat --output-dir dist/geosite/
"${COMPILER}" convert ip --input raw/geoip.dat --output-dir dist/geoip/
"${COMPILER}" convert asn --input raw/GeoLite2-ASN.mmdb --output-dir dist/asn/ --hot-only
echo "✅ 规则集编译完成"

# 5. 编译纯净 3.76MB geoip.rdb 与 380KB 复合精简库 geoip-lite.rdb
echo "🌐 正在自主编译 geoip.rdb (对齐 sing-box 纯净国家前缀树) 与 geoip-lite.rdb (复合精简库)..."
go -C "${SCRIPT_DIR}/tools" run build_geoip.go -input "${SCRIPT_DIR}/raw/Country.mmdb" -output "${SCRIPT_DIR}/publish/geoip.rdb"

if ! command -v geo >/dev/null 2>&1; then
    echo "📦 正在安装 geo 转换工具..."
    GOPROXY=https://proxy.golang.org,direct GIT_CONFIG_GLOBAL=/dev/null go install -trimpath -ldflags="-s -w" github.com/metacubex/geo/cmd/geo@master
fi
geo convert ip -i v2ray -o meta -f "${SCRIPT_DIR}/publish/geoip-lite.rdb" "${SCRIPT_DIR}/raw/geoip-lite.dat"
echo "✅ 数据库编译完成"

# 6. 校验与审查产物
echo "🔍 正在抽样审查编译产物与复合数据库..."
"${COMPILER}" inspect dist/geosite/geosite-cn.rrs
"${COMPILER}" inspect dist/geosite/geosite-openai.rrs
"${COMPILER}" inspect dist/geoip/geoip-cn.rrs
"${COMPILER}" inspect dist/asn/AS13335.rrs
"${COMPILER}" inspect publish/geoip.rdb
"${COMPILER}" inspect publish/geoip-lite.rdb

# 7. 规则命中测试
echo "🧪 正在执行规则匹配测试..."
"${COMPILER}" test domain --ruleset dist/geosite/geosite-cn.rrs --target "baidu.com"
"${COMPILER}" test domain --ruleset dist/geosite/geosite-openai.rrs --target "api.openai.com"
"${COMPILER}" test ip --ruleset dist/geoip/geoip-cn.rrs --target "114.114.114.114"
"${COMPILER}" test ip --ruleset dist/asn/AS13335.rrs --target "1.1.1.1"
"${COMPILER}" test ip --ruleset publish/geoip.rdb --target "114.114.114.114"
"${COMPILER}" test ip --ruleset publish/geoip-lite.rdb --target "114.114.114.114"

# 8. 打包归档 Full 与 Lite 总包
echo "📦 正在打包归档资产..."
cd "${SCRIPT_DIR}/dist"
7z a -mx=9 "${SCRIPT_DIR}/publish/BundleRRS.7z" ./*/*.rrs

mkdir -p /tmp/lite_rrs
cp geosite/geosite-cn.rrs geosite/geosite-openai.rrs geosite/geosite-google.rrs geosite/geosite-category-ads-all.rrs geoip/geoip-cn.rrs geoip/geoip-private.rrs /tmp/lite_rrs/ 2>/dev/null || true
cd /tmp/lite_rrs && 7z a -mx=9 "${SCRIPT_DIR}/publish/BundleRRS-lite.7z" ./*.rrs && cd -
rm -rf /tmp/lite_rrs

# 生成校验和
cd "${SCRIPT_DIR}/publish"
sha256sum * > sha256sums.txt

# 9. 自动同步交付物到本地 rrs 与 release 分支 (Orphan 单 Commit 覆盖，根绝 Git 历史体积膨胀)
echo "🌿 正在将生成交付物同步至本地 rrs 与 release 分支 (Orphan 单 Commit 覆盖模式)..."
rm -rf /tmp/rkt_data_dist /tmp/rkt_data_pub
mkdir -p /tmp/rkt_data_dist /tmp/rkt_data_pub
cp -r "${SCRIPT_DIR}/dist"/* /tmp/rkt_data_dist/
cp -r "${SCRIPT_DIR}/publish"/* /tmp/rkt_data_pub/

CURRENT_BRANCH="$(git -C "${SCRIPT_DIR}" branch --show-current)"

# 同步 rrs 分支 (无历史父提交，永远单 Commit，仅保留纯净产物)
git -C "${SCRIPT_DIR}" checkout --orphan rrs-temp >/dev/null 2>&1
find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name 'raw' -exec rm -rf {} +
cp -r /tmp/rkt_data_dist/* "${SCRIPT_DIR}/"
git -C "${SCRIPT_DIR}" checkout master -- README.md .gitignore >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" add -f asn geosite geoip README.md
git -C "${SCRIPT_DIR}" commit -m "Auto-compiled rulesets: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >/dev/null 2>&1
git -C "${SCRIPT_DIR}" branch -D rrs >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" branch -m rrs

# 同步 release 分支 (无历史父提交，永远单 Commit，仅保留纯净资产包与数据库)
git -C "${SCRIPT_DIR}" checkout --orphan release-temp >/dev/null 2>&1
find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name 'raw' -exec rm -rf {} +
cp -r /tmp/rkt_data_pub/* "${SCRIPT_DIR}/"
git -C "${SCRIPT_DIR}" checkout master -- README.md .gitignore >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" add -f BundleRRS.7z BundleRRS-lite.7z geoip.rdb geoip-lite.rdb sha256sums.txt README.md
git -C "${SCRIPT_DIR}" commit -m "Release assets: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >/dev/null 2>&1
git -C "${SCRIPT_DIR}" branch -D release >/dev/null 2>&1 || true
git -C "${SCRIPT_DIR}" branch -m release

git -C "${SCRIPT_DIR}" checkout "${CURRENT_BRANCH}"
rm -rf /tmp/rkt_data_dist /tmp/rkt_data_pub

# 自动修剪悬空历史对象，保持 .git 极度轻巧
git -C "${SCRIPT_DIR}" gc --prune=now --quiet 2>/dev/null || true

echo "============================================================"
echo "🎉 全流程构建成功！rrs 与 release 交付分支已由单 Commit 重置就绪！"
echo "📊 publish/ 目录产物概览："
echo "✨ rrs 分支：仅含纯净 asn/ geoip/ geosite/ 二进制规则集"
echo "📦 release 分支：包含全量 Bundle 压缩包、纯净 geoip.rdb (3.76MB)、geoip-lite.rdb (380KB) 与校验文件"
echo "============================================================"
