# gtk-3.0

GTK3 程序的全局外观：主题、图标、字体、光标，以及文件对话框的侧边栏书签。

部署到 `~/.config/gtk-3.0`。

## 文件

| 文件 | 说明 |
|---|---|
| `settings.ini` | GTK3 主题、图标主题、字体、光标、工具栏样式、抗锯齿 |
| `colors.css` | 由 matugen 生成，覆盖主题配色 |
| `bookmarks` | 文件对话框 / Nautilus 侧边栏的书签条目。**安装时按 `$HOME` 生成，不在仓库里**（见下节） |

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

`bookmarks` 决定 **Nautilus 侧边栏**（以及 GTK 打开/保存对话框、Thunar 侧栏）里「固定」着哪些目录：

```
file:///home/wq/.dotfiles dotfiles
file:///home/wq/Downloads Downloads
file:///home/wq/Documents Documents
file:///home/wq/Pictures Pictures
file:///home/wq/Music Music
file:///home/wq/Videos Videos
```

- **这个文件不在仓库里**（`.gitignore` 已排除）：GTK 只认绝对 `file://` URI，不展开 `~`、
  不读环境变量，内容必然跟用户名绑定。由 `setup/steps/03-dotfiles.sh` 的
  `_dotfiles_generate_bookmarks()` 在安装时按 `$HOME` 现生成（stow 会把
  `~/.config/gtk-3.0` 整个折叠成指向仓库的软链，所以「写仓库里那份」= 写生效的那份）。
- **Nautilus 不会自动列出 `~/Downloads` / `~/Documents` 等标准目录**（实测 51.1：侧边栏
  只有 Home / Recent / Starred / Network / Trash + 书签）。所以想让这些目录出现在左侧，
  必须写进本文件。
- 标准 XDG 目录由**首次登录**的 `xdg-user-dirs-update` 创建，而书签在安装阶段生成 ——
  生成函数会先用 `xdg-user-dir` 查真实路径（本地化目录名也能对上）再 `mkdir -p` 补建，
  不依赖登录时机。早期版本只判 `[[ -d ]]` 就跳过，结果侧边栏只剩安装途中顺带建出来的
  `~/Pictures` 一项。
- `dotfiles` 一项 `~/dotfiles`（软链）和 `~/.dotfiles`（clone 的默认名）都认。
- 只有作者本人（`LEGACY_USER`）的书签会多 `~/.config`、`~/.local` 两条 —— 对普通用户
  只是噪音，还容易被误点删掉东西。想让所有人都带上，把那个 `if` 去掉即可。

改完立即生效，不需要重启应用（`GtkPlacesSidebar` 监听文件变化）。

## 配色

matugen 的 `gtk3` 模板会写 `~/.config/gtk-3.0/colors.css`，GTK 应用启动时读取它覆盖主题色。也就是说**换个壁纸，GTK 程序的主色就变了**。

## 注意

- `Tokyonight-Moon` 图标主题需要单独安装（`tokyonight-gtk-theme` 之类的包），没装会自动回落到 Adwaita，不会报错。
- `gtk-4.0` 目录不在本仓库里，但 matugen 会往 `~/.config/gtk-4.0/colors.css` 写配色；想让 GTK4 程序也跟随，自己建个目录放一份 `gtk.css` 引用它。
- Flatpak 应用默认读不到 `~/.config/gtk-3.0`，安装器 Phase 5 已给 flatpak 放行 `xdg-config/gtk-3.0` 等路径。
