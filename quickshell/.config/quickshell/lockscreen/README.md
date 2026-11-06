# QuickShell Lockscreen

基于 QuickShell 的锁屏组件，使用 Wayland ext-session-lock-v1 协议。

## 功能特性

- **Grace Period（假锁屏）**: 倒计时期间可通过移动鼠标/按键取消
- **真锁屏**: 需要密码或人脸识别解锁
- **壁纸背景**: 自动读取当前壁纸
- **农历日历**: 显示农历日期和节日
- **双认证模式**: 人脸识别和密码认证独立运行

## 依赖

- QuickShell (with Quickshell.Services.Pam)
- howdy (可选，用于人脸识别)
- swayidle (用于空闲检测)

## PAM 配置

本锁屏使用两个独立的 PAM 配置：

### 1. `/etc/pam.d/qs-lock-face` - 人脸识别 + 密码

> 安装器的 `setup_qs_lock_pam` 会自动生成这个文件，并且会先探测本机 howdy 用哪种
> PAM 模块：有 `pam_howdy.so` 就用它，只有 `howdy/pam.py` 就写
> `pam_python.so /lib/security/howdy/pam.py`。下面手动写的话，先确认模块在不在：
>
> ```bash
> ls -l /usr/lib/security/pam_howdy.so /lib/security/howdy/pam.py
> ```
>
> 两个都不存在时（howdy 装了但打包不完整），这一行怎么都对，人脸永远失败，
> 而界面只显示「识别失败」——这是最容易踩的坑。

```bash
sudo tee /etc/pam.d/qs-lock-face << 'EOF'
#%PAM-1.0
auth       sufficient pam_howdy.so
auth       include    system-auth
account    include    system-auth
session    include    system-auth
EOF
```

### 2. `/etc/pam.d/qs-lock` - 仅密码 (需手动创建)

```bash
sudo tee /etc/pam.d/qs-lock << 'EOF'
#%PAM-1.0
# Password-only authentication for lockscreen
auth       include    system-auth
account    include    system-auth
session    include    system-auth
EOF
```

**为什么需要两个配置？**

- 点击头像或恢复路径使用 `qs-lock-face` 配置，启动人脸识别
- 输入密码时使用 `qs-lock` 配置，跳过人脸识别直接验证密码
- 这样可以在人脸识别过程中随时切换到密码认证，无需等待 howdy 超时

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `LOCK_GRACE_TIMEOUT` | Grace period 时长（秒） | 5 |
| `LOCK_FACE_ON_START` | 启动后进入真锁屏时自动触发人脸识别 | 关闭 |

## 使用方法

```bash
# 直接启动锁屏
qs-lock

# 带 grace period
LOCK_GRACE_TIMEOUT=30 qs-lock

# 显式触发人脸识别（用于休眠/熄屏恢复）
qs-lock --face
```

普通进入锁屏不会自动触发人脸识别。点击头像、`qs-lock --face`、休眠恢复、熄屏恢复会触发人脸识别。

## Grace Period 操作

- **移动鼠标 / 左键 / 滚轮 / 任意键**: 取消锁屏
- **右键 / Super+L**: 立即进入真锁屏

## 文件结构

```
lockscreen/
├── shell.qml          # 主组件
├── lunar_info.py      # 农历信息脚本
├── scripts/
│   └── capture-grace-screenshots.sh  # 等待阶段按输出截图
└── README.md          # 本文件
```

## swayidle 集成

参考 `~/.config/niri/scripts/swayidle.sh`:

```bash
IDLE_TIMEOUT=180      # 空闲多久后启动锁屏
GRACE_DURATION=30     # Grace period 时长
DPMS_TIMEOUT=300      # 空闲多久后关闭显示器
SUSPEND_TIMEOUT=600   # 空闲多久后自动挂起

LOCK_CMD="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=${GRACE_DURATION} qs-lock"
LOCK_CMD_UI="pgrep -x quickshell -a | grep -q 'lockscreen' || LOCK_GRACE_TIMEOUT=3 qs-lock"
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
```

三个不能改的地方：

1. **不加 `-w`**。`-w` 会 `waitpid`，而 `qs-lock` 末行是
   `exec quickshell -p ~/.config/quickshell/lockscreen`（常驻），一旦真的起锁屏，
   swayidle 会卡到解锁为止，期间所有 timeout 停摆。睡前锁屏的窗口由 logind 的
   `InhibitDelayMaxSec`（默认 5s）兜底。
2. **`resume` 必须紧跟在 `timeout DPMS` 后面**。swayidle 的 `resume` 修饰的是前
   一条 timeout，放到 `timeout SUSPEND` 后面就变成「挂起恢复后才亮屏」。
3. **`lock` 事件要配对 `loginctl lock-session`**。它不自计时，靠 logind 的 `Lock`
   信号触发；`binds.kdl` 里 `Mod+Alt+L` 走的就是这条路。
