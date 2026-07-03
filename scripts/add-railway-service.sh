#!/bin/bash

set -e

# 配置变量
REPO_URL=""
PB_INSTANCE_NAME="pb"
JSON_FILE=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
BATCH_SIZE=10
SCHEMA_FILE="pb_schema.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --repo <url>           Railway 模板仓库地址"
    echo "  --instance <name>      PocketBase 实例名称 (默认: pb)"
    echo "  --json <file>          导出的 JSON 数据文件"
    echo "  --email <email>        管理员邮箱"
    echo "  --password <password>  管理员密码"
    echo "  --schema <file>        Schema 文件路径 (默认: pb_schema.json)"
    echo "  --batch <num>          批量处理数量 (默认: 10)"
    echo "  -h, --help             显示帮助"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            --instance)
                PB_INSTANCE_NAME="$2"
                shift 2
                ;;
            --json)
                JSON_FILE="$2"
                shift 2
                ;;
            --email)
                ADMIN_EMAIL="$2"
                shift 2
                ;;
            --password)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --schema)
                SCHEMA_FILE="$2"
                shift 2
                ;;
            --batch)
                BATCH_SIZE="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

deploy_template() {
    log_info "步骤 1/5: 部署 Railway 模板..."

    if [ -z "$REPO_URL" ]; then
        log_warn "未提供仓库地址，跳过模板部署步骤"
        log_warn "请手动部署模板并设置环境变量"
        return 0
    fi

    if command -v railway &> /dev/null; then
        railway link --confirm --project "$REPO_URL" 2>/dev/null || true
        railway up -- service "$PB_INSTANCE_NAME" 2>/dev/null || true
        log_info "模板部署完成"
    else
        log_warn "Railway CLI 未安装，请手动部署模板"
        log_info "访问: https://railway.app/template/$(basename $REPO_URL)"
    fi
}

get_rpc_url() {
    log_info "步骤 2/5: 获取 RPC 服务地址..."

    if [ -n "$PB_RPC_URL" ]; then
        log_info "使用指定的 RPC 地址: $PB_RPC_URL"
        return 0
    fi

    if command -v railway &> /dev/null; then
        PB_RPC_URL=$(railway variables list --service "$PB_INSTANCE_NAME" | grep -o 'PB_HTTP=[^ ]*' | cut -d= -f2 || echo "http://localhost:8090")
        log_info "RPC 服务地址: $PB_RPC_URL"
    else
        log_warn "Railway CLI 未安装，使用默认地址"
        PB_RPC_URL="${PB_RPC_URL:-http://localhost:8090}"
    fi
}

import_schema() {
    log_info "步骤 3/5: 导入集合结构..."

    if [ ! -f "$SCHEMA_FILE" ]; then
        log_warn "Schema 文件不存在: $SCHEMA_FILE，跳过导入"
        return 0
    fi

    if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ] && [ -n "$PB_RPC_URL" ]; then
        log_info "使用 Node.js 工具导入 schema..."
        node tools/pb_upsert.js \
            --url "$PB_RPC_URL" \
            --email "$ADMIN_EMAIL" \
            --password "$ADMIN_PASSWORD" \
            --file "$SCHEMA_FILE" \
            --batch "$BATCH_SIZE"
        log_info "Schema 导入完成"
    else
        log_warn "缺少认证信息或 RPC 地址，跳过 schema 导入"
        log_info "请手动运行:"
        log_info "  node tools/pb_upsert.js --url <url> --email <email> --password <password> --file $SCHEMA_FILE"
    fi
}

import_records() {
    log_info "步骤 4/5: 导入数据记录..."

    if [ -z "$JSON_FILE" ]; then
        log_warn "未提供 JSON 数据文件，跳过记录导入"
        return 0
    fi

    if [ ! -f "$JSON_FILE" ]; then
        log_error "JSON 文件不存在: $JSON_FILE"
        exit 1
    fi

    if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ] && [ -n "$PB_RPC_URL" ]; then
        log_info "使用 Node.js 工具导入记录..."
        node tools/pb_upsert.js \
            --url "$PB_RPC_URL" \
            --email "$ADMIN_EMAIL" \
            --password "$ADMIN_PASSWORD" \
            --file "$JSON_FILE" \
            --batch "$BATCH_SIZE"
        log_info "记录导入完成"
    else
        log_warn "缺少认证信息或 RPC 地址，跳过记录导入"
        log_info "请手动运行:"
        log_info "  node tools/pb_upsert.js --url <url> --email <email> --password <password> --file $JSON_FILE"
    fi
}

print_summary() {
    log_info "步骤 5/5: 部署完成"
    echo ""
    log_info "=== 部署摘要 ==="
    log_info "实例名称: $PB_INSTANCE_NAME"
    log_info "RPC 地址: ${PB_RPC_URL:-未设置}"
    log_info "Schema 文件: $SCHEMA_FILE"
    log_info "数据文件: ${JSON_FILE:-未提供}"
    log_info "=================="
    echo ""
    log_info "下一步操作:"
    log_info "1. 访问 PocketBase 管理面板: ${PB_RPC_URL:-<RPC_URL>}/_/"
    log_info "2. 使用管理员账户登录"
    log_info "3. 检查集合和数据是否正确导入"
}

main() {
    parse_args "$@"

    log_info "开始部署 PocketBase Railway 服务..."
    echo ""

    deploy_template
    get_rpc_url
    import_schema
    import_records
    print_summary

    log_info "所有步骤完成！"
}

main "$@"
