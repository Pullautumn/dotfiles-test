# shellcheck shell=bash

setup_locale() {
    section "Phase 7a" "Locale Configuration"

    if is_done "setup_locale"; then
        print_skip "Locale setup (already done)"
        return
    fi

    local need_gen=false

    # en_US.UTF-8：LC_CTYPE 用它，规避 fcitx5 漏字
    if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
        print_info "Enabling en_US.UTF-8..."
        if grep -q "^#en_US.UTF-8" /etc/locale.gen; then
            sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        elif ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
            echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
        fi
        need_gen=true
    else
        print_ok "en_US.UTF-8 locale available"
    fi

    # zh_CN.UTF-8：niri environment.kdl 里 LANG 用它
    if ! locale -a 2>/dev/null | grep -qi "zh_CN.utf8"; then
        print_info "Enabling zh_CN.UTF-8..."
        if grep -q "^#zh_CN.UTF-8" /etc/locale.gen; then
            sudo sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
        elif ! grep -q "^zh_CN.UTF-8" /etc/locale.gen; then
            echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
        fi
        need_gen=true
    else
        print_ok "zh_CN.UTF-8 locale available"
    fi

    if $need_gen; then
        print_info "Generating locales..."
        if sudo locale-gen >> "$LOG_FILE" 2>&1; then
            print_ok "Locales generated"
        else
            print_warn "locale-gen failed"
        fi
    fi

    # 系统 locale 保持英文，中文由 niri 的 environment.kdl 设置
    print_info "System locale: en_US.UTF-8 (Chinese set via niri environment)"

    mark_done "setup_locale"
    log "Locale configured"
}

setup_bash_path() {
    section "Phase 7b" "Bash PATH Configuration"

    if is_done "setup_bash_path"; then
        print_skip "Bash PATH (already done)"
        return
    fi

    local bash_profile="$HOME/.bash_profile"
    local bashrc="$HOME/.bashrc"
    local path_line='export PATH="$HOME/.local/bin:$PATH"'

    if [[ -f "$bash_profile" ]]; then
        if ! grep -q '\.local/bin' "$bash_profile"; then
            printf '\n# Add local bin to PATH\n%s\n' "$path_line" >> "$bash_profile"
            print_ok "Updated .bash_profile"
        else
            print_info ".bash_profile already has PATH"
        fi
    else
        cat > "$bash_profile" << 'BASHPROFILE'
# ~/.bash_profile - Bash login shell configuration

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Source .bashrc if it exists
[[ -f ~/.bashrc ]] && source ~/.bashrc
BASHPROFILE
        print_ok "Created .bash_profile"
    fi

    if [[ -f "$bashrc" ]]; then
        if ! grep -q '\.local/bin' "$bashrc"; then
            printf '\n# Add local bin to PATH\n%s\n' "$path_line" >> "$bashrc"
            print_ok "Updated .bashrc"
        else
            print_info ".bashrc already has PATH"
        fi
    fi

    mark_done "setup_bash_path"
    log "Bash PATH configured"
}

# ~/.local/bin 里的脚本（niri-session-wlroots / quickload / quicksave 等）
setup_local_bin() {
    section "Phase 7c" "Local Binaries"

    if is_done "setup_local_bin"; then
        print_skip "Local binaries (already done)"
        return
    fi

    mkdir -p "$HOME/.local/bin"

    local count=0
    if [[ -d "$HOME/.local/bin" ]]; then
        count=$(find "$HOME/.local/bin" -maxdepth 1 -type f 2>/dev/null | wc -l)
        find "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
    fi

    print_ok "$count 个本地脚本已就绪 (~/.local/bin)"
    mark_done "setup_local_bin"
    log "Local binaries ready"
}

