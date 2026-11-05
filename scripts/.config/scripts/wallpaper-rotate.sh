#!/usr/bin/env bash
# ==============================================================================
# wallpaper-rotate.sh —— 开机「自动随机换壁纸」的开关
#
# 状态文件: ${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-auto-rotate
#   内容只有 on / off。文件不存在按 on 处理，保持老行为不变。
#
# 用法:
#   wallpaper-rotate.sh boot        开机入口，由 niri 的 autostart 调用
#   wallpaper-rotate.sh on|off      设置状态
#   wallpaper-rotate.sh toggle      翻转（Mod+Ctrl+F10）
#   wallpaper-rotate.sh status      打印当前状态
#
# 两个状态到底差在哪（这是本脚本存在的唯一理由）:
#
#   on  → waypaper --random
#         换一张新图，然后跑 waypaper 的 post_command：
#         matugen-update.sh 重算全套配色 + niri_set_overview_blur_dark_bg.sh 重算总览模糊。
#         一次开机三件事全跑。
#
#   off → awww restore
#         只让 awww-daemon 把「上次画的那张」贴回屏幕。不经过 waypaper，
#         所以不换图、不换色、不重算模糊，开机零计算。
#
# 为什么 off 不能真的什么都不做:
#   awww-daemon 每次开机是空白状态，它不记得上次画的是哪张图。一条命令都不
#   执行的结果是黑屏。awww restore 读的是 daemon 自己 ~/.cache/awww/ 里的
#   缓存，不触发 matugen、不触发模糊脚本，这就是「不动」能做到的极限。
#
# 为什么绝对不许用 waypaper --restore:
#   它名字叫 restore，但 waypaper 不管 --random 还是 --restore 都会跑
#   config.ini 里的 post_command，等于照样换色、照样重算模糊，那就不叫不动了。
#   本脚本的 off 分支刻意绕开 waypaper，原因就在这里。
# ==============================================================================

set -u

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-auto-rotate"

# matugen-update.sh 每次换图都会维护这个软链，指向上一次真正设置的那张图。
CURRENT_LINK="$HOME/.cache/current_wallpaper"

# ------------------------------------------------------------------------------
# 通知：有 notify-send 就弹一条，同时打到 stdout（终端里手动跑时能看见）
# ------------------------------------------------------------------------------
notify() {
    command -v notify-send >/dev/null 2>&1 \
        && notify-send -a "wallpaper-rotate" "自动换壁纸" "$1" >/dev/null 2>&1
    printf '%s\n' "$1"
}

# ------------------------------------------------------------------------------
# 读状态：文件缺失 / 内容乱写 / 读不了，一律当 on（保持现状，不能让升级变行为）
# ------------------------------------------------------------------------------
current_state() {
    local s=""
    [[ -s "$STATE_FILE" ]] && s=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null)

    case "$s" in
        off) printf 'off\n' ;;
        *)   printf 'on\n'  ;;
    esac
}

set_state() {
    local new="$1"

    mkdir -p "$(dirname "$STATE_FILE")"
    printf '%s\n' "$new" > "$STATE_FILE"

    if [[ "$new" == "off" ]]; then
        notify "已关闭：开机不再换图（当前这张保持不动）"
    else
        notify "已开启：开机自动随机换一张"
    fi
}

# ------------------------------------------------------------------------------
# 不动模式：把上次那张贴回屏幕，全程不碰 matugen
#
# 三级兜底，任何一级成功就返回 0：
#   1. awww restore      daemon 自己的缓存，零解析、最干净
#   2. ~/.cache/current_wallpaper   daemon 缓存被清过时用这个软链
#   3. waypaper config.ini 的 wallpaper  只取值，不调 waypaper，所以不会触发 post_command
# ------------------------------------------------------------------------------
try_awww_img() {
    local wp="$1"
    [[ -n "$wp" && -f "$wp" ]] || return 1
    command -v awww >/dev/null 2>&1 || return 1
    awww img "$wp" --transition-type none >/dev/null 2>&1
}

restore_current() {
    command -v awww >/dev/null 2>&1 || return 1

    # 先等 daemon 的 socket 就绪（autostart 里已有 sleep 1，这里只是保险），最多 3 秒。
    # 用 query 探活、而不是拿 restore 去试：这样即使这个版本的 awww 没有 restore
    # 子命令，也只会失败一次就往下走，不会傻等 6 轮共 3 秒。
    local i
    for i in 1 2 3 4 5 6; do
        awww query >/dev/null 2>&1 && break
        sleep 0.5
    done

    # 1. daemon 自己的缓存，零解析、最干净
    awww restore >/dev/null 2>&1 && return 0

    # 2. 软链兜底
    local wp=""
    if [[ -L "$CURRENT_LINK" || -e "$CURRENT_LINK" ]]; then
        wp=$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)
        try_awww_img "$wp" && return 0
    fi

    # 3. config.ini 兜底
    local cfg="$HOME/.config/waypaper/config.ini"
    if [[ -f "$cfg" ]]; then
        wp=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n1)
        wp="${wp/#\~/$HOME}"
        try_awww_img "$wp" && return 0
    fi

    # 三条都失败说明 daemon 没在跑或者缓存全没了，桌面会黑，至少别让人莫名其妙
    notify "取不到上次的壁纸，桌面可能是黑的（检查 awww-daemon 是否在跑）"
    return 1
}

# ------------------------------------------------------------------------------
# 开机入口
# ------------------------------------------------------------------------------
do_boot() {
    if [[ "$(current_state)" == "off" ]]; then
        restore_current
        exit $?
    fi

    # on：完全保持原行为
    exec waypaper --random
}

case "${1:-}" in
    boot)
        do_boot
        ;;
    on|off)
        set_state "$1"
        ;;
    toggle)
        if [[ "$(current_state)" == "on" ]]; then
            set_state off
        else
            set_state on
        fi
        ;;
    status)
        printf '自动换壁纸: %s\n' "$(current_state)"
        printf '状态文件:   %s\n' "$STATE_FILE"
        ;;
    ""|-h|--help|help)
        sed -n '2,/^# =\{10,\}/p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        printf 'unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
esac
