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

# 装失败的包会落盘成一份可直接复制粘贴的清单（重启后照着补装）
PENDING_LIST_FILE="$HOME/pullautumn-missing-packages.txt"
declare -ga FAILED_PACKAGES=()   # 逐包安装时失败的包名
declare -ga MISSING_PACKAGES=()  # 末尾 pacman -T 核对出的缺失包名（包组已展开）

# Install options
INSTALL_MINIMAL=false
SKIP_STOW=false
ASSUME_YES=false
NO_REBOOT=false
AUR_HELPER=""

# 脚本以普通用户身份运行，内部通过 sudo 提权
TARGET_USER="$(id -un)"
TARGET_HOME="$HOME"

# 配置作者的用户名。两个用途：
#   1. 判定「作者本人」——只有它才链接壁纸、才追加 uv 镜像源包、GTK 书签才多
#      ~/.config 与 ~/.local 两条（三处，见 03-dotfiles.sh 与本文件末尾）。
#   2. 仅供参考，**不再**拿它做全仓库批量替换（那会把 ~/.dotfiles 改写成别人的用户名）。
#      现在配置里能自解析的都已改成 ~ / $HOME / vim.fn.expand；剩余例外：
#        · GTK 书签 → 安装时按 $HOME 重新生成（见 _dotfiles_generate_bookmarks）
#        · niri 的 screenshot-path → 写 ~，由 niri 自己展开并建目录
# 可用环境变量覆盖：LEGACY_USER=someone ./install.sh
LEGACY_USER="${LEGACY_USER:-pullautumn}"

# ==============================================================================
# Stow Packages
# ==============================================================================
# 顶层目录即 stow 包。以下几个不是包：
#   setup/       安装器本体
#   wallpaper/   壁纸，单独链接到 ~/Pictures/Wallpapers
#   wallpapers/  头像等杂项资源，不部署
#   sddm-theme/  SDDM 主题源文件，由 setup_sddm 拷到 /usr/share/sddm/themes/lunar-glass
# waybar-quickshell 是备选状态栏样式，部署到 ~/.config/waybar-quickshell，
# 与主 waybar 各自独立，用 Mod+F2 / Mod+F3 / Mod+F4 随时切换。
# 它依赖 quickshell 包（弹窗/面板全在 ~/.config/quickshell 里），两者要一起装。
STOW_PACKAGES=(
    niri waybar waybar-niri-Win11Like waybar-quickshell
    quickshell
    systemd
    fuzzel rofi wlogout
    mako swaync
    kitty starship zsh zshenv
    nvim yazi mpv obs-studio
    Thunar btop fastfetch
    fcitx5 fontconfig environment.d gtk-3.0 mimeapps
    matugen scripts local-bin
    waypaper xdg-desktop-portal
    local-share-applications local-share-fcitx5
)

# uv 的 PyPI 镜像源只在作者机器上链接，理由和壁纸一样：清华源跟地理位置绑定，
# 对海外用户是减分项，而 stow 是整包链接 —— 放进上面的主列表，等于给每个
# clone 这份 dotfiles 的人都塞一个国内源。
# 放在数组**之后**追加而不是加条件判断包体，是因为 stow 只认目录，包里没法设开关。
# 注意 uv 的**二进制**不在这里：它在 AUR_PACKAGES 里，所有人都会装（quickshell 要用）；
# 条件化的只是 ~/.config/uv/uv.toml 这份镜像配置。
if [[ "${TARGET_USER,,}" == "${LEGACY_USER,,}" ]]; then
    STOW_PACKAGES+=(uv)
fi

# ==============================================================================
# Package Groups (仓库包，用 paru/pacman 静默安装)
# ==============================================================================
declare -A PKG_GROUPS

