# swaylock

Wayland 锁屏，**备用方案**。当前 niri 的 `Mod+Alt+L` 绑的是 hyprlock，这份配置留着备用。

部署到 `~/.config/swaylock`。

## 文件

| 文件 | 说明 |
|---|---|
| `config` | 背景图、指示器、时钟、配色 |
| `background.jpg` | 锁屏背景图 |
| `config.bak2` | 旧备份，不参与加载 |

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `image` | `/home/pullautumn/.config/niri/background.jpg` | 背景图绝对路径 |
| `indicator-radius` / `indicator-thickness` | 100 / 15 | 密码圈大小与粗细 |
| `indicator-x/y-position` | 50 / 50 | 居中 |
| `font` / `font-size` | `Noto Sans` / 20 | 时钟字体 |
| `clock` | 开启 | 显示时间 |
| `timestr` / `datestr` | `%H:%M` / `%Y-%m-%d` | 时间与日期格式 |
| `show-failed-attempts` | 开启 | 显示失败次数 |
| `color` | `11111B` | 遮罩底色 |
| `caps-lock-*-color` | `f5e0dc` / `a6e3a1` | 大写锁定提示色 |

`colors.css` 也会被 matugen 写到 `~/.config/swaylock/config`（模板见 `matugen/templates/swaylock-colors`），所以换壁纸后这套配色可能被整体重写。

## 用法

```bash
swaylock -f          # 前台锁屏
swaylock -f -c 000000  # 纯黑背景
```

## 注意

- `image` 是绝对路径且写死用户名，换用户后需要改，否则锁屏是纯色背景。
- 想用 swaylock 替代 hyprlock：把 `niri/conf.d/binds.kdl` 里 `Mod+Alt+L` 的命令从 `hyprlock -c ...` 改成 `swaylock -f`。
- 和 `gtklock` 的作用重复，别在同一台机器上同时装两个锁屏的自动触发（swayidle 里只配了一个）。
