# niri

[niri](https://github.com/YaLTeR/niri) 是 Wayland 原生的**滚动式平铺**合成器：工作区横向无限延伸，窗口按列纵向排列，新开窗口只会挤占列内空间，不会把已有窗口压缩变形。

部署到 `~/.config/niri`。

## 目录结构

| 文件 | 说明 |
|---|---|
| `config.kdl` | 入口文件，只有一句话：`include` 下面 9 个模块，实际配置都在 `conf.d/` |
| `conf.d/input.kdl` | 键盘布局、触控板（点击、滚动、手势）、鼠标灵敏度 |
| `conf.d/output.kdl` | 显示器：输出名、分辨率、缩放、位置 |
| `conf.d/layout.kdl` | 间隙、列宽预设（0.2/0.5/0.6/0.8/1.0）、焦点环、边框 |
| `conf.d/appearance.kdl` | overview 与通知的动画曲线、`prefer-no-csd` 隐藏标题栏 |
| `conf.d/environment.kdl` | niri 会话内的环境变量 |
| `conf.d/autostart.kdl` | 自启项：waybar、swaync、fcitx5、cliphist、swayidle、swayosd、polkit 代理、awww、waypaper、门户 |
| `conf.d/window-rules.kdl` | 窗口规则：默认浮动、按 app-id / 标题特判、默认列宽 |
| `conf.d/binds.kdl` | 全部快捷键 |
| `conf.d/colors.kdl` | 窗口边框配色，**由 matugen 生成**，手改会被下次换壁纸覆盖 |
| `config.kdl.all` | 官方全量配置参考，不参与加载，查语法时看它 |
| `scripts/` | 截图、录屏、长截图、侧边栏、快捷键弹窗等脚本 |

## 常用快捷键

`Mod` 在 TTY 下就是 Super 键。

| 快捷键 | 作用 |
|---|---|
| `Mod+Return` / `Mod+T` | 终端（kitty） |
| `Mod+A` | 应用启动器（fuzzel；Quickshell 样式下是 Quickshell launcher） |
| `Mod+O` / `Mod+G` | Overview 总览 |
| `Mod+Q` / `Alt+F4` | 关闭窗口 |
| `Mod+Y` | yazi（在 kitty 里） |
| `Mod+E` | 文件管理器（优先 nautilus，没有就 thunar） |
| `Mod+Alt+E` | 文件管理器（thunar） |
| `Mod+B` | 浏览器 |
| `Mod+V` / `Mod+Shift+V` | 剪贴板（shorinclip / fuzzel 图片预览版；Quickshell 样式下是 Quickshell clipboard） |
| `Mod+Alt+L` | 锁屏（Quickshell 锁屏，`qs-lock`） |
| `Mod+N` | 通知中心（swaync；Quickshell 样式下是 Quickshell 通知中心） |
| `Mod+Shift+N` | NiriMod 图形化配置编辑器（需自行安装 `nirimod-git`） |
| `Mod+Alt+Slash` | 快捷键说明弹窗 |
| `Alt+Tab` | 窗口快速切换（fuzzel） |
| `Mod+方向键` | 切换聚焦；加 `Ctrl` 变成移动窗口 |
| `Mod+Shift+方向键` | 跨显示器切换；加 `Ctrl` 移动窗口到别的显示器 |
| `XF86` 音量 / 亮度键 | 走 swayosd 显示 OSD，锁屏时也生效 |

功能键一栏：

| 快捷键 | 作用 |
|---|---|
| `Mod+F1` | 开关 fcitx5 |
| `Mod+F2` / `Mod+F3` / `Mod+F4` | 切换 waybar 样式（默认 / Win11Like / Quickshell），同时切换对应的通知后端 |
| `Mod+F5` / `Mod+F8` | Btrfs 快照存档 / 读档 |
| `Mod+F9` | 护眼模式（wlsunset）开关 |
| `Mod+F10` / `Mod+Shift+F10` | 随机换壁纸 / 随机下载动漫壁纸 |
| `Mod+Ctrl+F10` | 开关「开机自动随机换壁纸」（只影响下次开机，当前这张不动） |
| `Mod+Shift+F4` | 隐藏 waybar（进程仍在） |
| `Mod+Alt+W` | 打开 waypaper 选壁纸 |
| `Mod+Alt+M` / `Mod+Alt+T` | 切换 matugen 配色策略 |

侧边栏（`niri-sidebar-git` 提供，实验性）：

| 快捷键 | 作用 |
|---|---|
| `Mod+M` / `Mod+Alt+S` | 把当前窗口收进侧边栏 |
| `Mod+Ctrl+M` | 在浮动窗口与平铺之间切换聚焦 |
| `Mod+Alt+Z` | 展开 / 收起侧边栏 |
| `Mod+Alt+R` | 重置侧边栏排列 |

## 脚本

| 脚本 | 作用 |
|---|---|
| `niri-quick-switch-fuzzel.py` | `Alt+Tab` 的窗口切换菜单 |
| `niri-binds` | 读取 `binds.kdl` 生成快捷键说明 |
| `niri-monitor-switch.sh` | 显示器模式切换：quick-settings 面板的后端（`list-json`/`set`/`save`），也支持 `fuzzel` 交互菜单与 `apply` 恢复保存的配置（配置存 `~/.local/state/display/outputs.json`） |
| `swayidle.sh` | 空闲策略：超时锁屏、关显示器 |
| `start-yazi.sh` | 在 kitty 里启动 yazi |

截图不在这里出脚本，全部是 `binds.kdl` 里的单行命令（与 jswysnemc 一致）：

| 键位 | 动作 |
|---|---|
| `Print` | niri 内置 `screenshot`，写到 `screenshot-path` |
| `Ctrl+Print` | niri 内置 `screenshot-screen` |
| `Alt+Print` | niri 内置 `screenshot-window` |
| `Mod+Shift+S` | `wayfreeze` 冻结画面 → `slurp` 选区 → `grim` → `wl-copy` |
| `Alt+Ctrl+S` | `mark-shot` 选区截图并标注 |

录屏由状态栏按钮驱动，脚本是 `waybar/scripts/wf-recorder.sh`（两套 waybar 各一份副本，
`waybar-quickshell` 那份同源）。

## 外观与模糊

模糊分两层，互不影响，不要以为开了原生 blur 就能删掉预糊脚本。

**1. niri 原生 blur**（`ext-background-effect`，**需要 niri >= 26.04**）

| 文件 | 内容 |
|---|---|
| `layout.kdl` 顶层（`layout {}` **外面**） | `blur { passes 3; offset 3; noise 0.02 }`，`offset` 越大越糊，`7.0` 就相当明显 |
| `window-rules.kdl` 全局 `window-rule` | 圆角 6 + `clip-to-geometry` + `opacity 0.97` + `background-effect { blur; xray true }` + `popups` 里的右键菜单模糊 |
| `window-rules.kdl` `layer-rule` | `^waybar$` 一条、quickshell 卡片弹窗一条（圆角 20） |

要点：

- **全局 `window-rule` 只允许有一条**（无 `match` 的那种）。圆角、`clip-to-geometry`、`opacity`、
  `background-effect` 全写在这同一条里。NiriMod 只认最后一条无 `match` 的规则，拆成两条会让
  GUI 里显示的值和实际生效的值对不上。
- **`opacity` 是必须的**。窗口完全不透明时模糊被挡在后面，加了也看不见。全局 `0.97` 只透出 3%，很淡但够。
- **`xray true` vs `false`**：`true` 只模糊壁纸、算一次复用，几乎不耗 GPU；`false` 模糊背后真实内容，弹窗和右键菜单用这个才正确，但每帧重算。
- **quickshell 弹窗正则里有排除项**：`quickshell-welcome`、`idle-warning` 和各种 `-bg` 全屏捕获层都不能加圆角，否则会切掉屏幕四角并糊整屏。

**2. overview 背景预糊**（`scripts/niri_auto_blur_bg.sh`）

niri 的 blur 只作用于 toplevel / layer surface / pop-up 三类客户端表面，**管不到 backdrop**。overview 的壁纸是 niri 自己画的底，所以只能预先生成模糊图再贴上去：

```bash
magick <壁纸> -blur 0x15 -fill black -colorize 40%   # 生成
awww img -n overview <模糊图>                         # 贴到 awww-daemonoverview 图层
```

配合 `window-rules.kdl` 开头的 `place-within-backdrop true`，这张图才会落进 overview 背景。
`scripts/niri_auto_blur_bg.sh` 和 `niri_set_overview_blur_dark_bg.sh` 内容完全相同（md5 一致），
一个给开机用、一个给换壁纸用。

> Win11 那套状态栏 `style.css` 里 `window#waybar` 用的是不透明的 `@surface`，
> 原生 blur 在它身上看不出来。想要磨砂效果就自己改成 `alpha(@surface, 0.85)` 之类。

## 图形化改配置（NiriMod）

[NiriMod](https://github.com/srinivasr/nirimod) 是 niri 的 GTK4 配置编辑器，圆角、模糊、动画、
键位、输出布局都能点着改。`Mod+Shift+N` 打开，或终端 `nirimod`。

装法：跑 `./install.sh` 时在「可选软件」里勾 `nirimod-git`，或手动 `paru -S nirimod-git`。

**它改的就是本仓库，不需要任何额外配置。**

```bash
stow -d ~/.dotfiles -t "$HOME" -R niri
# niri 包只含 .config/niri 一个子目录，stow 会折叠成目录软链：
#   ~/.config/niri -> ~/.dotfiles/niri/.config/niri
```

NiriMod 写 `~/.config/niri/conf.d/layout.kdl` 时路径解析会穿过这条目录软链，物理落点就是仓库里
那个文件；它内部还会先 `resolve()` 一次再 `os.replace()`（`kdl_parser.py` 的 `_write_target`），
所以就算以后改用 `stow --no-folding` 让每个文件单独软链，也不会把软链替换成 HOME 下的实体副本。

因此**不要**给它加 `--config` 指向仓库绝对路径，也不要设 `NIRIMOD_CONFIG_DIR`：niri 运行时读的是
`~/.config/niri/config.kdl`、`niri validate` 校验的也是默认路径，两边一旦分叉就会出现
「校验通过但实际没生效」。

保存行为：

- 自动备份到 `~/.config/nirimod/backups`（10 代，不在 stow 包内，不进仓库）
- 写盘 → `niri validate` → 失败按快照回滚全部文件 → 成功 `niri msg action load-config-file` 热重载
- 首次保存会把 KDL 按它自己的格式重排，diff 里大部分是空白变化；`r#"firefox$"#` 这类原始字符串
  会变成 `r"firefox$"`，语义等价

两个注意点：

- **别在 GUI 里改颜色**。边框色来自 `conf.d/colors.kdl`，那是 matugen 生成的；NiriMod 保存时会把它
  一起重新序列化，下次 matugen 又覆盖回来，白折腾。颜色统一走 `Mod+Alt+M` / `Mod+Alt+T`。
- `profiles/` 会在 `~/.config/niri/profiles` 出现，因为配置目录是软链，它实际落在仓库里，已加进
  `.gitignore`。要在多台机器间共享 profile 再自行放开。

## 改完怎么生效

```bash
niri validate                          # 先校验语法，写错会指出行号
niri msg action reload-config          # 热重载，不用重启会话
```

如果 `niri validate` 报 `blur` / `background-effect` 不认识，就是 niri 版本低于 26.04，先升级。

改 `output.kdl` 前先确认显示器名字：

```bash
niri msg outputs
```

## 注意

- `autostart.kdl` 里开机跑的是 `~/.config/scripts/wallpaper-rotate.sh boot`，它读 `~/.cache/wallpaper-auto-rotate` 决定是否随机换图。不想随机就按 `Mod+Ctrl+F10` 或跑 `wallpaper-rotate.sh off`，**不要去改 autostart 那一行**。
- Xft.dpi 被设成 144（1.5 倍缩放），换成高分屏或普通屏时按需改这一行。
- `Mod+F9` 调用的 `~/.local/bin/toggle-wlsunset` 由本仓库的 `local-bin` 包提供，色温区间（`TEMP_LOW`/`TEMP_HIGH`）和日出日落时间写在脚本开头，按需改。
- `autostart.kdl` 里的 `xhost +si:localuser:root` 已注释停用：niri 的 XWayland 是懒启动的，开机那一刻 `DISPLAY` 还不存在，这行必然失败。要跑需要 root 的 X11 GUI 程序时再 `pacman -S xorg-xhost` 并取消注释。
