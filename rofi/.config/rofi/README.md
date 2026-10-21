# rofi

第二套启动器 / 通用选择菜单。fuzzel 是主力（`Mod+A`），rofi 主要用于主题化的启动器与电源菜单。

部署到 `~/.config/rofi`。

## 文件

| 路径 | 说明 |
|---|---|
| `config.rasi` | 主配置：模式列表、字体、行数、居中、DPI、图标主题，末尾 `@theme "arthur"` 指定主题 |
| `applets/` | 一组小程序：应用、电量、亮度、音量、截图、电源菜单、快速链接 |
| `launchers/type-1 … type-8/` | 8 套启动器主题，每套内有 `launcher.sh` 与多个 `style-*.rasi` |
| `powermenu/type-1 … type-6/` | 6 套电源菜单主题 |
| `scripts/` | `launcher_t1` … `launcher_t8`、`powermenu_t1` … 的快捷入口 |
| `colors/` | 配色片段 |
| `images/` | 主题用到的背景与图标 |

整套 `.rasi` 主题一共 166 个，来自 adi1090x 的 rofi 主题集合，可以直接挑一套用。

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `modi` | `run,drun,window,ssh,combi` | 启用哪些模式 |
| `font` | `Noto Sans 18` | 字号偏大，适合 1.33 缩放的屏幕 |
| `lines` | 10 | 显示行数 |
| `location` | 1 | 屏幕居中 |
| `dpi` | 133 | 与 niri 的 1.5 缩放 + 93% 综合视觉匹配 |
| `terminal` | `kitty` | 需要终端时用它 |
| `icon-theme` | `Adwaita` | drun 模式图标 |
| `matching` | `fuzzy` | 模糊匹配 |
| `fake-background` | `screenshot` | 半透明背景用截图 |

## 用法

```bash
rofi -show drun        # 应用启动
rofi -show run         # 执行命令
rofi -show window      # 窗口切换
rofi -show combi       # 混合模式
~/.config/rofi/scripts/launcher_t7   # 用第 7 套主题的启动器
~/.config/rofi/scripts/powermenu_t3  # 第 3 套电源菜单
```

`niri` 的 `Mod+Shift+V` 会先 `pkill rofi` 再用 fuzzel 版剪贴板，避免两者抢焦点。

## 注意

- `config.rasi` 里的 `pid: "/run/user/1000/rofi.pid"` 写死了 UID，换用户后建议删掉这行让 rofi 自己决定。
- 主题靠 `@theme "arthur"` 引入，换主题改这一行即可；每个 `type-N` 目录里的 `style-M.rasi` 也可以用 `-theme` 单独指定。
- 大量主题只在对应 `launcher.sh` 里生效，直接 `rofi -show drun` 用的是 `config.rasi` 的默认样式。
