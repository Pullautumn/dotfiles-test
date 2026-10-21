# Pullautumn Niri Dotfiles

Arch Linux + [niri](https://github.com/YaLTeR/niri) 的个人配置，整套用 GNU Stow 管理，附带一套模块化一键安装器。

安装器架构来自 [jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles)，配置与软件清单全部换成本仓库的 niri + waybar 方案。

## 特点

- **niri 滚动式平铺**：Wayland 原生合成器，每列纵向滚动的平铺布局，开再多窗口也不会被压成一条
- **matugen 动态配色**：从当前壁纸提取 Material You 配色，自动写进 waybar、kitty、fuzzel、GTK、Firefox
- **纯 Stow 管理**：顶层每个目录是一个独立包，`stow niri` 就能单独启用，`stow -D niri` 就能干净回滚
- **一键安装 + 断点续跑**：从裸 Arch 装到可用桌面，中断后重跑自动跳过已完成阶段
- **两套锁屏**：gtklock（走 PAM 校验密码）为主，swaylock 备用；ly 作为 TTY 图形登录入口

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

顶层每个目录就是一个 [GNU Stow](https://www.gnu.org/software/stow/) 包，目录内保持 `~` 下的相对路径。每个包的配置项、快捷键、注意事项都写在该目录下的 `README.md` 里，点包名直接跳转。

### 窗口与桌面

| 包 | 部署到 | 说明 |
|---|---|---|
| [`niri`](niri/.config/niri/README.md) | `~/.config/niri` | 合成器配置、按键绑定、`conf.d/` 分片、`scripts/` |
| [`waybar`](waybar/.config/waybar/README.md) | `~/.config/waybar` | 状态栏样式与模块脚本 |
| [`waybar-niri-Win11Like`](waybar-niri-Win11Like/.config/waybar-niri-Win11Like/README.md) | `~/.config/waybar-niri-Win11Like` | 备选 Win11 风格状态栏，独立目录不冲突，默认随主配置一起部署，`Mod+F3` 切换 |
| [`swaync`](swaync/.config/swaync/README.md) | `~/.config/swaync` | 通知中心（默认方案） |
| [`mako`](mako/.config/mako/README.md) | `~/.config/mako` | 轻量通知守护（备用方案） |
| [`fuzzel`](fuzzel/.config/fuzzel/README.md) | `~/.config/fuzzel` | 应用启动器 |
| [`rofi`](rofi/.config/rofi/README.md) | `~/.config/rofi` | 应用启动器 / dmenu 模式 |
| [`wlogout`](wlogout/.config/wlogout/README.md) | `~/.config/wlogout` | 电源菜单 |
| [`gtklock`](gtklock/.config/gtklock/README.md) | `~/.config/gtklock` | 锁屏（需 `/etc/pam.d/gtklock`，安装器会建） |
| [`swaylock`](swaylock/.config/swaylock/README.md) | `~/.config/swaylock` | 锁屏（备用） |
| [`satty`](satty/.config/satty/README.md) | `~/.config/satty` | 截图标注 |
| [`obs-studio`](obs-studio/.config/obs-studio/README.md) | `~/.config/obs-studio` | 录屏与直播 |
| [`xdg-desktop-portal`](xdg-desktop-portal/.config/xdg-desktop-portal/README.md) | `~/.config/xdg-desktop-portal` | 门户配置（截图 / 录屏走 gnome 后端） |

### 终端与 Shell

| 包 | 部署到 | 说明 |
|---|---|---|
| [`kitty`](kitty/.config/kitty/README.md) | `~/.config/kitty` | 终端模拟器 |
| [`starship`](starship/.config/starship/README.md) | `~/.config/starship.toml` | 提示符 |
| [`zsh`](zsh/.config/zsh/README.md) | `~/.config/zsh` | Zsh 配置与插件 |
| [`zshenv`](zshenv/README.md) | `~/.zshenv` | 指向 `ZDOTDIR` 的环境文件 |
| [`btop`](btop/.config/btop/README.md) | `~/.config/btop` | 系统监控 |
| [`fastfetch`](fastfetch/.config/fastfetch/README.md) | `~/.config/fastfetch` | 系统信息 |

### 应用

| 包 | 部署到 | 说明 |
|---|---|---|
| [`nvim`](nvim/.config/nvim/README.md) | `~/.config/nvim` | Neovim + LazyVim |
| [`yazi`](yazi/.config/yazi/README.md) | `~/.config/yazi` | 终端文件管理器 |
| [`mpv`](mpv/.config/mpv/README.md) | `~/.config/mpv` | 播放器配置与脚本 |
| [`Thunar`](Thunar/.config/Thunar/README.md) | `~/.config/Thunar` | 图形文件管理器 |

### 主题与外观

| 包 | 部署到 | 说明 |
|---|---|---|
| [`matugen`](matugen/.config/matugen/README.md) | `~/.config/matugen` | 配色模板与生成脚本 |
| [`waypaper`](waypaper/.config/waypaper/README.md) | `~/.config/waypaper` | 图形化壁纸切换 |
| [`fontconfig`](fontconfig/.config/fontconfig/README.md) | `~/.config/fontconfig` | 字体优先级 |
| [`gtk-3.0`](gtk-3.0/.config/gtk-3.0/README.md) | `~/.config/gtk-3.0` | GTK 主题、配色与书签 |
| [`environment.d`](environment.d/.config/environment.d/README.md) | `~/.config/environment.d` | 会话级环境变量（输入法、缩放等） |

### 输入法与杂项

| 包 | 部署到 | 说明 |
|---|---|---|
| [`fcitx5`](fcitx5/.config/fcitx5/README.md) | `~/.config/fcitx5` | 输入法配置（含 Rime） |
| [`local-share-fcitx5`](local-share-fcitx5/.local/share/fcitx5/README.md) | `~/.local/share/fcitx5` | 输入法皮肤与词库 |
| [`local-share-applications`](local-share-applications/.local/share/applications/README.md) | `~/.local/share/applications` | 自定义 .desktop |
| [`mimeapps`](mimeapps/README.md) | `~/.config/mimeapps.list` | 默认打开方式，用**绝对路径**链接，避免被写穿 |
| [`scripts`](scripts/.config/scripts/README.md) | `~/.config/scripts` | 通用脚本 |
| [`local-bin`](local-bin/.local/bin/README.md) | `~/.local/bin` | 命令入口，已由 `setup_bash_path` 加进 PATH |

> `tlpui/` 目录存在于仓库中，但没列入安装器的部署清单，需要时手动 `stow tlpui`。

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
| Phase 4b | 同上 | 装 8 个必需 AUR 包 |
| Phase 4c | `install_optional_packages` | 读 `common-applist.txt`，fzf 勾选后按 repo / AUR / flatpak 分类安装 |
| Phase 5 | `apply_dotfiles` | 备份旧配置 → 逐包 stow → 壁纸链接 → 脚本权限 → 路径替换 → flatpak 主题放行 |
| Phase 6a | `setup_nvim` | 装 Neovim，`Lazy! sync` 拉齐插件，可选装 LSP 依赖 |
| Phase 6b | `setup_zsh` | 装 Zsh，可选 `chsh` 改默认 shell |
| Phase 6c | `setup_mpv` | 装 MPV，可选下载 Anime4K 着色器 |
| Phase 6d | `setup_yazi` | 装 Yazi 与预览依赖，`ya pkg install` 装插件 |
| Phase 7a | `setup_locale` | 生成 `en_US.UTF-8` 与 `zh_CN.UTF-8` |
| Phase 7b | `setup_bash_path` | 把 `~/.local/bin` 加进 PATH |
| Phase 7c | `setup_local_bin` | 给 `~/.local/bin` 与各 `scripts/` 里的脚本加执行权限 |
| Phase 7d | `setup_gtklock_pam` | 创建 `/etc/pam.d/gtklock`，否则锁屏无法验证密码 |
| Phase 8 | `setup_matugen` | 用当前壁纸生成一次 Material You 配色 |
| Phase 8b | `setup_desktop_tweaks` | 默认终端、窗口按钮、i2c 权限等桌面细节 |
| Phase 9 | `enable_services` | 启用 NetworkManager、蓝牙、swayosd |
| Phase 9b | `setup_ly` | 装 ly 显示管理器，启用 `ly@tty1`（可跳过） |
| Phase 10 | `setup_user_dirs` | 建 `~/Pictures/Wallpapers` 等用户目录 |
| 收尾 | `show_completion` | 汇总结果，倒计时重启 |

### 安装后第一次启动

1. 重启，在 ly 登录界面输入用户名密码，自动进入 niri
2. 换壁纸：`waypaper`（选完会自动跑 matugen 重新配色）
3. 配输入法：`fcitx5-configtool`
4. 显示器特殊的话，改 `~/.config/niri/conf.d/output.kdl`
5. 完整操作速查见主目录下的 `必看-pullautumn-Niri使用方法.txt`

如果没装 ly，从 TTY 手动启动：

```bash
niri-session
```

### 安装选项

| 参数 | 说明 |
|---|---|
| `--minimal` | 只装核心，跳过可选软件与 flatpak |
| `--no-aur` | 不装 paru，AUR 包会被跳过 |
| `--no-stow` | 只装软件，不部署配置 |
| `--yes` | 全程自动确认，**可选软件按清单全部安装**（不弹 fzf） |
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
    gtklock hyprlock wlogout grim slurp satty wf-recorder imv \
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

# 必需 AUR 包（8 个）
paru -S --needed \
    matugen waypaper-git python-pywalfox lazyvim \
    ttf-jetbrains-maple-mono-nf-xx-xx ttf-lxgw-wenkai-screen \
    niri-sidebar-git wl-screenrec-git
```

**④ 部署配置**

```bash
cd ~/dotfiles
stow -d ~/dotfiles -t ~ -R niri waybar fuzzel rofi wlogout mako swaync \
    gtklock swaylock kitty starship zsh zshenv nvim yazi mpv obs-studio \
    Thunar btop fastfetch fcitx5 fontconfig environment.d gtk-3.0 \
    matugen scripts local-bin waypaper xdg-desktop-portal satty \
    local-share-applications local-share-fcitx5

# mimeapps 单独做成绝对路径链接（桌面环境会写这个文件）
ln -sfn ~/dotfiles/mimeapps/.config/mimeapps.list ~/.config/mimeapps.list
```

**⑤ 壁纸与脚本权限**

```bash
mkdir -p ~/Pictures
ln -sfn ~/dotfiles/wallpaper/Pictures/Wallpapers ~/Pictures/Wallpapers
find -L ~/.local/bin ~/.config/scripts ~/.config/niri/scripts \
     ~/.config/waybar/scripts ~/.config/matugen/scripts \
     -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
```

**⑥ 路径替换（用别的用户名时）**

配置里硬编码了 `/home/pullautumn`，不是这个用户名就替换：

```bash
grep -rl "/home/pullautumn" ~/.config ~/.local 2>/dev/null | while read -r f; do
    sed -i "s|/home/pullautumn|$HOME|g; s|/home/shorin|$HOME|g" "$f"
done
```

**⑦ 系统服务与登录**

```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable ly@tty1     # 用 ly 作为登录入口
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
| 锁屏 | `gtklock` `hyprlock` `wlogout` |
| 截图录屏 | `grim` `slurp` `satty` `wf-recorder` `imv` |
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

**AUR 包（8 个，配置直接依赖）**

| 包 | 用途 |
|---|---|
| [`matugen`](matugen/.config/matugen/README.md) | Material You 配色生成 |
| `waypaper-git` | 图形化壁纸切换 |
| `python-pywalfox` | Firefox 跟随系统配色 |
| `ttf-jetbrains-maple-mono-nf-xx-xx` | Maple Mono NF 字体（终端 / 编辑器） |
| `ttf-lxgw-wenkai-screen` | 霞鹜文楷屏幕版（中文正文字体） |
| `niri-sidebar-git` | niri 侧边栏 |
| `wl-screenrec-git` | Wayland 录屏 |
| `lazyvim` | Neovim 配置框架 |

**几个"看着像可选、其实不能删"的依赖**

| 包 | 为什么必需 |
|---|---|
| `xdg-desktop-portal-gnome` | `niri-portals.conf` 里 `ScreenCast` / `Screenshot` 都指向 gnome 后端，截图录屏靠它 |
| `gnome-keyring` | 同一份配置里 `Secret=gnome-keyring`，应用存密码靠它 |
| `polkit-gnome` | `niri/conf.d/autostart.kdl` 会 spawn 认证代理，没有它图形提权弹不出窗口 |

### 可选软件

安装到 Phase 4c 时弹出 fzf 界面，`TAB` 勾选、`ENTER` 安装、`ESC` 跳过。共 28 项：

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

setup/                           安装器本体（不是 stow 包）
wallpaper/Pictures/Wallpapers/   壁纸，安装时链接到 ~/Pictures/Wallpapers
wallpapers/                      头像等杂项资源，不部署
mainfest.txt                     包名与目标路径的对照表，供 to_stow.sh 使用
```

安装器的目录结构、阶段划分、如何加新步骤见 [setup/README.md](setup/README.md)。

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

ly 没启用，或者装的时候跳过了：

```bash
sudo systemctl enable --now ly@tty1
# 或者不装 ly，从 TTY 手动起桌面
niri-session
```

**改了用户名，配置里还是旧路径**

安装器会自动替换，手动装的话按[第 ⑥ 步](#手动安装)的 `sed` 处理，或者直接 `bash install.sh --reset` 重跑。

**显示器布局不对 / 只有一个屏亮**

编辑 `~/.config/niri/conf.d/output.kdl`，把输出名改成 `niri msg outputs` 里看到的实际名字。

**配色没生成，waybar 报错缺颜色文件**

matugen 至少需要跑一次：

```bash
waypaper                                    # 选张壁纸，会自动触发
# 或者直接生成
matugen image ~/Pictures/Wallpapers/xxx.jpg
```

**可选软件那一步没弹界面就过去了**

有 60 秒超时保护，超时自动跳过。重跑安装器即可（已完成的阶段会跳过，只重新问可选软件）。

## 说明

- **必需软件**写在 `setup/lib/config.sh`，可选软件写在 `setup/common-applist.txt`，`setup/niri-applist.txt` 是整理时的原始参考清单，安装器不读取。
- **路径替换**：配置里硬编码了 `/home/pullautumn`，装到其他用户名时安装器会自动替换成实际家目录（同时修掉 `waypaper` 里残留的 `/home/shorin`）。
- **备份**：部署前会把 `~/.config` 下的同名目录移到 `~/.config-backup-<时间戳>`，不会直接删除。`~/.local/bin` 这类共享目录交给 stow 合并，不整体搬走。
- **`waybar-niri-Win11Like`** 部署到 `~/.config/waybar-niri-Win11Like`，与主 waybar 互不影响，两套样式都会装好，用 `Mod+F2`（主样式）/ `Mod+F3`（Win11 风格）随时切换。
- **断点续跑**：进度记在 `~/.pullautumn_install_progress`，`--reset` 可清空。

## 致谢

- 安装器架构：[jswysnemc/dotfiles](https://github.com/jswysnemc/dotfiles)
- 大量 Arch 配置经验参考：[ShorinArchExperience](https://github.com/SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide/wiki)
