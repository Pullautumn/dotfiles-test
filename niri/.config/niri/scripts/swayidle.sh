#!/usr/bin/env bash

# ============================================================================
# Swayidle 空闲策略 —— 统一用 quickshell 锁屏（qs-lock）
# ============================================================================
# 时间线（沿用本项目原有的数值，不是上游的 45/120/300）：
#
#   300s 无操作           → 锁屏（qs-lock，带 30s grace period）
#   330s 无操作           → 关闭显示器
#   有输入（resume）      → 点亮屏幕
#   合盖 / 休眠前         → 立刻锁屏（grace 0，不给自己留取消窗口）
#   唤醒后（after-resume）→ 点亮屏幕 + 触发人脸识别（没装 howdy 就只亮屏）
#
# grace period 用上游 jswysnemc 的 30 秒：锁屏后 30 秒内动鼠标可以取消，
# 超时才进真锁屏。手动锁屏（Mod+Alt+L / 状态栏 / 电源菜单）用 3 秒，见 binds.kdl。
#
# ⚠️ 血泪教训：swayidle 的每条 timeout 都是一个独立参数，`\` 续行后面
#    绝对不能再跟 `#` 注释行 —— 续行会把注释拼进同一条命令，于是
#    `exec swayidle -w` 之后的内容全被当成注释吃掉，整个空闲策略静默失效。
#    历史版本就是这么写的（`exec swayidle -w \` 后紧跟 `# 5分钟锁屏...`），
#    结果 5 分钟锁屏从来没生效过。所以这里把命令全收进变量，注释只写在上面。
# ============================================================================

IDLE_TIMEOUT=300       # 多久后启动锁屏
GRACE_DURATION=30      # grace period 时长（由锁屏组件自己倒计时）
DPMS_TIMEOUT=330       # 多久后关闭显示器

# 那行 pgrep 是防抖：swayidle 的每个 timeout 都会独立执行，
# 不加判断的话每触发一次就多起一个 quickshell 进程。
LOCK_CMD="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=${GRACE_DURATION} qs-lock"
LOCK_CMD_IMMEDIATE="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=0 qs-lock"
WAKE_CMD="niri msg action power-on-monitors; qs-lock --face"

exec swayidle -w \
    timeout "$IDLE_TIMEOUT" "$LOCK_CMD" \
    timeout "$DPMS_TIMEOUT" 'niri msg action power-off-monitors' \
    resume 'niri msg action power-on-monitors' \
    before-sleep "$LOCK_CMD_IMMEDIATE" \
    after-resume "$WAKE_CMD"