# gtklock 需要自己的 PAM 服务
setup_gtklock_pam() {
    section "Phase 7d" "Lockscreen PAM (gtklock)"

    if is_done "setup_gtklock_pam"; then
        print_skip "PAM gtklock (already done)"
        return
    fi

    if ! command_exists gtklock; then
        print_skip "gtklock 未安装，跳过 PAM 配置"
        mark_done "setup_gtklock_pam"
        return
    fi

    local pam_file="/etc/pam.d/gtklock"

    if [[ -f "$pam_file" ]]; then
        print_ok "PAM service gtklock already exists"
    else
        print_info "Creating PAM configuration for gtklock..."
        sudo tee "$pam_file" > /dev/null << 'PAM'
#%PAM-1.0
# Password-only authentication for gtklock
auth       include    system-auth
account    include    system-auth
session    include    system-auth
PAM
        if [[ -f "$pam_file" ]]; then
            print_ok "Created $pam_file"
        else
            print_fail "Failed to create $pam_file"
        fi
    fi

    mark_done "setup_gtklock_pam"
    log "gtklock PAM configured"
}

# ==============================================================================
# Quickshell —— waybar-quickshell 样式的后端（Mod+F4 使用）
# ==============================================================================
# 这一步只准备「能跑起来」的前置条件，不负责启动：
#   · Theme.js 兜底（否则 matugen 没跑过时所有 QML 都加载失败）
#   · uv sync 装 Python 依赖（lockscreen 直接调 .venv/bin/python）
#   · systemd 单元注册（不 enable，和 swaync 抢通知服务，交给切换脚本管）
setup_quickshell() {
    section "Phase 7e" "Quickshell (waybar-quickshell 后端)"

    if is_done "setup_quickshell"; then
        print_skip "Quickshell setup (already done)"
        return
    fi

    local qs_dir="$HOME/.config/quickshell"

    if [[ ! -d "$qs_dir" ]]; then
        print_warn "$qs_dir 不存在，跳过（Mod+F4 的样式将不可用）"
        mark_done "setup_quickshell"
        return
    fi

    # 主题兜底
    # Commons/Theme.js 是 matugen 生成物且被 gitignore，git clean -fdx / 重装
    # 都可能把它弄没；没了 Quickshell 只会报 "Script qrc:/qs-blackhole unavailable"。
    # 所以不光看它在不在，还要看内容完不完整（matugen 写一半也算坏）。
    local qs_theme="$qs_dir/Commons/Theme.js"
    local qs_theme_default="$qs_dir/Commons/Theme.js.Default"
    local qs_screen_model="$qs_dir/Commons/ScreenModel.js"

    if [[ -f "$qs_theme" ]] && grep -q 'function alpha' "$qs_theme" 2>/dev/null; then
        print_skip "Commons/Theme.js 已存在且完整"
    elif [[ -f "$qs_theme_default" ]]; then
        cp -f "$qs_theme_default" "$qs_theme"
        print_ok "已生成默认 Theme.js（之后 matugen 会覆盖）"
    else
        print_warn "Commons/Theme.js 与 Theme.js.Default 都不存在，Quickshell 组件将无法加载"
    fi

    # QML 的 JS 脚本导入不能用 ../（失败的导入会被替换成 qrc:/qs-blackhole 占位），
    # 所以每个组件目录都要有自己的一份 ./Theme.js 和 ./ScreenModel.js。
    # 上游用符号链接，这里用实体拷贝，免得依赖软链权限。
    local qs_dir_item copied=0
    for qs_dir_item in "$qs_dir"/*/; do
        [[ -f "$qs_dir_item/shell.qml" ]] || continue
        if [[ -f "$qs_theme" ]] \
           && { [[ ! -f "$qs_dir_item/Theme.js" ]] || [[ "$qs_theme" -nt "$qs_dir_item/Theme.js" ]]; }; then
            cp -f "$qs_theme" "$qs_dir_item/Theme.js" 2>/dev/null && copied=$((copied + 1))
        fi
        if [[ -f "$qs_screen_model" ]] \
           && { [[ ! -f "$qs_dir_item/ScreenModel.js" ]] || [[ "$qs_screen_model" -nt "$qs_dir_item/ScreenModel.js" ]]; }; then
            cp -f "$qs_screen_model" "$qs_dir_item/ScreenModel.js" 2>/dev/null && copied=$((copied + 1))
        fi
    done

    if (( copied > 0 )); then
        print_ok "已同步 $copied 个组件目录的 Theme.js / ScreenModel.js"
    fi

    # Python 依赖
    if command_exists uv; then
        if exe "cd '$qs_dir' && uv sync"; then
            print_ok "Python dependencies installed"
        else
            print_warn "uv sync 失败，手动执行: cd ~/.config/quickshell && uv sync"
        fi
    else
        print_warn "未安装 uv，Quickshell 的 Python 组件（天气/计时/通知守护）不可用"
    fi

    # systemd 单元：只注册，不 enable
    if [[ -f "$HOME/.config/systemd/user/qs-notifications.service" ]]; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        print_ok "qs-notifications.service 已注册（开机不自启，由 switch-waybar.sh 管理）"
    fi

    if ! command_exists quickshell; then
        print_warn "找不到 quickshell 命令，Mod+F4 切过去后弹窗会全部失效"
    fi

    mark_done "setup_quickshell"
    log "Quickshell configured"
}

setup_matugen() {
    section "Phase 8" "Theme System (Matugen)"

    if is_done "setup_matugen"; then
        print_skip "Matugen setup (already done)"
        return
    fi

    if ! command_exists matugen; then
        print_warn "matugen not installed, skipping theme generation"
        mark_done "setup_matugen"
        return
    fi

    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    local default_wallpaper="$wallpaper_dir/壁纸1.jpg"
    local selected=""

    # 优先已选壁纸缓存（waypaper 会写这里）
    local cache_file="$HOME/.cache/current_wallpaper"
    if [[ -e "$cache_file" ]]; then
        selected=$(readlink -f "$cache_file" 2>/dev/null || true)
        [[ -f "$selected" ]] || selected=""
    fi

    # 其次壁纸目录里的第一张
    if [[ -z "$selected" && -d "$wallpaper_dir" ]]; then
        selected=$(find -L "$wallpaper_dir" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            2>/dev/null | sort | head -1)
    fi

    # 最后退回仓库默认壁纸
    if [[ -z "$selected" && -f "$default_wallpaper" ]]; then
        selected="$default_wallpaper"
    fi

    if [[ -n "$selected" ]]; then
        print_info "生成主题: $(basename "$selected")"
        if exe "matugen image '$selected'"; then
            print_ok "Theme generated successfully"
        else
            print_warn "Matugen failed, 手动执行: matugen image '$selected'"
        fi
    else
        print_warn "找不到壁纸，跳过主题生成"
        print_info "放一张壁纸到 ~/Pictures/Wallpapers 后执行: matugen image 图片路径"
    fi

    mark_done "setup_matugen"
    log "Matugen initialized"
}

# 桌面环境的一次性系统设置（不属于 dotfiles）
setup_desktop_tweaks() {
    section "Phase 8b" "Desktop Tweaks"

    if is_done "setup_desktop_tweaks"; then
        print_skip "Desktop tweaks (already done)"
        return
    fi

    # 默认终端（xdg-terminal-exec 读取）
    mkdir -p "$HOME/.config"
    local term_list="$HOME/.config/xdg-terminals.list"
    if ! grep -qx "kitty.desktop" "$term_list" 2>/dev/null; then
        echo "kitty.desktop" > "$term_list"
        print_ok "默认终端设为 kitty"
    else
        print_info "默认终端已是 kitty"
    fi

    # 去掉窗口标题栏的按钮（niri 无边框）
    if command_exists gsettings; then
        gsettings set org.gnome.desktop.wm.preferences button-layout ":close" 2>/dev/null \
            && print_ok "窗口按钮布局已设置" \
            || print_warn "gsettings 设置失败（缺少 dconf？）"
    fi

    # ddcutil 外接显示器亮度控制需要 i2c 权限
    if command_exists ddcutil; then
        if ! id -nG "$TARGET_USER" | grep -qw i2c; then
            sudo gpasswd -a "$TARGET_USER" i2c >/dev/null 2>&1 \
                && print_ok "已加入 i2c 组（重新登录生效）" \
                || print_warn "加入 i2c 组失败"
        else
            print_ok "已在 i2c 组"
        fi
        if ! lsmod 2>/dev/null | grep -q "^i2c_dev"; then
            echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
            print_info "已配置开机加载 i2c-dev"
        fi
    fi

    mark_done "setup_desktop_tweaks"
    log "Desktop tweaks applied"
}

enable_services() {
    section "Phase 9" "System Services"

    if is_done "enable_services"; then
        print_skip "Services enabled (already done)"
        return
    fi

    local services=("NetworkManager" "bluetooth")

    local service
    for service in "${services[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^$service.service"; then
            if sudo systemctl enable --now "$service" >> "$LOG_FILE" 2>&1; then
                print_ok "Enabled $service"
            else
                print_warn "Failed to enable $service"
            fi
        fi
    done

    # swayosd 的输入后端（音量/亮度 OSD）
    if systemctl list-unit-files 2>/dev/null | grep -q "^swayosd-libinput-backend.service"; then
        if sudo systemctl enable --now swayosd-libinput-backend.service >> "$LOG_FILE" 2>&1; then
            print_ok "Enabled swayosd-libinput-backend"
        else
            print_warn "Failed to enable swayosd-libinput-backend"
        fi
    fi

    mark_done "enable_services"
    log "Services enabled"
}

setup_ly() {
    section "Phase 9b" "Display Manager (ly)"

    if is_done "setup_ly"; then
        print_skip "ly setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}ly 是轻量的 TTY 登录管理器，用作 niri 的图形登录入口${NC}"
    echo -e "   ${DIM}不装的话需要登录 TTY 后手动执行 niri-session${NC}"
    echo ""

    if ! confirm "Install and configure ly display manager?"; then
        print_skip "ly installation (user declined)"
        mark_done "setup_ly"
        return
    fi

    print_info "Installing ly..."
    if ! sudo pacman -S --needed --noconfirm ly >> "$LOG_FILE" 2>&1; then
        print_fail "Failed to install ly"
        return
    fi
    print_ok "ly installed"

    # 清理可能冲突的其它显示管理器
    local other_dm
    for other_dm in sddm gdm lightdm greetd; do
        if systemctl is-enabled "$other_dm" &>/dev/null; then
            print_info "禁用冲突的 $other_dm"
            sudo systemctl disable "$other_dm" >> "$LOG_FILE" 2>&1 || true
        fi
    done

    local ly_conf="/etc/ly/config.ini"
    if [[ -f "$ly_conf" ]]; then
        sudo sed -i 's/^[#[:space:]]*animation[[:space:]]*=.*/animation = matrix/' "$ly_conf" 2>/dev/null || true
        print_ok "ly 动画设为 matrix"
    else
        print_warn "$ly_conf 未找到，跳过动画配置"
    fi

    if sudo systemctl enable ly@tty1 >> "$LOG_FILE" 2>&1; then
        print_ok "ly@tty1 enabled"
    else
        print_warn "Failed to enable ly@tty1"
    fi

    mark_done "setup_ly"
    log "ly configured"
}

setup_user_dirs() {
    section "Phase 10" "User Directories"

    if is_done "setup_user_dirs"; then
        print_skip "User directories (already done)"
        return
    fi

    local dirs=(
        "$HOME/.local/bin"
        "$HOME/.local/share"
        "$HOME/.cache"
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
        "$HOME/Videos/Recordings"
        "$HOME/Templates"
    )

    local dir
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    # niri 右键"新建"菜单需要的模板
    touch "$HOME/Templates/new"
    printf '#!/bin/bash\n' > "$HOME/Templates/new.sh"
    chmod +x "$HOME/Templates/new.sh"

    print_ok "Directories created"
    mark_done "setup_user_dirs"
    log "User directories created"
}
