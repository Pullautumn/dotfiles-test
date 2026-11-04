#!/usr/bin/env bash
# ==============================================================================
# switch-waybar.sh —— 三套状态栏互切，并同步切换各自依赖的后台服务
#
#   main        waybar（主样式，Win11 风格）        + swaync
#   win11       waybar-niri-Win11Like（备选样式）   + swaync
#   quickshell  waybar-quickshell（Quickshell 风格） + qs-notifications.service
#
# 为什么必须一起切：swaync 和 Quickshell 自带的通知守护进程都要抢占 D-Bus 上
# 唯一的 org.freedesktop.Notifications，同时只能有一个在跑。剪贴板不用切，
# Quickshell 的 clipboard 组件读的就是同一个 cliphist 数据库。
#
# 用法:
#   switch-waybar.sh main|win11|quickshell   切到指定样式
#   switch-waybar.sh next                    按 main → win11 → quickshell 循环
#   switch-waybar.sh restart                 重启当前样式（waybar 右键用）
#   switch-waybar.sh status                  打印当前样式与后台状态
#
# 另外三个动作让快捷键不用关心当前是哪套样式：
#   notifications  通知面板（swaync 面板 / Quickshell 通知中心）
#   launcher       应用启动器（fuzzel / Quickshell launcher）
#   clipboard      剪贴板（cliphist-fuzzel-img / Quickshell clipboard）
# ==============================================================================

set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$STATE_DIR/waybar-style"
QS_CONFIG_DIR="$CONFIG_DIR/quickshell"

ORDER=(main win11 quickshell)

declare -A BAR_CONFIG=(
    [main]="$CONFIG_DIR/waybar/config.jsonc"
    [win11]="$CONFIG_DIR/waybar-niri-Win11Like/config.jsonc"
    [quickshell]="$CONFIG_DIR/waybar-quickshell/config.jsonc"
)

declare -A BAR_STYLE=(
    [main]="$CONFIG_DIR/waybar/style.css"
    [win11]="$CONFIG_DIR/waybar-niri-Win11Like/style.css"
    [quickshell]="$CONFIG_DIR/waybar-quickshell/style.css"
)

say() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "switch-waybar" "状态栏" "$1" >/dev/null 2>&1
    printf '%s\n' "$1"
}

# ------------------------------------------------------------------------------
# 当前样式：先看实际在跑的 waybar（开机自启的是裸 waybar，即主样式），
# 查不到进程时才退回状态文件
# ------------------------------------------------------------------------------
current_style() {
    local pid args
    for pid in $(pgrep -x waybar 2>/dev/null); do
        args=$(ps -o args= -p "$pid" 2>/dev/null) || continue
        case "$args" in
            *waybar-quickshell/config.jsonc*)     printf 'quickshell\n'; return 0 ;;
            *waybar-niri-Win11Like/config.jsonc*) printf 'win11\n';      return 0 ;;
            # 开机自启的是裸 waybar，走默认配置，即主样式
            *)                                    printf 'main\n';       return 0 ;;
        esac
    done

    if [[ -s "$STATE_FILE" ]]; then
        local saved
        saved=$(cat "$STATE_FILE" 2>/dev/null)
        if [[ -n "${BAR_CONFIG[$saved]:-}" ]]; then
            printf '%s\n' "$saved"
            return 0
        fi
    fi

    printf 'main\n'
}

# ------------------------------------------------------------------------------
# 关掉 waybar：先 SIGTERM，等它自己退，超时才 -9
# 原来直接 pkill 后立刻拉起新实例，旧进程还没释放图层，会出现两条状态栏叠着
# ------------------------------------------------------------------------------
stop_bar() {
    pkill -x waybar 2>/dev/null || true
    local i
    for i in $(seq 1 30); do
        if ! pgrep -x waybar >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
    done
    pkill -9 -x waybar 2>/dev/null || true
    sleep 0.1
}