PKG_GROUPS[wm]="niri xwayland-satellite awww swayidle swayosd polkit-gnome"
PKG_GROUPS[portal]="xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome"
# 后面五个不是 waybar 自己的依赖（库依赖 pacman 会自动带），而是主状态栏各模块的
# 「点击目标」：缺了不报错，只是点了没反应、或者模块一直空白。
#   power-profiles-daemon → power-profiles-daemon 模块（另需 enable 服务，见 05-system.sh）
#   mission-center        → memory 模块左键，包名带连字符，二进制才叫 missioncenter
#   gnome-clocks / gnome-calendar → custom/clock 左键 / 右键
#   lm_sensors            → custom/temperature 的 sensors（本来被 mesa 间接带进来，写明免得哪天断）
PKG_GROUPS[bar]="waybar power-profiles-daemon mission-center gnome-clocks gnome-calendar lm_sensors"
PKG_GROUPS[launcher]="fuzzel rofi"
PKG_GROUPS[notify]="swaync libnotify"
# 锁屏用 quickshell 的 lockscreen 组件（qs-lock），不需要单独的锁屏包；
# 这里只剩电源菜单 wlogout。
PKG_GROUPS[lock]="wlogout"
PKG_GROUPS[screenshot]="grim slurp wayfreeze wf-recorder imv ffmpeg"
PKG_GROUPS[clipboard]="cliphist wl-clipboard xclip cliphist-tui-git"
PKG_GROUPS[terminal]="kitty starship xdg-terminal-exec"
PKG_GROUPS[shell]="zsh atuin zoxide fzf thefuck fnm"
# nautilus-python（官方仓库，provides python-nautilus）：Nautilus 43 之后原生「在终端中打开」
# 不可配置，靠它加载 nautilus-open-any-terminal（AUR，见 AUR_PACKAGES）补一个可指定终端的右键项。
PKG_GROUPS[files]="thunar thunar-volman thunar-archive-plugin tumbler nautilus gnome-text-editor gvfs gvfs-mtp gvfs-smb ffmpegthumbnailer poppler-glib file-roller webp-pixbuf-loader gnome-keyring nautilus-python"
PKG_GROUPS[input]="fcitx5 fcitx5-im fcitx5-chinese-addons fcitx5-rime rime-ice-git"
PKG_GROUPS[audio]="pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol playerctl"
PKG_GROUPS[network]="networkmanager network-manager-applet nm-connection-editor bluez bluez-utils blueman"
PKG_GROUPS[cli]="ripgrep fd bat eza jq curl wget unzip bc duf fastfetch prettyping pacman-contrib unarchiver lazygit lazydocker btop"
PKG_GROUPS[fonts]="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-liberation otf-font-awesome ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd"
PKG_GROUPS[dev]="python python-pip nodejs npm"
PKG_GROUPS[media]="mpv yazi cava"
PKG_GROUPS[power]="brightnessctl wlsunset"
PKG_GROUPS[browser]="google-chrome firefox"
PKG_GROUPS[theme]="adw-gtk-theme"

PKG_GROUP_NAMES=(
    "wm:窗口管理器 (niri)"
    "portal:桌面门户 (xdg-desktop-portal)"
    "bar:状态栏 (waybar + 模块点击依赖)"
    "launcher:启动器 (fuzzel/rofi)"
    "notify:通知 (swaync)"
    "lock:电源菜单 (wlogout；锁屏在 quickshell 里)"
    "screenshot:截图与录屏 (grim/wayfreeze/wf-recorder)"
    "clipboard:剪贴板 (cliphist + cliphist-tui)"
    "terminal:终端与提示符 (kitty/starship)"
    "shell:Shell 增强 (zsh/atuin/zoxide)"
    "files:文件管理与文本编辑 (thunar/nautilus/gnome-text-editor)"
    "input:输入法 (fcitx5)"
    "audio:音频 (pipewire)"
    "network:网络与蓝牙"
    "cli:命令行工具"
    "fonts:字体"
    "dev:开发环境"
    "media:播放器与文件管理 (mpv/yazi)"
    "power:亮度与色温 (brightnessctl/wlsunset)"
    "browser:浏览器"
    "theme:GTK 主题 (adw-gtk3，明暗切换用)"
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
    # 截图：mark-shot 做选区标注，wayscrollshot-bin 做滚动长截图
    # （wayfreeze 在官方仓库，随 PKG_GROUPS[screenshot] 装）
    mark-shot
    wayscrollshot-bin
    # waybar-quickshell 样式的后端：quickshell 本体 + Python 依赖管理器
    quickshell
    uv
    # zsh 语法高亮，由 zsh-vi-mode 的 zvm_after_init 钩子调用（见 zsh/plugins.zsh）
    zsh-patina
    # Nautilus 右键「在终端中打开」的菜单项提供者（需要 PKG_GROUPS[files] 里的 nautilus-python）。
    # 终端由 gsettings 键 com.github.stunkymonkey.nautilus-open-any-terminal terminal 决定，
    # 初始值在 05-system.sh 的 setup_desktop_tweaks 里设为 kitty。
    nautilus-open-any-terminal
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
