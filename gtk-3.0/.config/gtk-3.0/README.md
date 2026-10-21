# gtk-3.0

GTK3 程序的全局外观：主题、图标、字体、光标，以及文件对话框的侧边栏书签。

部署到 `~/.config/gtk-3.0`。

## 文件

| 文件 | 说明 |
|---|---|
| `settings.ini` | GTK3 主题、图标主题、字体、光标、工具栏样式、抗锯齿 |
| `colors.css` | 由 matugen 生成，覆盖主题配色 |
| `bookmarks` | 文件对话框左侧的书签条目 |

## settings.ini 关键项

| 项 | 值 | 含义 |
|---|---|---|
| `gtk-theme-name` | `Adwaita` | 基础主题 |
| `gtk-icon-theme-name` | `Tokyonight-Moon` | 图标主题 |
| `gtk-font-name` | `Adwaita Sans 11` | 界面字体与字号 |
| `gtk-cursor-theme-name` | `Adwaita` | 光标主题 |
| `gtk-cursor-theme-size` | 24 | 光标大小 |
| `gtk-toolbar-style` | `GTK_TOOLBAR_ICONS` | 工具栏只显示图标 |
| `gtk-button-images` / `gtk-menu-images` | 0 | 按钮和菜单不显示图标 |
| `gtk-enable-event-sounds` | 1 | 开启事件音效 |
| `gtk-enable-input-feedback-sounds` | 0 | 关闭输入反馈音 |
| `gtk-xft-antialias` / `gtk-xft-hinting` | 1 / 1 | 抗锯齿与微调 |

## 书签

`bookmarks` 是 GTK 文件对话框左侧的快捷入口（Thunar、GTK 打开/保存对话框都会用）：

```
file:///home/<user>/Downloads Downloads
file:///home/<user>/Pictures  Pictures
```

改完立即生效，不需要重启应用。

## 配色

matugen 的 `gtk3` 模板会写 `~/.config/gtk-3.0/colors.css`，GTK 应用启动时读取它覆盖主题色。也就是说**换个壁纸，GTK 程序的主色就变了**。

## 注意

- `Tokyonight-Moon` 图标主题需要单独安装（`tokyonight-gtk-theme` 之类的包），没装会自动回落到 Adwaita，不会报错。
- `gtk-4.0` 目录不在本仓库里，但 matugen 会往 `~/.config/gtk-4.0/colors.css` 写配色；想让 GTK4 程序也跟随，自己建个目录放一份 `gtk.css` 引用它。
- Flatpak 应用默认读不到 `~/.config/gtk-3.0`，安装器 Phase 5 已给 flatpak 放行 `xdg-config/gtk-3.0` 等路径。
