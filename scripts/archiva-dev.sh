#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"
DEV_DATA_DIR="$ROOT_DIR/.dev-data"
CLIENT_DIR="$ROOT_DIR/client"
CLIENT_DIST_DIR="$CLIENT_DIR/dist"

BACKEND_PORT=1718
FRONTEND_PORT=1719

BACKEND_PID_FILE="$RUNTIME_DIR/backend.pid"
FRONTEND_PID_FILE="$RUNTIME_DIR/frontend.pid"
BACKEND_LOG="$RUNTIME_DIR/backend.log"
FRONTEND_LOG="$RUNTIME_DIR/frontend.log"

mkdir -p "$RUNTIME_DIR"

port_pid() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | head -n 1
}

pid_from_file() {
    local pid_file="$1"
    if [[ -f "$pid_file" ]]; then
        sed -n '1p' "$pid_file"
    fi
}

is_running() {
    [[ -n "$1" ]] && kill -0 "$1" 2>/dev/null
}

pid_matches() {
    local pid="$1"
    local pattern="$2"
    is_running "$pid" && ps -p "$pid" -o command= 2>/dev/null | grep -E "$pattern" >/dev/null 2>&1
}

print_service_status() {
    local label="$1"
    local pid_file="$2"
    local port="$3"
    local pattern="$4"
    local pid
    local listener

    pid="$(pid_from_file "$pid_file")"
    listener="$(port_pid "$port")"

    if [[ -n "$pid" ]] && pid_matches "$pid" "$pattern"; then
        printf '%-10s 已启动   PID=%s   端口=%s\n' "$label" "$pid" "$port"
    elif [[ -n "$listener" ]]; then
        printf '%-10s 端口被占用 PID=%s   端口=%s\n' "$label" "$listener" "$port"
    else
        printf '%-10s 已停止   端口=%s\n' "$label" "$port"
    fi
}

status() {
    printf '%s\n' 'Archiva Music 开发环境状态'
    print_service_status '后端' "$BACKEND_PID_FILE" "$BACKEND_PORT" 'swingmusic|archiva-music'
    print_service_status '前端' "$FRONTEND_PID_FILE" "$FRONTEND_PORT" 'vite|yarn.*dev'
    printf '%s\n' "开发地址：http://127.0.0.1:$FRONTEND_PORT"
    printf '%s\n' "后端地址：http://127.0.0.1:$BACKEND_PORT"
}

ensure_dependencies() {
    local missing=0
    for command_name in uv yarn lsof; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            printf '缺少命令：%s\n' "$command_name" >&2
            missing=1
        fi
    done
    return "$missing"
}

ensure_client_build() {
    if [[ ! -f "$CLIENT_DIST_DIR/index.html" ]]; then
        printf '%s\n' '未找到 client/dist，先构建前端生产文件供后端加载……'
        (cd "$CLIENT_DIR" && yarn build) || return 1
    fi
}

start_backend() {
    local pid
    pid="$(pid_from_file "$BACKEND_PID_FILE")"

    if [[ -n "$pid" ]] && pid_matches "$pid" 'swingmusic|archiva-music'; then
        printf '%s\n' '后端已经在运行。'
        return 0
    fi

    if [[ -n "$(port_pid "$BACKEND_PORT")" ]]; then
        printf '后端端口 %s 已被其它程序占用，未启动。\n' "$BACKEND_PORT" >&2
        return 1
    fi

    ensure_client_build || return 1
    : > "$BACKEND_LOG"
    (
        cd "$ROOT_DIR" || exit 1
        nohup uv run python -m swingmusic \
            --host 127.0.0.1 \
            --port "$BACKEND_PORT" \
            --debug \
            --config "$DEV_DATA_DIR" \
            --client "$CLIENT_DIST_DIR" \
            >> "$BACKEND_LOG" 2>&1 < /dev/null &
        printf '%s\n' "$!" > "$BACKEND_PID_FILE"
    )
    printf '后端已启动，日志：%s\n' "$BACKEND_LOG"
}

