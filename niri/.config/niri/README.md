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
| `hyprlock.conf` | hyprlock 锁屏配置（`Mod+Alt+L` 调用） |
| `scripts/` | 截图、录屏、长截图、侧边栏、快捷键弹窗等脚本 |

## 常用快捷键

`Mod` 在 TTY 下就是 Super 键。

| 快捷键 | 作用 |
|---|---|
| `Mod+Return` / `Mod+T` | 终端（kitty） |
| `Mod+A` | 应用启动器（fuzzel） |
| `Mod+O` / `Mod+G` | Overview 总览 |
| `Mod+Q` / `Alt+F4` | 关闭窗口 |
| `Mod+Y` | yazi（在 kitty 里） |
| `Mod+E` | 文件管理器（优先 nautilus，没有就 thunar） |
| `Mod+Alt+E` | 文件管理器（thunar） |
| `Mod+B` | 浏览器 |
| `Mod+V` / `Mod+Shift+V` | 剪贴板（shorinclip / fuzzel 图片预览版） |
| `Mod+Alt+L` | 锁屏（hyprlock） |
| `Mod+N` | 通知中心（swaync） |
| `Mod+Alt+Slash` | 快捷键说明弹窗 |
| `Alt+Tab` | 窗口快速切换（fuzzel） |
| `Mod+方向键` | 切换聚焦；加 `Ctrl` 变成移动窗口 |
| `Mod+Shift+方向键` | 跨显示器切换；加 `Ctrl` 移动窗口到别的显示器 |
| `XF86` 音量 / 亮度键 | 走 swayosd 显示 OSD，锁屏时也生效 |

功能键一栏：

| 快捷键 | 作用 |
|---|---|
| `Mod+F1` | 开关 fcitx5 |
| `Mod+F2` / `Mod+F3` | 切换 waybar 样式（默认 / Win11Like） |
| `Mod+F5` / `Mod+F8` | Btrfs 快照存档 / 读档 |
| `Mod+F9` | 护眼模式（wlsunset）开关 |
| `Mod+F10` / `Mod+Shift+F10` | 随机换壁纸 / 随机下载动漫壁纸 |
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
| `screenshot.sh` | 截图主入口，支持全屏 / 区域 / 聚焦窗口，接 satty 标注 |
| `wf-recorder.sh` | 录屏（含声音与倒计时提示） |
| `longshot.sh` / `longshot-*.sh` / `stitch.py` | 长截图：分段滚动截取后拼接 |
| `niri-quick-switch-fuzzel.py` | `Alt+Tab` 的窗口切换菜单 |
| `niri-binds` | 读取 `binds.kdl` 生成快捷键说明 |
| `swayidle.sh` | 空闲策略：超时锁屏、关显示器 |
| `start-yazi.sh` | 在 kitty 里启动 yazi |
| `screenshot-edit.sh` | 截完直接丢给 satty 编辑 |

截图、录屏脚本在 `waybar/scripts/` 下各有一份副本（状态栏按钮调用），改动时两边都要同步。

## 改完怎么生效

```bash
niri validate                          # 先校验语法，写错会指出行号
niri msg action reload-config          # 热重载，不用重启会话
```

改 `output.kdl` 前先确认显示器名字：

```bash
niri msg outputs
```

## 注意

- `autostart.kdl` 里 `spawn-sh-at-startup "sleep 1 && waypaper --random"` 决定了开机随机壁纸；不想要随机就删掉这行。
- Xft.dpi 被设成 144（1.5 倍缩放），换成高分屏或普通屏时按需改这一行。
- `Mod+F9` 调用的 `~/.local/bin/toggle-wlsunset` 不在本仓库里，由系统或其他脚本提供；没有它这个键按下无反应。
