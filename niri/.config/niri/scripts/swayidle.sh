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
#
# 保持唤醒（waybar 的 ☕ 按钮 / idle-toggle.sh）：
#   $XDG_RUNTIME_DIR/idle-paused 存在时，三条 timeout 全部空转。
#   手动锁屏 Mod+Alt+L 走 logind 的 `lock` 事件，**故意不套 gate** —— 要求是
#   「保持唤醒也能手动锁屏」。`before-sleep` 同理不套：手动挂起 / 合盖回来后
#   仍然要密码，否则中午合盖放桌上等于给所有人开门。
# ============================================================================

IDLE_TIMEOUT=180       # 多久后启动锁屏
GRACE_DURATION=30      # grace period 时长（由锁屏组件自己倒计时）
DPMS_TIMEOUT=300       # 多久后关闭显示器
SUSPEND_TIMEOUT=600    # 多久后自动挂起

# 与 scripts/idle-toggle.sh 里的 FLAG 必须是同一个路径
PAUSE_FLAG="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-paused"

# 给命令套一层「没暂停才执行」。swayidle 把整串交给 sh -c 跑，所以这里拼的是
# shell 片段；**不能**用 printf %q 转义，那会把整条命令压成一个单词，
# sh 会去找一个名叫 "pgrep -x quickshell | ..." 的可执行文件。
gate() { printf 'test ! -e %s && { %s; }' "$PAUSE_FLAG" "$1"; }

# 那行 pgrep 是防抖：swayidle 的每个 timeout 都会独立执行，
# 不加判断的话每触发一次就多起一个 quickshell 进程。
LOCK_CMD="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=${GRACE_DURATION} qs-lock"
# logind 的 lock 事件用这条：匹配手动锁屏的 3 秒宽限
LOCK_CMD_UI="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=3 qs-lock"
# 睡前锁屏无宽限
LOCK_CMD_IMMEDIATE="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=0 qs-lock"
# 亮屏照做（暂停时屏幕本来就没关过，这里的 power-on 只是幂等兜底）；
# 锁屏那半句套 gate，避免「保持唤醒」下从手动挂起回来被弹一脸密码框。
WAKE_CMD="niri msg action power-on-monitors; test -e ${PAUSE_FLAG} || qs-lock --face"

exec swayidle \
    timeout "$IDLE_TIMEOUT"    "$(gate "$LOCK_CMD")" \
    timeout "$DPMS_TIMEOUT"    "$(gate 'niri msg action power-off-monitors')" \
        resume                 "$WAKE_CMD" \
    timeout "$SUSPEND_TIMEOUT" "$(gate 'systemctl suspend')" \
    before-sleep               "$LOCK_CMD_IMMEDIATE" \
    after-resume               "$WAKE_CMD" \
    lock                       "$LOCK_CMD_UI"