start_frontend() {
    local pid
    pid="$(pid_from_file "$FRONTEND_PID_FILE")"

    if [[ -n "$pid" ]] && pid_matches "$pid" 'vite|yarn.*dev'; then
        printf '%s\n' '前端已经在运行。'
        return 0
    fi

    if [[ -n "$(port_pid "$FRONTEND_PORT")" ]]; then
        printf '前端端口 %s 已被其它程序占用，未启动。\n' "$FRONTEND_PORT" >&2
        return 1
    fi

    : > "$FRONTEND_LOG"
    (
        cd "$CLIENT_DIR" || exit 1
        nohup yarn dev --host 127.0.0.1 --port "$FRONTEND_PORT" \
            >> "$FRONTEND_LOG" 2>&1 < /dev/null &
        printf '%s\n' "$!" > "$FRONTEND_PID_FILE"
    )
    printf '前端已启动，日志：%s\n' "$FRONTEND_LOG"
}

start() {
    ensure_dependencies || return 1
    case "${1:-all}" in
        all)
            start_backend && start_frontend
            ;;
        backend)
            start_backend
            ;;
        frontend)
            start_frontend
            ;;
        *)
            usage
            return 1
            ;;
    esac
}

stop_service() {
    local label="$1"
    local pid_file="$2"
    local pattern="$3"
    local pid
    pid="$(pid_from_file "$pid_file")"

    if [[ -z "$pid" ]]; then
        printf '%s\n' "$label 未运行。"
        return 0
    fi

    if ! pid_matches "$pid" "$pattern"; then
        printf '%s\n' "$label 的 PID 文件已失效，未终止其它进程。"
        return 0
    fi

    kill "$pid" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
        if ! is_running "$pid"; then
            break
        fi
        sleep 1
    done

    if is_running "$pid"; then
        printf '%s 未能在 5 秒内退出，请查看日志：%s\n' "$label" "$RUNTIME_DIR" >&2
        return 1
    fi

    rm -f "$pid_file"
    printf '%s 已停止。\n' "$label"
}

stop() {
    case "${1:-all}" in
        all)
            stop_service '后端' "$BACKEND_PID_FILE" 'swingmusic|archiva-music'
            stop_service '前端' "$FRONTEND_PID_FILE" 'vite|yarn.*dev'
            ;;
        backend)
            stop_service '后端' "$BACKEND_PID_FILE" 'swingmusic|archiva-music'
            ;;
        frontend)
            stop_service '前端' "$FRONTEND_PID_FILE" 'vite|yarn.*dev'
            ;;
        *)
            usage
            return 1
            ;;
    esac
}

logs() {
    case "${1:-all}" in
        backend)
            tail -n 80 -f "$BACKEND_LOG"
            ;;
        frontend)
            tail -n 80 -f "$FRONTEND_LOG"
            ;;
        all)
            printf '%s\n' '--- backend.log ---'
            tail -n 40 "$BACKEND_LOG" 2>/dev/null || true
            printf '%s\n' '--- frontend.log ---'
            tail -n 40 "$FRONTEND_LOG" 2>/dev/null || true
            ;;
        *)
            usage
            return 1
            ;;
    esac
}

menu() {
    while true; do
        printf '\n'
        status
        printf '\n%s\n' '[s]启动  [t]停止  [r]重启  [l]查看日志  [q]退出'
        read -r -p '请选择：' choice
        case "$choice" in
            s|start)
                start
                ;;
            t|stop)
                stop
                ;;
            r|restart)
                stop
                start
                ;;
            l|logs)
                logs all
                ;;
            q|quit|exit)
                break
                ;;
            *)
                printf '%s\n' '请输入 s、t、r、l 或 q。'
                ;;
        esac
    done
}

usage() {
    cat <<'EOF'
用法：
  ./scripts/archiva-dev.sh              进入交互式管理菜单
  ./scripts/archiva-dev.sh status       查看后端和前端状态
  ./scripts/archiva-dev.sh start        启动前后端
  ./scripts/archiva-dev.sh stop         停止前后端
  ./scripts/archiva-dev.sh restart      重启前后端
  ./scripts/archiva-dev.sh logs         查看最近日志

也可以只操作一端：
  start|stop|restart backend|frontend
  logs backend|frontend
EOF
}

case "${1:-menu}" in
    status)
        status
        ;;
    start|on)
        start "${2:-all}"
        ;;
    stop|off)
        stop "${2:-all}"
        ;;
    restart)
        stop "${2:-all}" && start "${2:-all}"
        ;;
    logs)
        logs "${2:-all}"
        ;;
    menu)
        menu
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
