# matugen

Material You 配色生成器。从当前壁纸提取主色，按模板渲染出一整套配置，写回各应用的配置目录——换壁纸就等于换整套主题。

部署到 `~/.config/matugen`。

## 工作原理

```
壁纸图片
  └─ matugen image <file> [-t scheme] [-m dark|light]
       ├─ 读取 config.toml 的 [templates.*] 列表
       ├─ 用 templates/ 里的模板渲染
       └─ 写到 output_path，并执行 post_hook（通知该应用重载）
```

## 文件

| 路径 | 说明 |
|---|---|
| `config.toml` | 模板清单：每个 `[templates.名字]` 定义 `input_path` → `output_path`，可选 `pre_hook` / `post_hook` |
| `templates/` | 模板源文件，用 matugen 的 `{{ colors.xxx }}` 语法 |
| `custom/` | 作者留存的生成结果样本（各应用配色文件副本），**config.toml 不引用**，仅供对照 |
| `scripts/inject_vscode.sh` | 把生成的配色注入 VS Code 的 `settings.json` |

## 会写到哪些地方

`config.toml` 里有 28 个输出目标：

| 应用 | 输出 |
|---|---|
| waybar | `~/.config/waybar/colors.css` |
| waybar（备选样式） | `~/.config/waybar-niri-Win11Like/colors.css` |
| niri | `~/.config/niri/conf.d/colors.kdl` |
| kitty | `~/.config/kitty/themes/matugen.conf` |
| fuzzel | `~/.config/fuzzel/colors.ini` |
| mako | `~/.config/mako/colors.conf` |
| swaync | `~/.config/swaync/colors.css` |
| swayosd | `~/.config/swayosd/colors.css` |
| wlogout | `~/.config/wlogout/colors.css` + 图标重着色脚本 |
| yazi | `~/.config/yazi/theme.toml` |
| btop | `~/.config/btop/themes/matugen.theme` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |
| obs | `~/.config/obs-studio/themes/matugen.obt` |
| fcitx5 | `~/.local/share/fcitx5/themes/Matugen/theme.conf` |
| qt5ct / qt6ct | `~/.config/qt5ct/colors/matugen.conf`、`qt6ct/colors/matugen.conf` |
| GTK3 / GTK4 | `~/.config/gtk-3.0/colors.css`、`gtk-4.0/colors.css` |
| GTK 图标 | `~/.cache/matugen/recoloricons.sh`（重着色脚本） |
| KDE 配色 | `~/.local/share/color-schemes/Matugen.colors` |
| neovim | `~/.config/nvim/generated.lua` |
| swaylock | `~/.config/swaylock/config` |
| starship | `templates/starship-colors.toml`（需手动合并） |
| pywalfox | `~/.cache/wal/colors.json`（给 Firefox 用） |

其中一部分目标（hyprland、ghostty、niriswitcher、AdwSteamGtk）在当前配置里没用上，属于"顺便生成"，不存在对应应用也不报错。

## 用法

```bash
matugen image ~/Pictures/Wallpapers/壁纸1.jpg              # 默认方案
matugen image xxx.jpg -t scheme-content -m dark            # 指定配色方案与明暗
matugen image xxx.jpg --source-color-index 2               # 从图片里挑第 2 个主色
matugen image xxx.jpg --dry-run                            # 只打印不写文件
```

`-t` 可选 `scheme-tonal-spot`（默认）、`scheme-content`、`scheme-expressive`、`scheme-fidelity`、`scheme-monochrome` 等。

## 和仓库里其他脚本的关系

```
waypaper（选壁纸）
  └─ post_command → ~/.config/scripts/matugen-update.sh $wallpaper
                        └─ 调 matugen image，再按策略决定明暗
                             └─ post_hook 让各程序重载
```

`niri/conf.d/binds.kdl` 里 `Mod+Alt+M` / `Mod+Alt+T` 调用 `matugen-select-type.sh`，用来切换配色策略（策略缓存在 `~/.cache/matugen-strategy/`）。

## 注意

- **别手改 `colors.css` / `colors.kdl` / `theme.toml` 这些生成物**，下次换壁纸就没了。要改就改 `templates/` 里对应的模板。
- `templates/` 里很多模板用了 Nerd Font 私有区字符，字体缺失时会渲染成方块。
- 首次使用至少跑一次 `matugen image 某张图`，否则 waybar、fuzzel 这些引用 `colors.*` 的配置找不到文件，会退回默认配色（不报错，只是不好看）。
- `custom/` 目录可以整删，不影响任何流程。
