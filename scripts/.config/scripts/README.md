# scripts

跨组件共用的胶水脚本，放在 `~/.config/scripts`。壁纸、配色、截图、录屏、状态栏切换都在这里，
被 waypaper 的 `post_command`、niri 的键位与 autostart、三套状态栏的按钮互相调用，
是「换壁纸 → 整套换色」这条链路的中间层。

部署到 `~/.config/scripts`。安装器 Phase 5 会给这里的 `*.sh` / `*.py` 统一加执行权限。

## 脚本放哪儿（三层规则）

新加脚本前先对号入座，不要凭手感决定：

| 层 | 位置 | 判据 | 例子 |
|---|---|---|---|
| **T0 · PATH 命令** | `~/.local/bin` | 要在终端里手敲、被多个组件按名调用、或作为系统入口（session / systemd 直接 exec） | `qs-lock`、`qs-popup` |
| **T1 · 跨组件流程** | `~/.config/scripts`（这里） | 调用方 ≥2 个组件，但只在图形会话里用，不需要进 PATH | `switch-waybar.sh`、`matugen-update.sh`、`screenshot.sh`、`wf-recorder.sh`、`terminal-launcher` |
| **T2 · 组件私有** | 组件自己的目录 | 只有它自己的配置 / 主题 / QML 调用，属于实现细节 | `waybar/scripts/caffeine.sh`、`niri/scripts/swayidle.sh`、`rofi/scripts/launcher_tN` |

一句话判据：**生命周期跟谁绑定，就放谁的目录；出现第二个调用方，升级到共享层；
需要被手敲或被系统入口调用，进 PATH。**

几条硬约束（不是习惯问题，搬了会坏）：

- `rofi/scripts/launcher_tN`、`powermenu_tN` 被主题 `.rasi` 用相对路径引用，必须留在主题目录里
- `mpv/scripts/*.lua` 只从 `~/.config/mpv/scripts` 自动加载，没有可配的搜索路径
- quickshell 各组件目录里的 helper 与 `shell.qml` 同目录，才能「整目录复制即自成一套」

引用方式：T1 一律写成绝对路径 `~/.config/scripts/xxx.sh`。waybar 的 `on-click` 和 niri 的
`spawn` / `spawn-sh` 都不走登录 shell，取不到 zsh 里加的 PATH。

## 脚本

| 脚本 | 作用 | 谁调用 |
|---|---|---|
| `matugen-update.sh` | 总入口：读壁纸 → 调 `matugen image` → 处理策略与明暗 → 触发重载 | waypaper 的 `post_command`、`matugen-select-type.sh`、`random-anime-wallpaper.sh` |
| `matugen-select-type.sh` | 交互式切换配色策略，结果缓存在 `~/.cache/matugen-strategy/type` | `Mod+Alt+M` / `Mod+Alt+T` |
| `matugen-restore.sh` | 系统级还原：清图标缓存、按缓存重新生成整套配色 | 手动 |
| `niri_auto_blur_bg.sh` | 生成 overview 用的模糊 + 变暗背景，并跟随当前壁纸自动重算（缓存命中则直接贴图） | waypaper 的 `post_command`（紧跟 matugen-update 后）、`niri/conf.d/autostart.kdl` 开机启动、Win11Like 状态栏中键、`random-anime-wallpaper.sh` |
| `random-anime-wallpaper.sh` | 从在线 API 随机下载动漫壁纸并设为壁纸 | `Mod+Shift+F10` |
| `wallpaper-rotate.sh` | 开机「自动随机换壁纸」的开关，状态存 `~/.cache/wallpaper-auto-rotate` | `niri/conf.d/autostart.kdl` 开机启动、`Mod+Ctrl+F10`、手动 |
| `screenshot.sh` | 选区截图直接进剪贴板（`grim` + `slurp`，三行） | 三套状态栏的截图按钮 |
| `wf-recorder.sh` | 录屏主控：`waybar` 出状态 JSON，`start` / `stop` / `pause-toggle` / `settings` | 三套状态栏的录屏按钮、quickshell 录屏面板 |
| `terminal-launcher` | 按 `$TERMINAL` 打开终端，屏蔽 kitty / ghostty / foot / alacritty / wezterm 等参数差异；`--float` 开 1200×1000 浮动窗 | `waybar-quickshell` 的终端 / CPU / 内存 / 网络按钮 |

## terminal-launcher

从 [jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles) 的 `my-scripts/.custom/bin` 原样移植。

```bash
~/.config/scripts/terminal-launcher                # 打开 $TERMINAL
~/.config/scripts/terminal-launcher --float        # 浮动窗口（app-id = terminal-float）
~/.config/scripts/terminal-launcher -- btop        # 在终端里跑命令
```

终端由 `$TERMINAL` 决定，支持 `kitty --single-instance` 这种带参数的写法；未设置时按
kitty → ghostty → foot → alacritty → wezterm → konsole → gnome-terminal → kgx → xterm
的顺序探测第一个装了的。waybar 的 `on-click` 不走登录 shell，取不到 zsh 里设的 `$TERMINAL`，
所以这几个按钮实际走的是探测链（本仓库装着 kitty，命中第一个）。

