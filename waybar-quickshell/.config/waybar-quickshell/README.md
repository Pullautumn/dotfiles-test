# waybar-quickshell

第三套状态栏样式（`Mod+F4`）。布局与 `waybar`、`waybar-niri-Win11Like` 完全不同：中间是窗口标题，
右侧是硬件/网络/音频/亮度/电池/时钟/代理/托盘/电源的分组药丸，左侧是启动器、包更新、天气、
媒体播放、音律条、快捷命令组、截图录屏组和任务栏。

**它自己只是一个 waybar 配置。** 所有弹窗、面板、启动器、剪贴板界面都在
[`quickshell`](../../quickshell/.config/quickshell/README.md) 包里，通过 `~/.local/bin/qs-popup`
按需拉起。所以两者必须一起部署。

## 部署

安装器会自动处理，手动装的话：

```bash
stow -d ~/dotfiles -t ~ -R waybar-quickshell quickshell systemd
cd ~/.config/quickshell && uv sync      # Python 依赖，天气/农历/通知守护要用
systemctl --user daemon-reload           # 注册 qs-notifications.service（不 enable）
```

需要 `quickshell`（AUR）、`uv`（AUR）两个包。

## 切换

三套样式统一由 `~/.config/scripts/switch-waybar.sh` 管理：

```bash
switch-waybar.sh main        # 主样式（Mod+F2）
switch-waybar.sh win11       # waybar-niri-Win11Like（Mod+F3）
switch-waybar.sh quickshell  # 本样式（Mod+F4）
switch-waybar.sh next        # 循环切换
switch-waybar.sh status      # 看当前样式和后台状态
```

**切换会连带切换通知后端**，因为 `swaync` 和 Quickshell 的通知守护进程都要独占 D-Bus 上唯一的
`org.freedesktop.Notifications`：

| 样式 | 通知后端 |
|---|---|
| `main` / `win11` | `swaync`（开机自启那个） |
| `quickshell` | `qs-notifications.service`（`uv run python notifications/main.py`） |

剪贴板不用切：Quickshell 的 clipboard 组件读的就是同一个 `cliphist` 数据库，`wl-paste --watch` 一直在喂它。

## 模块与对应的 Quickshell 组件

| 位置 | 模块 | 点击行为 |
|---|---|---|
| 左 | `custom/arch` | 左键 `qs-popup launcher`，中键 `waypaper`，右键重启当前状态栏 |
| 左 | `custom/arch-updates` | 左键刷新，右键跑升级 |
| 左 | `custom/weather` | `qs-popup weather` |
| 左 | `custom/media` / `custom/visualizer` | 媒体状态与音律条，点击 `qs-popup media` |
| 左 | `group/quick-start` | 终端 / 文件管理器 / 浏览器 |
| 左 | `group/shortcuts` | AI 站点与常用链接 |
| 左 | `group/shot-recoder` | `qs-popup screenshot-toolbox`、`qs-popup screen-recorder` |
| 中 | `niri/window` | 当前窗口标题 |
| 右 | `group/hardware` | CPU / 内存 / 温度 → `qs-popup quick-settings` |
| 右 | `network` / `bluetooth` | `qs-popup wifi` / `qs-popup bluetooth` |
| 右 | `group/audio` / `group/g-backlight` | 音量、亮度滑块 |
| 右 | `custom/clock` | 农历时钟，点击 `qs-popup calendar` |
| 右 | `custom/timer` | 计时器状态，点击 `qs-popup timer` |
| 右 | `group/proxies` | 代理模式 / 内核 / 规则切换 |
| 右 | `custom/clipboard` | `qs-popup clipboard` |
| 右 | `group/power` | 关机 / 重启 / 休眠 / 锁屏 / 注销（`qs-popup power`） |

`custom/notification` 也已配好（`qs-popup notifications`），只是没放进 `modules-right`，
需要时把 `"custom/notification"` 加进数组即可。

## 配色

`style.css` 只做汇总，真正的颜色在 `colors.css`：

```css
@import "colors.css";        /* matugen 生成，已被 .gitignore 排除 */
@import "css/common.css";
@import "css/left-modules.css";
@import "css/center-modules.css";
@import "css/right-modules.css";
@import "css/tray.css";
```

`colors.css` 由 `~/.config/matugen/templates/waybar-quickshell-colors.css` 渲染，
换壁纸时跟着 `matugen-update.sh` 一起更新。变量名与主 waybar 不同（15 个 `@` 变量），
不能和 `waybar` 共用同一个模板。

## 与上游的差异

本目录是从 [jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles) 的 `waybar` 包原样搬来的，改了四处：

1. 包目录由 `~/.config/waybar` 改为 `~/.config/waybar-quickshell`，
   因此 `config.jsonc` 里所有 `~/.config/waybar/scripts/` 都改成了 `~/.config/waybar-quickshell/scripts/`
   （脚本用本目录 `scripts/` 里的自带副本，与主 waybar 的同名脚本互相独立，不会互相覆盖）。
2. `custom/arch` 右键原本是 `killall waybar ; waybar`，会让样式弹回主 waybar，改为
   `switch-waybar.sh restart`。
3. `custom/arch` 中键原本打开 Quickshell 的 `wallpaper-selector`（依赖 `theme-gen`/`wallpaper-manager`），
   本仓库不用那套，直接 exec `waypaper`。
4. 弹窗里的锁屏动作（电源菜单、idle-warning、`custom/lock` 按钮）统一指向 `qs-lock`，
   与 `Mod+Alt+L` 保持一致。

## 故障排除

- **整条状态栏起不来**：直接 `waybar -c ~/.config/waybar-quickshell/config.jsonc -s ~/.config/waybar-quickshell/style.css` 看报错，
  多数是 `colors.css` 不存在 → 跑一次 `matugen image <壁纸>`，或 `switch-waybar.sh restart`。
- **点按钮没反应 / 提示 `Component not found`**：`~/.config/quickshell` 没部署，或 `qs-popup` 没有执行权限
  （`chmod +x ~/.local/bin/qs-popup`）。
- **点按钮没反应、也不报错**：先看 `qs-popup logs`。日志里若是
  `Script qrc:/qs-blackhole unavailable`，说明 `./Theme.js` 没加载上——
  QML 的 JS 脚本导入不支持 `../`，每个组件目录都得有自己的一份 `Theme.js`。
  `qs-popup` 下次启动会自动从 `Commons/Theme.js` 复制过去并记一行日志；
  想直接看错误就前台跑：`quickshell -p ~/.config/quickshell/launcher/shell.qml`。
- **弹窗出来但没颜色 / 报 `Theme.js` 语法错误**：同上，先确认 `Theme.js` 存在且完整，
  再 `cd ~/.config/quickshell && uv sync`，最后重新 `matugen image <壁纸>`。
- **切到本样式后通知不弹**：`switch-waybar.sh status` 看 `qs-notifications` 是否运行；
  没跑起来多半是 `uv sync` 没做，或 systemd 单元没 `daemon-reload`。
- **开终端报 `zvm_after_init:1: command not found: zsh-patina`**：`zsh-patina` 没装。
  `paru -S zsh-patina`（已在安装器的 AUR 清单里，重跑安装器也会装）。
