# fontconfig

字体匹配规则。决定「sans-serif / serif / monospace 到底用哪个字体」，中文回退顺序和渲染参数都靠它。

部署到 `~/.config/fontconfig`。

## 文件

| 文件 | 说明 |
|---|---|
| `fonts.conf` | 三条字体回退链 + 渲染参数 |

## 三条回退链

**sans-serif**（界面正文字体）

```
Noto Sans → Noto Sans CJK SC → Adwaita Sans → Liberation Sans → WenQuanYi Zen Hei
```

最后那个 `WenQuanYi Zen Hei` 是中文兜底：前几个 CJK 字体都缺字时才会用到。

**serif**（衬线）

```
Noto Serif → Noto Serif CJK SC → Liberation Serif
```

**monospace**（等宽）

```
JetBrains Maple Mono → JetBrains Mono → Adwaita Mono
```

排第一的 `JetBrains Maple Mono` 就是 kitty 用的那款，来自 AUR 包 `ttf-jetbrains-maple-mono-nf-xx-xx`。

## 渲染参数

| 项 | 值 | 含义 |
|---|---|---|
| `antialias` | `true` | 抗锯齿 |
| `hinting` | `true` | 开启字形微调 |
| `hintstyle` | `hintslight` | 轻微微调，中文小字号最耐看的档位 |
| `rgba` | `rgb` | 次像素渲染顺序（普通 RGB 排列显示器） |
| `lcdfilter` | `lcddefault` | 次像素滤波，让细体更清晰 |

## 生效

```bash
fc-cache -fv                       # 重建字体缓存
fc-match sans-serif                # 看 sans-serif 实际匹配到谁
fc-match "sans-serif:lang=zh-cn"   # 看中文匹配结果
fc-match monospace                 # 看等宽匹配结果
```

改完不需要重启会话。

## 依赖字体

| 包 | 用途 |
|---|---|
| `noto-fonts-cjk` | 中文正文（思源系） |
| `ttf-jetbrains-mono-nerd` | 等宽 + Nerd Font 图标 |
| `ttf-cascadia-code-nerd` | waybar 用的等宽 |
| `ttf-jetbrains-maple-mono-nf-xx-xx` | kitty 主字体（AUR） |
| `ttf-lxgw-wenkai-screen` | 霞鹜文楷屏幕版（AUR） |

## 注意

- `rgba=rgb` 是按普通 RGB 排布写的。用 BGR 排布的显示器（部分 Dell / 老款笔记本）字会带彩边，改成 `bgr`。
- 图标显示成方块时，先 `fc-match "JetBrainsMono Nerd Font"` 确认字体名，再怀疑这里。
- `hintslight` 在高 DPI 屏上可能偏细，想更锐利改 `hintfull`。
- 这里没配 Emoji 字体，Emoji 走系统默认的 `noto-fonts-emoji`（如果装了）。
