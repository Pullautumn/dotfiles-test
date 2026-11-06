# Pullautumn Niri Dotfiles

Arch Linux + [niri](https://github.com/YaLTeR/niri) 的个人配置，整套用 GNU Stow 管理，附带一套模块化一键安装器。

安装器架构来自 [jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles)，配置与软件清单全部换成本仓库的 niri + waybar 方案。

## 特点

- **niri 滚动式平铺**：Wayland 原生合成器，每列纵向滚动的平铺布局，开再多窗口也不会被压成一条
- **matugen 动态配色**：从当前壁纸提取 Material You 配色，自动写进 waybar、kitty、fuzzel、GTK、Firefox
- **纯 Stow 管理**：顶层每个目录是一个独立包，`stow niri` 就能单独启用，`stow -D niri` 就能干净回滚
- **一键安装 + 断点续跑**：从裸 Arch 装到可用桌面，中断后重跑自动跳过已完成阶段
- **统一锁屏**：Quickshell 的 `lockscreen` 组件（Wayland `ext-session-lock-v1` + PAM 认证 + 可选人脸），入口 `qs-lock`；SDDM 带 lunar-glass 主题做图形登录界面

## 目录

- [包含的配置](#包含的配置)
- [从零开始安装](#从零开始安装)
  - [一键安装（推荐）](#一键安装推荐)
  - [安装脚本做了什么](#安装脚本做了什么)
  - [安装后第一次启动](#安装后第一次启动)
  - [安装选项](#安装选项)
  - [手动安装](#手动安装)
- [软件清单](#软件清单)
  - [必需软件](#必需软件)
  - [可选软件](#可选软件)
- [仓库结构](#仓库结构)
- [常见问题](#常见问题)
- [说明](#说明)
- [致谢](#致谢)

## 包含的配置

顶层每个目录就是一个 [GNU Stow](https://www.gnu.org/software/stow/) 包，目录内保持 `~` 下的相对路径。每个包的配置项、快捷键、注意事项都写在该目录下的 `README.md` 里，点表格最右列的 `README` 直接跳转。

### 窗口与桌面

| 配置 | 说明 | 部署到 | 文档 |
|---|---|---|---|
| **niri** | 合成器配置、按键绑定、`conf.d/` 分片、`scripts/` | `~/.config/niri` | [README](niri/.config/niri/README.md) |
| **waybar** | 状态栏样式与模块脚本 | `~/.config/waybar` | [README](waybar/.config/waybar/README.md) |
| **waybar-niri-Win11Like** | 备选 Win11 风格状态栏，独立目录不冲突，默认随主配置一起部署，`Mod+F3` 切换 | `~/.config/waybar-niri-Win11Like` | [README](waybar-niri-Win11Like/.config/waybar-niri-Win11Like/README.md) |
| **waybar-quickshell** | 备选 Quickshell 风格状态栏，`Mod+F4` 切换；弹窗/面板由下面的 quickshell 提供 | `~/.config/waybar-quickshell` | [README](waybar-quickshell/.config/waybar-quickshell/README.md) |
| **quickshell** | Quickshell 组件集合（通知中心、启动器、剪贴板、快捷设置，以及**锁屏** `lockscreen`），`waybar-quickshell` 的后端 | `~/.config/quickshell` | [README](quickshell/.config/quickshell/README.md) |
| **systemd** | 用户级服务单元（`qs-notifications.service`，不 enable，由切换脚本启停） | `~/.config/systemd/user` | — |
| **swaync** | 通知中心（默认方案） | `~/.config/swaync` | [README](swaync/.config/swaync/README.md) |
| **mako** | 轻量通知守护（备用方案） | `~/.config/mako` | [README](mako/.config/mako/README.md) |
| **fuzzel** | 应用启动器 | `~/.config/fuzzel` | [README](fuzzel/.config/fuzzel/README.md) |
| **rofi** | 应用启动器 / dmenu 模式 | `~/.config/rofi` | [README](rofi/.config/rofi/README.md) |
| **wlogout** | 电源菜单 | `~/.config/wlogout` | [README](wlogout/.config/wlogout/README.md) |
| **obs-studio** | 录屏与直播 | `~/.config/obs-studio` | [README](obs-studio/.config/obs-studio/README.md) |
| **xdg-desktop-portal** | 门户配置（截图 / 录屏走 gnome 后端） | `~/.config/xdg-desktop-portal` | [README](xdg-desktop-portal/.config/xdg-desktop-portal/README.md) |

### 终端与 Shell

| 配置 | 说明 | 部署到 | 文档 |
|---|---|---|---|
| **kitty** | 终端模拟器 | `~/.config/kitty` | [README](kitty/.config/kitty/README.md) |
| **starship** | 提示符 | `~/.config/starship.toml` | [README](starship/.config/starship/README.md) |
| **zsh** | Zsh 配置与插件 | `~/.config/zsh` | [README](zsh/.config/zsh/README.md) |
| **zshenv** | 指向 `ZDOTDIR` 的环境文件 | `~/.zshenv` | [README](zshenv/README.md) |
| **btop** | 系统监控 | `~/.config/btop` | [README](btop/.config/btop/README.md) |
| **fastfetch** | 系统信息 | `~/.config/fastfetch` | [README](fastfetch/.config/fastfetch/README.md) |

### 应用

| 配置 | 说明 | 部署到 | 文档 |
|---|---|---|---|
| **nvim** | Neovim + LazyVim | `~/.config/nvim` | [README](nvim/.config/nvim/README.md) |
| **yazi** | 终端文件管理器 | `~/.config/yazi` | [README](yazi/.config/yazi/README.md) |
| **mpv** | 播放器配置与脚本 | `~/.config/mpv` | [README](mpv/.config/mpv/README.md) |
| **Thunar** | 图形文件管理器 | `~/.config/Thunar` | [README](Thunar/.config/Thunar/README.md) |

### 主题与外观

| 配置 | 说明 | 部署到 | 文档 |
|---|---|---|---|
| **matugen** | 配色模板与生成脚本 | `~/.config/matugen` | [README](matugen/.config/matugen/README.md) |
| **waypaper** | 图形化壁纸切换 | `~/.config/waypaper` | [README](waypaper/.config/waypaper/README.md) |
| **fontconfig** | 字体优先级 | `~/.config/fontconfig` | [README](fontconfig/.config/fontconfig/README.md) |
| **gtk-3.0** | GTK 主题、配色与书签 | `~/.config/gtk-3.0` | [README](gtk-3.0/.config/gtk-3.0/README.md) |
| **environment.d** | 会话级环境变量（输入法、缩放等） | `~/.config/environment.d` | [README](environment.d/.config/environment.d/README.md) |
| **sddm-theme** | SDDM 登录主题 lunar-glass（**不是 stow 包**，`setup_sddm` 拷到系统目录） | `/usr/share/sddm/themes/lunar-glass` | [README](sddm-theme/README.md) |

### 输入法与杂项

| 配置 | 说明 | 部署到 | 文档 |
|---|---|---|---|
| **fcitx5** | 输入法配置（含 Rime） | `~/.config/fcitx5` | [README](fcitx5/.config/fcitx5/README.md) |
| **local-share-fcitx5** | 输入法皮肤与词库 | `~/.local/share/fcitx5` | [README](local-share-fcitx5/.local/share/fcitx5/README.md) |
| **local-share-applications** | 自定义 .desktop | `~/.local/share/applications` | [README](local-share-applications/.local/share/applications/README.md) |
| **mimeapps** | 默认打开方式，用**绝对路径**链接，避免被写穿 | `~/.config/mimeapps.list` | [README](mimeapps/README.md) |
| **scripts** | 通用脚本 | `~/.config/scripts` | [README](scripts/.config/scripts/README.md) |
| **local-bin** | 命令入口，已由 `setup_bash_path` 加进 PATH | `~/.local/bin` | [README](local-bin/.local/bin/README.md) |

> `tlpui/` 目录存在于仓库中，但没列入安装器的部署清单，需要时手动 `stow tlpui`（[README](tlpui/README.md)）。

## 从零开始安装

适用于刚用 `archinstall` 装好 Arch、还没有桌面环境的系统。**以普通用户执行**，不要用 root。

### 一键安装（推荐）

```bash
git clone https://github.com/Pullautumn/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

也可以直接跑（会自动克隆到 `~/.dotfiles`）：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pullautumn/dotfiles/main/install.sh)"
```

装到一半中断不要紧，重新执行会从断点继续。日志在 `~/.local/state/pullautumn/install-*.log`。

### 安装脚本做了什么

| 阶段 | 函数 | 作用 |
|---|---|---|
| Pre-Flight | `check_system` | 校验 Arch、非 root、pacman 可用、有网络 |
| Phase 1 | `install_base` | `pacman -Syu`，装 `git` `stow` `base-devel` |
| Phase 2 | `install_aur_helper` | 加 archlinuxcn 源，装 `paru`（已有 paru/yay 则直接复用） |
| Phase 3 | `clone_dotfiles` | 本地运行时直接用当前目录，否则克隆到 `~/.dotfiles` |
| Phase 4 | `install_packages` | 按 20 个包组装 90 个仓库包 |
| Phase 4b | 同上 | 装 7 个必需 AUR 包（逐包显示进度，不询问） |
| Phase 4c | `install_optional_packages` | 读 `common-applist.txt`，fzf 勾选后按 repo / AUR / flatpak 分类安装 |
| Phase 5 | `apply_dotfiles` | 备份旧配置 → 逐包 stow → 壁纸链接 → 脚本权限 → 生成 GTK 书签 → flatpak 主题放行 |
| Phase 6a | `setup_nvim` | 装 Neovim，`Lazy! sync` 拉齐插件，可选装 LSP 依赖 |
| Phase 6b | `setup_zsh` | 装 Zsh，可选 `chsh` 改默认 shell |
| Phase 6c | `setup_mpv` | 装 MPV，可选下载 Anime4K 着色器 |
| Phase 6d | `setup_yazi` | 装 Yazi 与预览依赖，`ya pkg install` 装插件 |
| Phase 7a | `setup_locale` | 生成 `en_US.UTF-8` 与 `zh_CN.UTF-8` |
| Phase 7b | `setup_bash_path` | 把 `~/.local/bin` 加进 PATH |
| Phase 7c | `setup_local_bin` | 给 `~/.local/bin` 与各 `scripts/` 里的脚本加执行权限 |
| Phase 7d | `setup_qs_lock_pam` | 创建 `/etc/pam.d/qs-lock`（缺 howdy 时会询问是否安装，有 howdy 再加 `qs-lock-face` 并自动探测 PAM 模块），否则锁屏无法验证密码 |
| Phase 7e | `setup_quickshell` | 兜底 `Theme.js`、`uv sync` 装 Quickshell 依赖、注册（不启用）`qs-notifications.service` |
| Phase 8 | `setup_matugen` | 用当前壁纸生成一次 Material You 配色 |
| Phase 8b | `setup_desktop_tweaks` | 默认终端、窗口按钮、i2c 权限等桌面细节 |
| Phase 9 | `enable_services` | 启用 NetworkManager、蓝牙、swayosd |
| Phase 9b | `setup_sddm` | 装 SDDM + lunar-glass 主题，写 `/etc/sddm.conf.d/10-lunar-glass.conf`，`enable` 但不 `start`（可跳过） |
| Phase 10 | `setup_user_dirs` | 建 `~/Pictures/Wallpapers` 等用户目录 |
| 收尾 | `show_completion` | 汇总结果，倒计时重启 |

### 安装后第一次启动

1. 重启，在 SDDM 的 lunar-glass 登录界面输入用户名密码，自动进入 niri
2. 换壁纸：`waypaper`（选完会自动跑 matugen 重新配色）
3. 配输入法：`fcitx5-configtool`
4. 显示器特殊的话，改 `~/.config/niri/conf.d/output.kdl`
5. 试一下锁屏：`Mod+Alt+L`（3 秒后进真锁屏，输密码解锁；装了 howdy 还可以点头像走人脸，
   配置步骤见下一节「人脸识别解锁」）

如果没装 SDDM，从 TTY 手动启动：

```bash
niri-session
```

### 人脸识别解锁（可选）

锁屏（`qs-lock`）支持 howdy 人脸识别，但**默认不装**：howdy 在 AUR，依赖 `python-dlib` / `opencv`
需要编译，而且只有红外摄像头识别率才可靠（普通 RGB 摄像头误识率明显偏高）。

**① 安装 howdy**

三个入口任选一个：

- 安装器「可选软件」阶段勾选 `howdy`（在系统工具组末尾）
- 运行到 `setup_qs_lock_pam` 时会问一次（`--yes` 无人值守模式不问）
- 手动装：`paru -S howdy`（或 `yay -S howdy`）

**② 配置摄像头并录脸**

```bash
sudo howdy config     # 改 device_path，通常是 /dev/video0；笔记本 IR 摄像头常见 /dev/video2
sudo howdy test       # 先确认能认出你，再进行下一步
sudo howdy add        # 录入人脸，可以多录几张提高成功率
```

**③ 确认 PAM 模块（关键）**

howdy 的 PAM 接法有两种，取决于打包方式，写错就会出现「人脸永远失败、界面只显示识别失败」：

```bash
ls -l /usr/lib/security/pam_howdy.so    # A. 自带 C 模块
ls -l /lib/security/howdy/pam.py        # B. Python 桥
```

安装器的 `setup_qs_lock_pam` 会自动探测并生成 `/etc/pam.d/qs-lock-face`。这两个模块都不存在，
就说明 howdy 装了但打包不完整，人脸不可能工作——先解决这个再谈其他。

**④ 怎么触发**

| 方式 | 操作 |
|---|---|
| 手动 | 锁屏界面点一下头像 |
| 锁屏时立刻识脸 | `qs-lock --face`，或 `LOCK_FACE_ON_START=1 qs-lock` |
| 合盖/休眠唤醒后 | 已内置：`swayidle.sh` 的 `after-resume` 就是 `qs-lock --face` |

**⑤ 排查**

- 一直「人脸识别失败，点击重试」→ 先跑 `sudo howdy test`，再核对 ③ 的模块名
- 不用担心锁死：人脸走 `/etc/pam.d/qs-lock-face`，密码走 `/etc/pam.d/qs-lock`，是两个独立的
  PAM service，人脸失败不影响输密码
- 想彻底关掉：删掉 `/etc/pam.d/qs-lock-face`，**同时**把 `swayidle.sh` 里 `WAKE_CMD` 的
  `qs-lock --face` 改成 `qs-lock`，否则每次唤醒都会弹一次识别失败

### 安装选项

| 参数 | 说明 |
|---|---|
| `--minimal` | 只装核心，跳过可选软件与 flatpak |
| `--no-stow` | 只装软件，不部署配置 |
| `--yes` | 全程自动确认，可选软件按清单全部安装，不弹任何询问 |
| `--no-reboot` | 装完不自动重启 |
| `--reset` | 清空进度记录，从头开始 |
| `--help` | 显示帮助 |

### 手动安装

不想用脚本时，按下面来。

**① 基础工具**

```bash
sudo pacman -S --needed git stow base-devel
# AUR helper（推荐 paru；也可以 yay）
sudo pacman -S --needed paru
```

**② 克隆仓库**

```bash
git clone https://github.com/Pullautumn/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**③ 装包**

```bash
# 必需仓库包（20 组）
paru -S --needed \
    niri xwayland-satellite awww swayidle swayosd polkit-gnome \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    waybar fuzzel rofi swaync libnotify \
    wlogout grim slurp wayfreeze wf-recorder imv ffmpeg \
    cliphist wl-clipboard xclip kitty starship \
    zsh atuin zoxide fzf thefuck fnm \
    thunar thunar-volman thunar-archive-plugin tumbler gvfs gvfs-mtp gvfs-smb \
    ffmpegthumbnailer poppler-glib file-roller webp-pixbuf-loader gnome-keyring \
    fcitx5 fcitx5-im fcitx5-chinese-addons \
    pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol playerctl \
    networkmanager network-manager-applet nm-connection-editor bluez bluez-utils blueman \
    ripgrep fd bat eza jq curl wget unzip bc duf fastfetch prettyping \
    pacman-contrib unarchiver lazygit lazydocker btop \
    noto-fonts-cjk ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd \
    python python-pip nodejs npm mpv yazi brightnessctl wlsunset \
    google-chrome firefox

# 必需附加包（12 个，交给 paru：AUR 包 + 已在官方仓库的 matugen/quickshell）
paru -S --needed \
    matugen waypaper-git python-pywalfox \
    ttf-jetbrains-maple-mono-nf-xx-xx ttf-lxgw-wenkai-screen \
    niri-sidebar-git wl-screenrec-git \
    quickshell uv zsh-patina \
    mark-shot wayscrollshot-bin
```

**④ 部署配置**

```bash
cd ~/dotfiles
stow -d ~/dotfiles -t ~ -R niri waybar waybar-niri-Win11Like waybar-quickshell \
    quickshell systemd fuzzel rofi wlogout mako swaync \
    kitty starship zsh zshenv nvim yazi mpv obs-studio \
    Thunar btop fastfetch fcitx5 fontconfig environment.d gtk-3.0 \
    matugen scripts local-bin waypaper xdg-desktop-portal \
    local-share-applications local-share-fcitx5

# mimeapps 单独做成绝对路径链接（桌面环境会写这个文件）
ln -sfn ~/dotfiles/mimeapps/.config/mimeapps.list ~/.config/mimeapps.list
```

**⑤ 壁纸与脚本权限**

```bash
mkdir -p ~/Pictures
ln -sfn ~/dotfiles/wallpaper/Pictures/Wallpapers ~/Pictures/Wallpapers
find -L ~/.local/bin ~/.config/scripts ~/.config/niri/scripts \
     ~/.config/waybar/scripts ~/.config/waybar-quickshell/scripts \
     ~/.config/matugen/scripts \
     -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
# 无后缀脚本（qs-lock、niri-binds、cliphist-fuzzel-img、rofi 的 launcher_tN 等）
# 认首行 shebang，不靠文件名白名单
for d in ~/.local/bin ~/.config/scripts ~/.config/niri/scripts \
         ~/.config/waybar/scripts ~/.config/waybar-quickshell/scripts \
         ~/.config/matugen/scripts ~/.config/rofi; do
    find -L "$d" -type f ! -name "*.*" \
         -exec sh -c 'head -c2 "$1" | grep -q "^#!" && chmod +x "$1"' _ {} \;
done
```

**⑤b Quickshell 的 Python 依赖（用 `Mod+F4` 才需要）**

```bash
cd ~/.config/quickshell && uv sync
systemctl --user daemon-reload
```

**⑥ 家目录路径（基本不用管了）**

配置里能自解析的都已改成 `~` / `$HOME` / `vim.fn.expand`，不再需要批量替换用户名。
只剩两处例外：

1. **GTK 书签** `~/.config/gtk-3.0/bookmarks` —— GTK 只认绝对 `file://` URI，不支持 `~`。
   仓库里不再放这个文件，安装器会按当前 `$HOME` 现生成；手动装不生成也行，GTK 会自己写一份默认的。
2. **niri 截图路径** —— `~/.config/niri/conf.d/environment.kdl` 的 `screenshot-path`
   只接受绝对路径，装完自己改一下：

```bash
sed -i "s|/home/pullautumn|$HOME|g" ~/.config/niri/conf.d/environment.kdl
mkdir -p ~/Pictures/Screenshots
```

> ⚠️ 别再对整个 `~/.config` 跑 `sed -i`。stow 会把多数包目录折叠成指向 `~/dotfiles`
> 的软链，改 `~/.config` 下的文件等于直接改写仓库 —— `git status` 会变脏，
> `git pull` 会冲突，`pullautumn-screenrec` 这类标识符也会被一起改掉。

**⑦ 系统服务与登录**

```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable sddm           # 用 SDDM 作为登录入口（lunar-glass 主题）
```

## 软件清单

清单维护在两个地方，改这两个文件就够，不用动脚本：

- 必需软件 → `setup/lib/config.sh` 的 `PKG_GROUPS` / `AUR_PACKAGES`
- 可选软件 → `setup/common-applist.txt`（装到 Phase 4c 时 fzf 勾选）

### 必需软件

**仓库包（90 个，20 组，按组安装失败不影响其他组）**

| 组 | 包 |
|---|---|
| 窗口管理 | `niri` `xwayland-satellite` `awww` `swayidle` `swayosd` `polkit-gnome` |
| 桌面门户 | `xdg-desktop-portal` `xdg-desktop-portal-gtk` `xdg-desktop-portal-gnome` |
| 状态栏 | `waybar` |
| 启动器 | `fuzzel` `rofi` |
| 通知 | `swaync` `libnotify` |
| 锁屏 | `quickshell`（lockscreen 组件，入口 `qs-lock`） |
| 电源菜单 | `wlogout` |
| 截图录屏 | `grim` `slurp` `wayfreeze` `wf-recorder` `imv` `ffmpeg` |
| 剪贴板 | `cliphist` `wl-clipboard` `xclip` |
| 终端 | `kitty` `starship` |
| Shell | `zsh` `atuin` `zoxide` `fzf` `thefuck` `fnm` |
| 文件管理 | `thunar` `thunar-volman` `thunar-archive-plugin` `tumbler` `gvfs` `gvfs-mtp` `gvfs-smb` `ffmpegthumbnailer` `poppler-glib` `file-roller` `webp-pixbuf-loader` `gnome-keyring` |
| 输入法 | `fcitx5` `fcitx5-im` `fcitx5-chinese-addons` |
| 音频 | `pipewire` `wireplumber` `pipewire-pulse` `pipewire-alsa` `pavucontrol` `playerctl` |
| 网络与蓝牙 | `networkmanager` `network-manager-applet` `nm-connection-editor` `bluez` `bluez-utils` `blueman` |
| 命令行工具 | `ripgrep` `fd` `bat` `eza` `jq` `curl` `wget` `unzip` `bc` `duf` `fastfetch` `prettyping` `pacman-contrib` `unarchiver` `lazygit` `lazydocker` `btop` |
| 字体 | `noto-fonts-cjk` `ttf-jetbrains-mono-nerd` `ttf-cascadia-code-nerd` |
| 开发环境 | `python` `python-pip` `nodejs` `npm` |
| 媒体 | `mpv` `yazi` |
| 亮度色温 | `brightnessctl` `wlsunset` |
| 浏览器 | `google-chrome` `firefox` |

**附加包（12 个，配置直接依赖）**

| 包 | 用途 |
|---|---|
| [`matugen`](matugen/.config/matugen/README.md) | Material You 配色生成 |
| `waypaper-git` | 图形化壁纸切换 |
| `python-pywalfox` | Firefox 跟随系统配色 |
| `ttf-jetbrains-maple-mono-nf-xx-xx` | Maple Mono NF 字体（终端 / 编辑器） |
| `ttf-lxgw-wenkai-screen` | 霞鹜文楷屏幕版（中文正文字体） |
| `niri-sidebar-git` | niri 侧边栏 |
| `wl-screenrec-git` | Wayland 录屏 |
| `quickshell` | Quickshell 本体（通知 / 锁屏 / 截图工具箱） |
| `uv` | Quickshell 组件的 Python 依赖管理 |
| `zsh-patina` | zsh 语法高亮 |
| `mark-shot` | 选区截图标注（`Alt+Ctrl+S`） |
| `wayscrollshot-bin` | 滚动长截图（状态栏中键） |

**几个"看着像可选、其实不能删"的依赖**

| 包 | 为什么必需 |
|---|---|
| `xdg-desktop-portal-gnome` | `niri-portals.conf` 里 `ScreenCast` / `Screenshot` 都指向 gnome 后端，截图录屏靠它 |
| `gnome-keyring` | 同一份配置里 `Secret=gnome-keyring`，应用存密码靠它 |
| `polkit-gnome` | `niri/conf.d/autostart.kdl` 会 spawn 认证代理，没有它图形提权弹不出窗口 |

### 可选软件

安装到 Phase 4c 时会弹出 fzf 列表：`Tab` / `Shift-Tab` 多选、`Enter` 确认、`Esc` 全部跳过。共 28 项：

| 分类 | 软件 |
|---|---|
| 通讯与社交 | QQ、微信、`localsend`（局域网传文件） |
| 开发与网络 | VS Code、`sparkle-bin`（代理客户端） |
| 系统工具 | `mission-center` 任务管理器、`baobab` 磁盘分析、`gnome-disk-utility` 分区、`gnome-font-viewer`、`nwg-look` GTK 主题、`flatseal`、`bazaar` Flatpak 商店、`ddcutil` + `ddcutil-service` 外接屏亮度 |
| 媒体与创作 | `obs-studio`、`easyeffects` 音频效果器、`pinapp` .desktop 编辑器、`gearlever` AppImage 管理器 |
| 虚拟化 | `virt-manager`、`qemu-full`、`libvirt`、`edk2-ovmf`、`swtpm`（Win11 虚拟机需要） |
| 办公 | `libreoffice-fresh` |
| 命令行增强 | `strace`、`downgrade`、`bat-extras`、`clipnotify` |

> `--minimal` 会整段跳过；`--yes` 不弹界面、把清单里 **28 项全部装上**。清单里带 `AUR:` 前缀的走 AUR，带 `flatpak:` 的走 Flatpak（此时才会按需装 flatpak 与 flathub 源），无前缀的走官方仓库。

## 仓库结构

```
niri/.config/niri/...            →  ~/.config/niri/...
waybar/.config/waybar/...        →  ~/.config/waybar/...
zsh/.config/zsh/...              →  ~/.config/zsh/...
zshenv/.zshenv                   →  ~/.zshenv
local-bin/.local/bin/...         →  ~/.local/bin/...
scripts/.config/scripts/...      →  ~/.config/scripts/...

setup/                           安装器本体（不是 stow 包）
wallpaper/Pictures/Wallpapers/   壁纸，安装时链接到 ~/Pictures/Wallpapers
wallpapers/                      头像等杂项资源，不部署
mainfest.txt                     包名与目标路径的对照表，供 to_stow.sh 使用
```

安装器的目录结构、阶段划分、如何加新步骤见 [setup/README.md](setup/README.md)。

### 脚本放哪儿

脚本分三层，新加脚本先对号入座（完整说明见
[scripts/README.md](scripts/.config/scripts/README.md)）：

| 层 | 位置 | 判据 |
|---|---|---|
| PATH 命令 | `~/.local/bin` | 要手敲、被多个组件按名调用、或作为系统入口 |
| 跨组件流程 | `~/.config/scripts` | 调用方 ≥2 个组件，只在图形会话里用 |
| 组件私有 | 各组件的 `scripts/` | 只有它自己的配置 / 主题 / QML 调用 |

一句话：**生命周期跟谁绑定就放谁的目录；出现第二个调用方，升级到共享层。**

`rofi` 的 `launcher_tN`、`mpv` 的 lua、quickshell 各组件里的 helper 属于硬约束，
必须留在自己目录，不要往共享层搬。

## 聚合脚本

`to_stow.sh` 用来把系统里已有的配置反向收进仓库，按 `mainfest.txt` 的对照关系复制到 `~/.dotfiles`：

```bash
./to_stow.sh mainfest.txt
```

`mainfest.txt` 每行一个映射，格式为 `目标名称:源路径`，例如：

```
niri:~/.config/niri
waybar:~/.config/waybar
```

空行之后的条目会用 `sudo` 复制，用于 `/etc` 这类需要提权的文件；源路径支持通配符。输出目录固定为 `~/.dotfiles`，与 `install.sh` 克隆的位置一致。

## 常见问题

**状态栏图标显示成方块**

Nerd Font 没装上或没生效：

```bash
paru -S ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
fc-cache -fv
```

**中文输入法打不出字**

先确认 fcitx5 在跑（`pgrep -a fcitx5`），再看环境变量，配置里的 `environment.d` 已设置：

```bash
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

**壁纸没了 / waypaper 打不开壁纸目录**

检查链接是否还在：

```bash
ls -l ~/Pictures/Wallpapers
# 断了就重建
ln -sfn ~/dotfiles/wallpaper/Pictures/Wallpapers ~/Pictures/Wallpapers
```

**重启后没有图形登录界面**

SDDM 没启用，或者装的时候跳过了：

```bash
sudo systemctl enable --now sddm
# 或者不装 SDDM，从 TTY 手动起桌面
niri-session
```

**SDDM 黑屏 / 卡在登录界面进不去**

用 `Ctrl+Alt+F2` 切到 TTY 先救回来：

```bash
sudo systemctl disable sddm
sudo systemctl enable --now ly@tty1     # 之前装过 ly 的话
# 没有 ly 就直接
niri-session
```

大概率是 greeter 的合成器起不来：编辑 `/etc/sddm.conf.d/10-lunar-glass.conf`，
把 `CompositorCommand=kwin_wayland ...` 换成 `weston --shell=kiosk`（装 `weston`），
或者整段删掉让 SDDM 退回 X11 greeter（需要 `xorg-server` `xorg-xauth`）。

**锁屏输密码一直失败**

`/etc/pam.d/qs-lock` 没建。装的是 `quickshell`（不带 PAM 支持）时也会这样：

```bash
pacman -Ql quickshell | grep -i 'Services/Pam'   # 没有输出就是不带
# 需要带 PAM 的版本
paru -S quickshell-git
```

**改了用户名，配置里还是旧路径**

配置本身已经不含用户名了（都用 `~` / `$HOME`），剩下要自己看一眼的只有
[第 ⑥ 步](#手动安装)列的那两处：GTK 书签由安装器按 `$HOME` 现生成，
niri 的 `environment.kdl` 截图路径装完会提示你改。

**显示器布局不对 / 只有一个屏亮**

编辑 `~/.config/niri/conf.d/output.kdl`，把输出名改成 `niri msg outputs` 里看到的实际名字。

**配色没生成，waybar 报错缺颜色文件**

matugen 至少需要跑一次：

```bash
waypaper                                    # 选张壁纸，会自动触发
# 或者直接生成
matugen image ~/Pictures/Wallpapers/xxx.jpg
```

**可选软件勾选时按了 Esc 或直接回车**

视为一项都不装，安装流程继续往下走。想重来就重跑安装器（已完成阶段会跳过，只重新弹可选软件与 4b）。若终端里找不到 fzf 或没有可用 TTY，这一阶段会打印提示并跳过，全程无人值守请直接用 `--yes`。

## 说明

- **必需软件**写在 `setup/lib/config.sh`，可选软件写在 `setup/common-applist.txt`，`setup/niri-applist.txt` 是整理时的原始参考清单，安装器不读取。
- **家目录路径**：能自解析的配置都已写成 `~` / `$HOME` / `vim.fn.expand`，装到任何用户名下都成立。只有 GTK 书签（必须绝对 `file://` URI）由安装器按 `$HOME` 现生成，niri 的 `screenshot-path` 只提示不代改。安装器**不会**再对 `~/.config` 做批量 `sed` —— stow 会把目录折叠成软链，那样改等于直接改写仓库。
- **备份**：部署前会把 `~/.config` 下的同名目录移到 `~/.config-backup-<时间戳>`，不会直接删除。`~/.local/bin` 这类共享目录交给 stow 合并，不整体搬走。
- **`waybar-niri-Win11Like`** 部署到 `~/.config/waybar-niri-Win11Like`，与主 waybar 互不影响，两套样式都会装好，用 `Mod+F2`（主样式）/ `Mod+F3`（Win11 风格）随时切换。
- **`waybar-quickshell`** 部署到 `~/.config/waybar-quickshell`，形态与上一套相同，但它的弹窗、面板、启动器、剪贴板全部由 `~/.config/quickshell` 里的 QML 组件提供。三套样式统一用 `~/.config/scripts/switch-waybar.sh` 切换（`Mod+F2`/`F3`/`F4`），切换时会连带切换通知后端：Quickshell 样式用 `qs-notifications.service`，另两套用 `swaync`。两者都要独占 D-Bus 的 `org.freedesktop.Notifications`，所以不能同时运行。剪贴板不需要切换，Quickshell 的 clipboard 组件读的就是同一个 `cliphist` 数据库。
- **断点续跑**：进度记在 `~/.pullautumn_install_progress`，`--reset` 可清空。

## 致谢

- 安装器架构：[jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles)
- 大量 Arch 配置经验参考：[ShorinArchExperience](https://github.com/SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide/wiki)
