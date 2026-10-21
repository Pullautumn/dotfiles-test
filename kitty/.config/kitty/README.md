# kitty

终端模拟器，GPU 加速，日常 `Mod+Return` 打开的就是它。

部署到 `~/.config/kitty`。

## 文件

| 文件 | 说明 |
|---|---|
| `kitty.conf` | 字体、透明度、标签页键位、滚动缓冲、鼠标映射 |
| `colors.conf` | Catppuccin Mocha 配色，`include` 进主配置 |
| `themes/matugen.conf` | 换壁纸后 matugen 生成的配色，用 `themes` 命令切换 |

## 关键配置

| 项 | 值 | 含义 |
|---|---|---|
| `font_family` | `JetBrainsMapleMono` | 主字体（AUR 的 Maple Mono NF） |
| `bold/italic` | `JetBrainsMapleMono-Bold/Italic` | 粗体与斜体 |
| `disable_ligatures` | `always` | **关闭连字**，代码里 `!=` `=>` 保持原样 |
| `background_opacity` | 0.85 | 背景 85% 不透明 |
| `window_padding_width` | 2 | 窗口内边距 |
| `scrollback_lines` | 200000 | 20 万行历史 |
| `listen_on` | `unix:/tmp/kitty-$USER` | 开启远程控制 socket，供 `kitty @` 使用 |
| `shell_integration` | `enabled` | shell 集成（跳转提示符、标记） |
| `enabled_layouts` | `splits` | 只启用分屏布局 |
| `cursor_trail` | 3 | 光标拖尾 |
| `mouse_map middle press` | `copy_to_clipboard` | 中键选中即复制 |

## 标签页键位

| 快捷键 | 作用 |
|---|---|
| `Alt+Shift+T` | 在当前目录开新标签 |
| `Alt+Shift+[` / `]` | 上一个 / 下一个标签 |
| `Alt+Shift+Q` | 关闭标签 |
| `Alt+Shift+R` | 重命名标签 |
| `Alt+Shift+←` / `→` | 标签左移 / 右移 |

## 换主题

```bash
kitty +kitten themes                    # 交互式选择
kitty +kitten themes --reload-in=all matugen   # 切到 matugen 生成的配色
kitty @ set-colors --all ~/.config/kitty/themes/matugen.conf  # 立即生效
```

matugen 的 `post_hook` 里已经写了自动 reload，换壁纸时配色会跟着变。

## 注意

- `JetBrainsMapleMono` 来自 AUR 的 `ttf-jetbrains-maple-mono-nf-xx-xx`，没装的话字体会回退成系统等宽字体。
- `listen_on` 用的是 `/tmp` 下的 socket，多用户机器上其他人理论上能 `kitty @` 控制你的终端，介意就注释掉。
