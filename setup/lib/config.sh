# shellcheck shell=bash

# ==============================================================================
# Colors & Styles
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ==============================================================================
# Configuration
# ==============================================================================
DOTFILES_REPO="https://github.com/Pullautumn/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pullautumn"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
STATE_FILE="$HOME/.pullautumn_install_progress"

# Install options
INSTALL_MINIMAL=false
SKIP_STOW=false
ASSUME_YES=false
NO_REBOOT=false
AUR_HELPER=""

# 脚本以普通用户身份运行，内部通过 sudo 提权
TARGET_USER="$(id -un)"
TARGET_HOME="$HOME"

# 配置作者的用户名/家目录，仅供参考。
# 安装器**不再**拿它做全仓库批量替换（那会把 ~/.dotfiles 改写成别人的用户名）。
# 现在配置里能自解析的都已改成 ~ / $HOME / vim.fn.expand；剩余例外：
#   · GTK 书签 → 安装时按 $HOME 重新生成（见 03-dotfiles.sh: _dotfiles_generate_bookmarks）
#   · niri 的 screenshot-path → 只提示，不代改
LEGACY_USER="pullautumn"
LEGACY_HOME="/home/pullautumn"

# ==============================================================================
# Stow Packages
# ==============================================================================
# 顶层目录即 stow 包。以下几个不是包：
#   setup/      安装器本体
#   wallpaper/  壁纸，单独链接到 ~/Pictures/Wallpapers
#   wallpapers/ 头像等杂项资源，不部署
# waybar-quickshell 是备选状态栏样式，部署到 ~/.config/waybar-quickshell，
# 与主 waybar 各自独立，用 Mod+F2 / Mod+F3 / Mod+F4 随时切换。
# 它依赖 quickshell 包（弹窗/面板全在 ~/.config/quickshell 里），两者要一起装。
STOW_PACKAGES=(
    niri waybar waybar-niri-Win11Like waybar-quickshell
    quickshell
    systemd
    fuzzel rofi wlogout
    mako swaync gtklock swaylock
    kitty starship zsh zshenv
    nvim yazi mpv obs-studio
    Thunar btop fastfetch
    fcitx5 fontconfig environment.d gtk-3.0 mimeapps
    matugen scripts local-bin
    waypaper xdg-desktop-portal satty
    local-share-applications local-share-fcitx5
)

# ==============================================================================
# Package Groups (仓库包，用 paru/pacman 静默安装)
# ==============================================================================
declare -A PKG_GROUPS

PKG_GROUPS[wm]="niri xwayland-satellite awww swayidle swayosd polkit-gnome"
PKG_GROUPS[portal]="xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome"
PKG_GROUPS[bar]="waybar"
PKG_GROUPS[launcher]="fuzzel rofi"
PKG_GROUPS[notify]="swaync libnotify"
PKG_GROUPS[lock]="gtklock hyprlock wlogout"
PKG_GROUPS[screenshot]="grim slurp satty wf-recorder imv"
PKG_GROUPS[clipboard]="cliphist wl-clipboard xclip"
PKG_GROUPS[terminal]="kitty starship"
PKG_GROUPS[shell]="zsh atuin zoxide fzf thefuck fnm"
PKG_GROUPS[files]="thunar thunar-volman thunar-archive-plugin tumbler gvfs gvfs-mtp gvfs-smb ffmpegthumbnailer poppler-glib file-roller webp-pixbuf-loader gnome-keyring"
PKG_GROUPS[input]="fcitx5 fcitx5-im fcitx5-chinese-addons"
PKG_GROUPS[audio]="pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol playerctl"
PKG_GROUPS[network]="networkmanager network-manager-applet nm-connection-editor bluez bluez-utils blueman"
PKG_GROUPS[cli]="ripgrep fd bat eza jq curl wget unzip bc duf fastfetch prettyping pacman-contrib unarchiver lazygit lazydocker btop"
PKG_GROUPS[fonts]="noto-fonts-cjk ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd"
PKG_GROUPS[dev]="python python-pip nodejs npm"
PKG_GROUPS[media]="mpv yazi cava"
PKG_GROUPS[power]="brightnessctl wlsunset"
PKG_GROUPS[browser]="google-chrome firefox"

PKG_GROUP_NAMES=(
    "wm:窗口管理器 (niri)"
    "portal:桌面门户 (xdg-desktop-portal)"
    "bar:状态栏 (waybar)"
    "launcher:启动器 (fuzzel/rofi)"
    "notify:通知 (swaync)"
    "lock:锁屏与电源菜单 (gtklock/hyprlock/wlogout)"
    "screenshot:截图与录屏 (grim/satty/wf-recorder)"
    "clipboard:剪贴板 (cliphist)"
    "terminal:终端与提示符 (kitty/starship)"
    "shell:Shell 增强 (zsh/atuin/zoxide)"
    "files:文件管理 (thunar)"
    "input:输入法 (fcitx5)"
    "audio:音频 (pipewire)"
    "network:网络与蓝牙"
    "cli:命令行工具"
    "fonts:字体"
    "dev:开发环境"
    "media:播放器与文件管理 (mpv/yazi)"
    "power:亮度与色温 (brightnessctl/wlsunset)"
    "browser:浏览器"
)

# ==============================================================================
# AUR Packages (配置依赖，必须安装)
# ==============================================================================
# 注：matugen 已在官方仓库，这里一并交给 paru 处理（repo 包也装得了）。
# LazyVim 不是 AUR 包（AUR 里没有这个名字），它由 nvim 配置首次启动时自举。
AUR_PACKAGES=(
    matugen
    waypaper-git
    python-pywalfox
    ttf-jetbrains-maple-mono-nf-xx-xx
    ttf-lxgw-wenkai-screen
    niri-sidebar-git
    wl-screenrec-git
    # waybar-quickshell 样式的后端：quickshell 本体 + Python 依赖管理器
    quickshell
    uv
    # zsh 语法高亮，由 zsh-vi-mode 的 zvm_after_init 钩子调用（见 zsh/plugins.zsh）
    zsh-patina
)

# ==============================================================================
# 可选软件清单
# ==============================================================================
# 安装器在「可选软件」阶段读取这个文件，用 fzf 让你多选，再按包名前缀分类：
#   AUR:包名      → 通过 AUR helper 安装
#   flatpak:包名  → 通过 flatpak 安装
#   包名          → 通过 pacman/paru 从官方仓库安装
# 改清单只改这个文件，不用动脚本。
COMMON_APPLIST="${SETUP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/common-applist.txt"
