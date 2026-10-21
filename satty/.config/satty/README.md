# satty

截图标注工具。`grim` 截完图丢给它，画箭头、打码、加文字，然后复制或保存。

部署到 `~/.config/satty`。

## 文件

| 文件 | 说明 |
|---|---|
| `config.toml` | 复制命令、默认工具、缩放步进、字体与回退链 |

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `copy-command` | `wl-copy` | 标注完复制到剪贴板 |
| `initial-tool` | `brush` | 打开就是画笔 |
| `focus-toggles-toolbars` | `true` | 聚焦窗口时隐藏工具栏 |
| `zoom-factor` | 1.1 | 每次滚轮缩放 10% |
| `font.family` | `Roboto` | 文字工具主字体 |
| `font.fallback` | `Noto Sans CJK SC/JP/TC/KR` | 中日韩回退，保证中文能显示 |

## 用法

```bash
# 区域截图 → 直接标注
grim -g "$(slurp)" - | satty --filename -

# 已有图片
satty --filename ~/Pictures/shot.png

# 标注后保存到指定文件
grim -g "$(slurp)" - | satty --filename - --output-filename ~/Pictures/out.png
```

niri 的 `Mod+Shift+S` 一类截图键位最终调的就是 `niri/scripts/screenshot.sh`，里面已经串好 grim → satty。

## 常用键

| 键 | 作用 |
|---|---|
| `Ctrl+C` | 复制 |
| `Ctrl+S` | 保存 |
| `Ctrl+Z` | 撤销 |
| `滚轮` | 缩放 |
| `Esc` | 退出 |

## 注意

- `copy-command` 是 `wl-copy`，来自 `wl-clipboard` 包（核心包里已有）。
- 中文字体靠 `fallback` 链，`Roboto` 本身没有中文；想换主字体直接改 `font.family`。
- 标注工具的选择在工具栏里，`initial-tool` 只决定打开时的默认项。
