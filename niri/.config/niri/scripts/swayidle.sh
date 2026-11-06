#!/usr/bin/env bash

# ============================================================================
# Swayidle 空闲策略 —— 统一用 quickshell 锁屏（qs-lock）
# ============================================================================
# 时间线（都从上一次输入算起，不是逐条叠加）：
#   180s 锁屏（grace 30s → 210s 真锁）→ 300s 关屏 → 600s 自动挂起
#
# 三个不能改的地方：
# 1. 不加 -w。它 waitpid 等命令退出，而 qs-lock 末行 exec quickshell 是常驻的，
#    真起锁屏后 swayidle 会卡到解锁为止（所有 timeout 停摆，before-sleep 和
#    lock 都收不到）。睡前锁屏靠 logind 的 InhibitDelayMaxSec（默认 5s）兜底。
# 2. `resume` 修饰的是紧邻的前一条 `timeout`，不是全局事件。必须
#    `timeout DPMS` → `resume` → `timeout SUSPEND`；顺序颠倒则「关屏后回来」不亮屏。
# 3. `\` 续行后面不能跟 `#` 注释行，否则注释被拼进命令、整段参数被吃掉
#    （历史版本因此从未生效）。命令收进变量，注释只写在上面。
# ============================================================================

IDLE_TIMEOUT=180       # 多久后启动锁屏
GRACE_DURATION=30      # grace period 时长（由锁屏组件自己倒计时）
DPMS_TIMEOUT=300       # 多久后关闭显示器
SUSPEND_TIMEOUT=600    # 多久后自动挂起

# 那行 pgrep 是防抖：swayidle 的每个 timeout 都会独立执行，
# 不加判断的话每触发一次就多起一个 quickshell 进程。
LOCK_CMD="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=${GRACE_DURATION} qs-lock"
# logind 的 lock 事件用这条：匹配手动锁屏的 3 秒宽限
LOCK_CMD_UI="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=3 qs-lock"
# 睡前锁屏无宽限
LOCK_CMD_IMMEDIATE="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=0 qs-lock"
WAKE_CMD="niri msg action power-on-monitors; qs-lock --face"

exec swayidle \
    timeout "$IDLE_TIMEOUT"    "$LOCK_CMD" \
    timeout "$DPMS_TIMEOUT"    'niri msg action power-off-monitors' \
        resume                 "$WAKE_CMD" \
    timeout "$SUSPEND_TIMEOUT" 'systemctl suspend' \
    before-sleep               "$LOCK_CMD_IMMEDIATE" \
    after-resume               "$WAKE_CMD" \
    lock                       "$LOCK_CMD_UI"
