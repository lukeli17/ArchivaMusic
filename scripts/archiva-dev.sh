#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"
DEV_DATA_DIR="$ROOT_DIR/.dev-data"
CLIENT_DIR="$ROOT_DIR/client"
CLIENT_DIST_DIR="$CLIENT_DIR/dist"

# 浏览器只打开前端端口 7019，后端 7018 由前端在后台调用。
BACKEND_PORT=7018
FRONTEND_PORT=7019

BACKEND_PID_FILE="$RUNTIME_DIR/backend.pid"
FRONTEND_PID_FILE="$RUNTIME_DIR/frontend.pid"
BACKEND_LOG="$RUNTIME_DIR/backend.log"
FRONTEND_LOG="$RUNTIME_DIR/frontend.log"

mkdir -p "$RUNTIME_DIR"

pid_from_file() {
    local file="$1"
    [[ -f "$file" ]] && sed -n '1p' "$file"
}

port_pid() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | head -n 1
}

running() {
    [[ -n "$1" ]] && kill -0 "$1" 2>/dev/null
}

matches() {
    local pid="$1"
    local pattern="$2"
    running "$pid" && ps -p "$pid" -o command= 2>/dev/null | grep -E "$pattern" >/dev/null 2>&1
}

backend_running() {
    matches "$(pid_from_file "$BACKEND_PID_FILE")" 'swingmusic|archiva-music'
}

frontend_running() {
    matches "$(pid_from_file "$FRONTEND_PID_FILE")" 'vite|yarn.*dev'
}

lan_ip() {
    local ip=""
    ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
    [[ -z "$ip" ]] && ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
    printf '%s' "$ip"
}

show_status() {
    local backend_pid="$(pid_from_file "$BACKEND_PID_FILE")"
    local frontend_pid="$(pid_from_file "$FRONTEND_PID_FILE")"
    local lan_address="$(lan_ip)"

    printf '\n%s\n' 'Archiva Music 开发控制台'
    if backend_running && frontend_running; then
        printf '%s\n' '状态：运行中 · 本控制台管理'
        printf '进程：后端 PID %s · 前端 PID %s\n' "$backend_pid" "$frontend_pid"
    elif [[ -n "$(port_pid "$BACKEND_PORT")" || -n "$(port_pid "$FRONTEND_PORT")" ]]; then
        printf '%s\n' '状态：部分运行或端口被占用'
    else
        printf '%s\n' '状态：已停止'
    fi
    printf '本机地址：http://127.0.0.1:%s\n' "$FRONTEND_PORT"
    if [[ -n "$lan_address" ]]; then
        printf '局域网地址：http://%s:%s\n' "$lan_address" "$FRONTEND_PORT"
    else
        printf '%s\n' '局域网地址：未检测到局域网 IP'
    fi
    printf '\n'
}

check_dependencies() {
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
        printf '%s\n' '未找到前端构建文件，正在构建……'
        (cd "$CLIENT_DIR" && yarn build) || return 1
    fi
}

start_backend() {
    if backend_running; then
        return 0
    fi
    if [[ -n "$(port_pid "$BACKEND_PORT")" ]]; then
        printf '后端端口 %s 已被占用。\n' "$BACKEND_PORT" >&2
        return 1
    fi

    ensure_client_build || return 1
    : > "$BACKEND_LOG"
    (
        cd "$ROOT_DIR" || exit 1
        nohup uv run python -m swingmusic \
            --host 0.0.0.0 --port "$BACKEND_PORT" --debug \
            --config "$DEV_DATA_DIR" --client "$CLIENT_DIST_DIR" \
            >> "$BACKEND_LOG" 2>&1 < /dev/null &
        printf '%s\n' "$!" > "$BACKEND_PID_FILE"
    )
}

start_frontend() {
    if frontend_running; then
        return 0
    fi
    if [[ -n "$(port_pid "$FRONTEND_PORT")" ]]; then
        printf '前端端口 %s 已被占用。\n' "$FRONTEND_PORT" >&2
        return 1
    fi

    : > "$FRONTEND_LOG"
    (
        cd "$CLIENT_DIR" || exit 1
        nohup yarn dev --host 0.0.0.0 --port "$FRONTEND_PORT" \
            >> "$FRONTEND_LOG" 2>&1 < /dev/null &
        printf '%s\n' "$!" > "$FRONTEND_PID_FILE"
    )
}