`--float` 产生的 app-id 是 **`terminal-float`**（ghostty 走 `com.snemc.terminal-float`，GTK
要求反域名格式），由 `niri/conf.d/window-rules.kdl` 里单独那条 `match app-id="(?i)terminal-float"`
接管（`open-floating true` + 固定 1200×1000）。改类名必须两边一起改。

注意别和同一文件里的 `app-id="floating-term"` 混了：那个是 `waybar-niri-Win11Like` 更新按钮
（`kitty --class floating-term -e shorin checkallupdates`）专用的，两个入口互不相干。

这个文件**没有 `.sh` 后缀**，靠 `setup/steps/03-dotfiles.sh` 的 shebang 探测拿执行位
（`find ... ! -name "*.*"` + 首行 `#!`），不在 `*.sh` 批量赋权那一段里。

> 已知遗留：`waybar-quickshell/scripts/package-updates.sh:148` 仍引用旧路径
> `~/.local/bin/terminal-launcher`，该模块已弃用、暂不修。

## matugen-update.sh

```bash
~/.config/scripts/matugen-update.sh                       # 用当前壁纸
~/.config/scripts/matugen-update.sh /path/to/wall.jpg     # 指定图片
~/.config/scripts/matugen-update.sh -n                    # 终端里交互式挑主色
```

这个脚本**只接受 `-n` 和壁纸路径**，没有 `-t` / `-m` 选项。配色方案（`scheme-*`）、
主色 index 和明暗都由 `~/.cache/matugen-strategy/` 下的状态文件决定，写这些文件的正规入口是
`Mod+Alt+M`（`matugen-select-type.sh`）。

明暗的默认值是 **`light`**（`mode` 文件缺失时），全新安装从亮色起步。
这一项不只是配色：light 会把 dconf 的 `color-scheme` 写成 `prefer-light`，dark 写成
`prefer-dark`——改的是系统「白色 / 黑暗模式」总开关，持久生效，只有 `matugen-restore.sh`
会写回 `default`。要换明暗走菜单，别手撕状态文件。

## matugen-select-type.sh

```bash
~/.config/scripts/matugen-select-type.sh
```

弹出选择界面挑配色策略，选中后写进 `~/.cache/matugen-strategy/type` 并立即用当前壁纸重跑一次。

## random-anime-wallpaper.sh

```bash
~/.config/scripts/random-anime-wallpaper.sh
```

从 `https://t.alcy.cc/pc/` 拉一张随机动漫图，存到壁纸目录后设为壁纸，再调 `matugen-update.sh` 换色。

## wallpaper-rotate.sh

```bash
~/.config/scripts/wallpaper-rotate.sh status    # 看当前是 on 还是 off
~/.config/scripts/wallpaper-rotate.sh toggle    # 翻转（等同于 Mod+Ctrl+F10）
~/.config/scripts/wallpaper-rotate.sh off       # 关掉开机随机换图
~/.config/scripts/wallpaper-rotate.sh on        # 恢复开机随机换图
```

状态就是 `~/.cache/wallpaper-auto-rotate` 里的一个词。**文件不存在按 `on` 处理**，所以升级完行为不会变。

两个状态做的事完全不同：

| 状态 | 开机执行 | 实际效果 |
|---|---|---|
| `on` | `waypaper --random` | 换新图 → `post_command` 跑 matugen 换全套配色 → 重算总览模糊 |
| `off` | `awww restore` | 只把上次那张贴回屏幕，不换图、不换色、不重算模糊，零计算 |

`off` 为什么要留一条 `awww` 命令：`awww-daemon` 每次开机是空白的，不记得上次画了哪张，一条命令都不跑就是黑屏。`awww restore` 读的是 daemon 自己 `~/.cache/awww/` 里的缓存，不经过 waypaper，所以不会触发 matugen。

⚠️ **不要用 `waypaper --restore` 来实现「固定壁纸」**：waypaper 不管 `--random` 还是 `--restore` 都会跑 `post_command`，等于照样换色、照样重算模糊，那就不是「不动」了。

`off` 的模式下 `niri_auto_blur_bg.sh` 依然会启动，但当前壁纸没变，它的模糊图缓存命中，直接贴图走人，不会跑 `magick`。

开关只影响**下次开机**，不会立刻撤回当前这张。手动 `Mod+F10` 随机也不受开关影响。

## 和 waypaper 的关系

`waypaper/.config/waypaper/config.ini` 里这一行串起了全部：

```ini
post_command = $HOME/.config/scripts/matugen-update.sh $wallpaper && sleep 0.8 && $HOME/.config/scripts/niri_auto_blur_bg.sh $wallpaper
```

所以「在 waypaper 里点一张壁纸」= 换壁纸 + 换整套配色 + 重做 overview 背景，中间那条 `sleep 0.8` 是等 awww 把壁纸真正画上去。

## 注意

- 这些脚本都**不是 POSIX sh**，用的是 bash 特性（数组、`[[ ]]`），别把 shebang 改成 `sh`。
- `random-anime-wallpaper.sh` 依赖外网，API 挂了脚本会静默退出，不会破坏当前壁纸。
- `matugen-restore.sh` 会清 `~/.cache` 下的图标缓存并重建，跑一次要几十秒，别频繁用。
- 脚本里的路径基本都是 `$HOME/...` 相对写法，换用户名不用改。