# 残留的 Quickshell 弹窗面板（切换样式后它们不应该继续挂在屏幕上）
stop_quickshell_popups() {
    pkill -x quickshell 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 后台：swaync
# ------------------------------------------------------------------------------
backend_swaync() {
    systemctl --user stop qs-notifications.service >/dev/null 2>&1 || true
    pkill -f 'notifications/main.py' 2>/dev/null || true

    if ! pgrep -x swaync >/dev/null 2>&1; then
        setsid -f swaync >/dev/null 2>&1 || true
        sleep 0.3
    fi
}

# ------------------------------------------------------------------------------
# 后台：Quickshell 通知守护进程（替代 swaync）
# 优先用 systemd 单元；单元没装就前台拉一个后台进程兜底
# ------------------------------------------------------------------------------
backend_quickshell() {
    pkill -x swaync 2>/dev/null || true

    if systemctl --user cat qs-notifications.service >/dev/null 2>&1; then
        systemctl --user restart qs-notifications.service >/dev/null 2>&1 || true
        return 0
    fi

    if ! pgrep -f 'notifications/main.py' >/dev/null 2>&1; then
        if [[ -d "$QS_CONFIG_DIR" ]] && command -v uv >/dev/null 2>&1; then
            ( cd "$QS_CONFIG_DIR" && setsid -f uv run python -u notifications/main.py >/dev/null 2>&1 ) || true
        else
            say "Quickshell 未就绪：缺 $QS_CONFIG_DIR 或 uv，通知可能没有守护进程"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 切换
# ------------------------------------------------------------------------------
switch_to() {
    local style="$1"

    if [[ -z "${BAR_CONFIG[$style]:-}" ]]; then
        printf 'unknown style: %s\n' "$style" >&2
        exit 2
    fi

    if [[ ! -f "${BAR_CONFIG[$style]}" ]]; then
        say "配置不存在：${BAR_CONFIG[$style]}"
        exit 1
    fi

    stop_bar
    stop_quickshell_popups

    case "$style" in
        quickshell) backend_quickshell ;;
        *)          backend_swaync ;;
    esac

    setsid -f waybar -c "${BAR_CONFIG[$style]}" -s "${BAR_STYLE[$style]}" >/dev/null 2>&1

    mkdir -p "$STATE_DIR"
    printf '%s\n' "$style" > "$STATE_FILE"

    say "已切换到 $style"
}

# ------------------------------------------------------------------------------
# 按当前样式分发的三个常用动作
# ------------------------------------------------------------------------------
BAR_DIR="$CONFIG_DIR/waybar"

act_notifications() {
    if [[ "$(current_style)" == "quickshell" ]]; then
        exec "$HOME/.local/bin/qs-popup" notifications
    fi
    exec swaync-client -t
}

act_launcher() {
    if [[ "$(current_style)" == "quickshell" ]]; then
        exec "$HOME/.local/bin/qs-popup" launcher
    fi
    exec fuzzel
}

act_clipboard() {
    if [[ "$(current_style)" == "quickshell" ]]; then
        exec "$HOME/.local/bin/qs-popup" clipboard
    fi
    pkill rofi 2>/dev/null || true
    exec "$BAR_DIR/scripts/cliphist-fuzzel-img"
}

case "${1:-}" in
    main|win11|quickshell)
        switch_to "$1"
        ;;
    next)
        cur=$(current_style)
        for i in "${!ORDER[@]}"; do
            if [[ "${ORDER[$i]}" == "$cur" ]]; then
                switch_to "${ORDER[$(( (i + 1) % ${#ORDER[@]} ))]}"
                exit 0
            fi
        done
        switch_to "${ORDER[0]}"
        ;;
    restart)
        switch_to "$(current_style)"
        ;;
    notifications)
        act_notifications
        ;;
    launcher)
        act_launcher
        ;;
    clipboard)
        act_clipboard
        ;;
    status)
        cur=$(current_style)
        printf '样式: %s\n' "$cur"
        if pgrep -x waybar >/dev/null 2>&1; then
            printf 'waybar: 运行中\n'
        else
            printf 'waybar: 未运行\n'
        fi
        if pgrep -x swaync >/dev/null 2>&1; then
            printf 'swaync: 运行中\n'
        else
            printf 'swaync: 未运行\n'
        fi
        if systemctl --user is-active --quiet qs-notifications.service 2>/dev/null; then
            printf 'qs-notifications: 运行中\n'
        elif pgrep -f 'notifications/main.py' >/dev/null 2>&1; then
            printf 'qs-notifications: 运行中 (无 systemd 单元)\n'
        else
            printf 'qs-notifications: 未运行\n'
        fi
        ;;
    ""|-h|--help|help)
        sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        printf 'unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
esac
