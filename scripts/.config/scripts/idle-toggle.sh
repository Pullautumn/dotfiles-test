#!/usr/bin/env bash
# ============================================================================
# 空闲策略开关 —— 保持唤醒 / 恢复休眠
# ============================================================================
# 只做一件事：维护 $XDG_RUNTIME_DIR/idle-paused 这个标记文件。
#   - 标记不存在 → niri/scripts/swayidle.sh 正常按 180/300/600 秒锁屏 / 熄屏 / 挂起
#   - 标记存在   → 那三条 timeout 全部空转，屏幕常亮
#
# 读标记的是 swayidle.sh 里的 gate()，本脚本**不重启 swayidle、不碰 systemd**。
# 旧版本走的是 `systemctl --user start/stop swayidle.service`，而那个 unit 根本
# 不存在（swayidle 是 niri autostart 里 spawn 出来的裸进程），于是出现最坏的
# 那种坏法：按钮变成 ☕「已禁用」，锁屏照旧生效。
#
# 标记为什么放 $XDG_RUNTIME_DIR 而不是 /tmp：它是 tmpfs，注销即消失，
# 不会像 /tmp/swayidle-disabled 那样跨重启残留、把新会话的锁屏莫名关掉。
#
# 用法：
#   idle-toggle.sh status   waybar JSON（默认，被 modules.jsonc 的 exec 调用）
#   idle-toggle.sh toggle   切换
#   idle-toggle.sh pause    保持唤醒
#   idle-toggle.sh resume   恢复休眠
#
# 注意：点按钮本身就是一次输入事件，swayidle 的空闲计时会从这一刻重新开始，
# 所以「已空闲 500 秒时恢复休眠」不会立刻熄屏，而是重新等满 300 秒。
# ============================================================================

set -u

FLAG="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-paused"
WAYBAR_SIG=7          # 与 waybar/modules.jsonc 里 "signal": 7 对应

# tooltip 里的 \n 是给 JSON 用的转义（printf 的 %s 不解释反斜杠，
# 写的是两个字面字符，waybar 解析 JSON 时才变成换行）。
json() {
    if [[ -e "$FLAG" ]]; then
        printf '{"text":"☕","class":"paused","tooltip":"保持唤醒：不锁屏 / 不熄屏 / 不挂起\\n左键：恢复休眠　右键：立即锁屏"}'
    else
        printf '{"text":"💤","class":"active","tooltip":"允许休眠：3 分钟锁屏 · 5 分钟熄屏 · 10 分钟挂起\\n左键：保持唤醒　右键：立即锁屏"}'
    fi
}

refresh() {
    # 立刻让 waybar 重跑 status；module 的 interval 30 只是兜底轮询。
    # waybar 只对自己 config 里声明过的 signal 建处理器，撞号也无副作用。
    pkill -RTMIN+"$WAYBAR_SIG" -x waybar 2>/dev/null || true
}

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "空闲策略" -t 2500 "$1" "$2"
    return 0
}

pause() {
    : >"$FLAG"
    niri msg action power-on-monitors >/dev/null 2>&1 || true
    notify "☕ 保持唤醒" "不会自动锁屏 / 熄屏 / 挂起"
}

resume() {
    rm -f "$FLAG"
    notify "💤 已恢复休眠" "3 分钟锁屏 · 5 分钟熄屏 · 10 分钟挂起"
}

case "${1:-status}" in
    status)
        json
        ;;
    toggle)
        if [[ -e "$FLAG" ]]; then resume; else pause; fi
        json
        refresh
        ;;
    pause)
        pause
        json
        refresh
        ;;
    resume)
        resume
        json
        refresh
        ;;
    *)
        printf '用法: %s {status|toggle|pause|resume}\n' "${0##*/}" >&2
        exit 2
        ;;
esac
