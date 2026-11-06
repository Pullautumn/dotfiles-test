# local-bin

自定义命令入口，放几个脚本到 `~/.local/bin`。这个目录已经在 PATH 里（`setup_bash_path` 负责），所以脚本名可以直接当命令用。

## 脚本

| 文件 | 作用 |
|---|---|
| `niri-session-wlroots` | 用 `wlroots` 作为 `XDG_CURRENT_DESKTOP` 启动 niri |
| `qs-lock` | 启动 Quickshell 锁屏（`Mod+Alt+L`、空闲超时、电源菜单都走它） |
| `qs-popup` | Quickshell 弹窗调度器（waybar-quickshell 的每个按钮都调它） |
| `quicksave` | 创建 Btrfs 快照（存档） |
| `quickload` | 从 Btrfs 快照恢复（读档） |
| `toggle-wlsunset` | 护眼模式开关（`Mod+F9`、Win11Like 状态栏护眼右键） |

## qs-lock

```bash
qs-lock            # 锁屏（grace period 由 LOCK_GRACE_TIMEOUT 决定，默认 5 秒）
qs-lock --face     # 锁屏并立刻触发人脸识别（装了 howdy 才有意义，否则等于 0 秒宽限）
```

它做的事比 `quickshell -p ~/.config/quickshell/lockscreen` 多两件：

1. **同步 `Theme.js`**。QML 的 JS 脚本导入不能用 `../`，每个组件目录必须自带一份
   `./Theme.js`。平时由 `qs-popup` 的 `ensure_qml_assets` 维护，但锁屏是独立进程、
   绕过了 `qs-popup`，所以这里自己按 mtime 复制一次。
2. **防重复启动**。已经在锁屏时再调一次不会起第二个 quickshell，`--face` 只会
   往 `$XDG_RUNTIME_DIR/qs-lock-face-trigger` 写一条唤醒信号。

| 环境变量 | 说明 |
|---|---|
| `LOCK_GRACE_TIMEOUT` | grace period 秒数。`0` = 立刻要密码 |
| `LOCK_FACE_ON_START` | `1`/`true`/`yes`/`on` → 进真锁屏后自动试人脸 |

调用方与对应的宽限时长：

| 入口 | 命令 |
|---|---|
| `Mod+Alt+L` | `loginctl lock-session` → swayidle 的 `lock` 事件 → `LOCK_GRACE_TIMEOUT=3 qs-lock` |
| 空闲 180 秒（`swayidle.sh` 的 `timeout`） | `LOCK_GRACE_TIMEOUT=30 qs-lock` |
| 空闲 600 秒（`swayidle.sh` 的 `timeout`） | `systemctl suspend`（睡前由 `before-sleep` 立刻锁屏） |
| 合盖 / 休眠前（`before-sleep`） | `LOCK_GRACE_TIMEOUT=0 qs-lock` |
| 状态栏 / 电源菜单 / idle-warning | `qs-lock`（3 秒或无宽限，见各配置） |

PAM service 是 `/etc/pam.d/qs-lock`（装了 howdy 时另加 `qs-lock-face`），
由安装器的 `setup_qs_lock_pam` 创建。**缺了它输什么密码都解不开。**

## toggle-wlsunset

```bash
toggle-wlsunset            # 翻转（在跑就关，没跑就开）
toggle-wlsunset on|off     # 明确开 / 关
toggle-wlsunset status     # 打印 on / off
```

色温由脚本头部的变量决定：`TEMP_LOW=4000` / `TEMP_HIGH=6500`，
日出日落写死成 `07:00` / `19:00`。想按真实经纬度算，把 `wlsunset` 那行的
`-S`/`-s` 换成 `-l <纬度> -L <经度>`。

「关」就是 `pkill -x wlsunset`：wlsunset 走 `wlr-gamma-control` 协议把色温直接
推给合成器，进程退出色温立刻复原，没有需要还原的残留状态。

`wlsunset` 本体由 `PKG_GROUPS[power]` 安装（`brightnessctl wlsunset`）。

## niri-session-wlroots

```sh
#!/bin/sh
export XDG_CURRENT_DESKTOP=wlroots
export XDG_SESSION_DESKTOP=niri
exec niri-session "$@"
```

比直接 `niri-session` 多做一件事：把 `XDG_CURRENT_DESKTOP` 设成 `wlroots`。Electron、Qt 之类靠这个变量判断「该走 Wayland 还是 X11」。

`environment.d` 包里也有一条 `XDG_CURRENT_DESKTOP=wlroots`，两者效果相同，任选。

装登录管理器的时候，会话项指向哪个都行；想让桌面变量更"标准"（`niri`）就直接 `niri-session`。

## quicksave / quickload

基于 **Btrfs + snapper** 的快照工具，有中英双语界面，普通用户即可运行（权限不够时会请求提权，自动把 wheel 组加进配置）。

依赖：

| 包 | 用途 |
|---|---|
| `snapper` | 快照管理后端 |
| `btrfs-progs` | Btrfs 工具 |
| 根分区是 Btrfs 且配好了 snapper 配置 | 否则 `quicksave -lc` 会提示「未检测到任何 snapper 配置」 |

常用：

```bash
quicksave                      # 用默认描述创建快照
quicksave -c root -d "装驱动前"  # 指定配置与描述
quicksave -l                   # 列出快照
quicksave -lc                  # 列出可用的 snapper 配置
quicksave -del 12              # 删掉 ID 12 的快照

quickload                      # 交互式选快照恢复
quickload -c root -l           # 看 root 配置下有哪些可恢复的快照
quickload -c root -n           # 直接恢复，不再确认
```

niri 里 `Mod+F5` 存档、`Mod+F8` 读档。

## 注意

- `quicksave` / `quickload` 是**强依赖 Btrfs** 的。ext4 上跑会直接报错退出，不是坏了。
- 恢复快照本身是危险操作，`quickload -n` 不给二次确认；不熟悉就先 `-l` 看看，别直接 `-n`。
- 这两个脚本带 `set -euo pipefail`，任何一步失败都会立刻中止——这是有意的，避免半途恢复。
- `~/.local/bin` 是 stow 会合并的共享目录，安装器**不会**备份或整体替换它，只往里加文件。