start_program() {
    check_dependencies || return 1
    printf '%s\n' '正在启动服务……'
    if start_backend && start_frontend; then
        sleep 1
        if backend_running && frontend_running; then
            printf '%s\n' '状态：运行中'
            return 0
        fi
    fi
    printf '%s\n' '状态：启动失败，请查看日志。' >&2
    return 1
}

stop_one() {
    local name="$1"
    local pid_file="$2"
    local pattern="$3"
    local pid="$(pid_from_file "$pid_file")"

    if ! matches "$pid" "$pattern"; then
        rm -f "$pid_file"
        return 0
    fi

    terminate_tree() {
        local parent="$1"
        local child
        for child in $(ps -axo pid=,ppid= | awk -v parent="$parent" '$2 == parent {print $1}'); do
            terminate_tree "$child"
        done
        kill "$parent" 2>/dev/null || true
    }

    terminate_tree "$pid"
    for _ in 1 2 3 4 5; do
        running "$pid" || break
        sleep 1
    done

    if running "$pid"; then
        printf '%s 未能退出，请查看 .dev-runtime 日志。\n' "$name" >&2
        return 1
    fi

    rm -f "$pid_file"
    return 0
}

stop_program() {
    printf '%s\n' '正在停止服务……'
    stop_one '后端' "$BACKEND_PID_FILE" 'swingmusic|archiva-music'
    stop_one '前端' "$FRONTEND_PID_FILE" 'vite|yarn.*dev'
    printf '%s\n' '状态：已停止'
}

restart_program() {
    stop_program
    start_program
}

open_browser() {
    printf '正在打开浏览器：http://127.0.0.1:%s\n' "$FRONTEND_PORT"
    open "http://127.0.0.1:$FRONTEND_PORT"
}

show_logs() {
    printf '%s\n' '--- 后端日志（最近 30 行）---'
    tail -n 30 "$BACKEND_LOG" 2>/dev/null || true
    printf '%s\n' '--- 前端日志（最近 30 行）---'
    tail -n 30 "$FRONTEND_LOG" 2>/dev/null || true
}

show_menu() {
    printf '%s\n' \
        '请选择操作：' \
        '  [1] 查看状态' \
        '  [2] 启动程序' \
        '  [3] 停止程序' \
        '  [4] 重启程序' \
        '  [5] 打开浏览器' \
        '  [6] 查看日志' \
        '  [7] 清理屏幕' \
        '  [8] 显示菜单' \
        '  [0] 退出控制台'
}

pause_console() {
    read -r -p '按回车继续……' _
}

menu() {
    # 双击打开时，如果服务未运行，默认自动启动。
    if ! backend_running || ! frontend_running; then
        if start_program; then
            open_browser
        fi
        pause_console
    fi

    while true; do
        show_status
        show_menu
        read -r -p '请输入数字 [0-8]：' choice || break
        printf '\n'
        case "$choice" in
            1)
                show_status
                pause_console
                ;;
            2)
                start_program
                pause_console
                ;;
            3)
                stop_program
                pause_console
                ;;
            4)
                restart_program
                pause_console
                ;;
            5)
                open_browser
                pause_console
                ;;
            6)
                show_logs
                pause_console
                ;;
            7)
                clear
                ;;
            8)
                show_menu
                pause_console
                ;;
            0)
                break
                ;;
            *)
                printf '%s\n' '输入无效，请输入 0-8。'
                pause_console
                ;;
        esac
    done
}

usage() {
    printf '%s\n' \
        '用法：' \
        '  ./scripts/archiva-dev.sh       进入管理菜单' \
        '  ./scripts/archiva-dev.sh start 启动程序' \
        '  ./scripts/archiva-dev.sh stop  停止程序' \
        '  ./scripts/archiva-dev.sh restart 重启程序' \
        '  ./scripts/archiva-dev.sh status 查看状态' \
        '  ./scripts/archiva-dev.sh logs   查看日志'
}

case "${1:-menu}" in
    menu) menu ;;
    status) show_status ;;
    start|on) start_program ;;
    stop|off) stop_program ;;
    restart) restart_program ;;
    logs) show_logs ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
esac
