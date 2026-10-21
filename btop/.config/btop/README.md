# btop

系统监控（CPU / 内存 / 磁盘 / 网络 / 进程），终端里的「任务管理器」。

部署到 `~/.config/btop`。

## 文件

| 文件 | 说明 |
|---|---|
| `btop.conf` | 主配置：主题、排序方式、背景、键位方案 |
| `themes/catppuccin_mocha.theme` | Catppuccin Mocha 配色 |
| `themes/matugen.theme` | 换壁纸后 matugen 生成，重启 btop 生效 |

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `color_theme` | `catppuccin_mocha.theme` | 当前主题 |
| `theme_background` | `true` | 用主题背景色（关掉则透明） |
| `proc_sorting` | `memory` | 进程默认按内存排序 |
| `vim_keys` | `false` | 用方向键而不是 hjkl |

## 主题切换

```bash
# 交互式换主题
btop  # 按 Esc → Options → color_theme
# 或者直接改 btop.conf 里的 color_theme
```

matugen 会把配色写到 `~/.config/btop/themes/matugen.theme`，并在 `post_hook` 里给 btop 发 `SIGUSR1` / `SIGUSR2` 让它热重载。

## 常用键

| 键 | 作用 |
|---|---|
| `Esc` | 菜单 / 退出菜单 |
| `f` | 切换 CPU 频率显示 |
| `p` | 进程树 |
| `+` / `-` | 调整刷新间隔 |
| `/` | 搜索进程 |

## 注意

- `theme_background = true` 配合终端 85% 透明度（kitty 配置）效果最好；终端不透明时建议设成 `false`。
- 进程排序改成 `memory` 后，CPU 占用高的进程不在最上面，找卡顿时按 `c` 临时切 CPU 排序。
