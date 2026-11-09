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
        # -L 是必须的：stow 把 local-bin 折叠成指向仓库的目录软链，
        # 不加 -L 的 find 不会往下走，count 永远是 0、chmod 也一个都碰不到。
        count=$(find -L "$HOME/.local/bin" -maxdepth 1 -type f 2>/dev/null | wc -l)
        find -L "$HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
    fi

    print_ok "$count 个本地脚本已就绪 (~/.local/bin)"
    mark_done "setup_local_bin"
    log "Local binaries ready"
}

# ==============================================================================
# 滚动长截图 wayscrollshot
# ==============================================================================
# AUR 的 wayscrollshot-bin 是第一选择（已列在 AUR_PACKAGES 里）。这里只是兜底：
# AUR helper 拉不到或者用户没装 AUR helper 时，直接抓官方 release 的静态二进制，
# 丢进 ~/.local/bin。waybar 中键和截图工具箱都按 "$PATH 里有 wayscrollshot" 找它。
install_wayscrollshot() {
    section "Phase 7e" "Wayscrollshot (scrolling screenshot)"

    if is_done "install_wayscrollshot"; then
        print_skip "wayscrollshot (already done)"
        return
    fi

    local bin_path="$HOME/.local/bin/wayscrollshot"

    if command_exists wayscrollshot || [[ -x "$bin_path" ]]; then
        print_ok "wayscrollshot 已存在"
        mark_done "install_wayscrollshot"
        return
    fi

    print_info "从 GitHub Release 下载 wayscrollshot ..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local tar_url="https://github.com/jswysnemc/wayscrollshot/releases/download/v0.1.0/wayscrollshot-linux-x86_64.tar.gz"
    local ok=0

    # curl --retry 处理传输中途被 reset，外层 gh_retry 再兜 3 次整体重试
    if gh_retry "curl -fsSL --retry 3 --retry-all-errors --connect-timeout 10 '$tar_url' -o '$tmp_dir/wayscrollshot.tar.gz'" 3 3 \
        && tar -xzf "$tmp_dir/wayscrollshot.tar.gz" -C "$tmp_dir" 2>/dev/null; then
        local extracted
        extracted=$(find "$tmp_dir" -type f -name "wayscrollshot" 2>/dev/null | head -1)
        if [[ -n "$extracted" ]]; then
            mkdir -p "$HOME/.local/bin"
            cp "$extracted" "$bin_path"
            chmod +x "$bin_path"
            print_ok "wayscrollshot 已安装到 ~/.local/bin/wayscrollshot"
            ok=1
        fi
    fi

    if (( ok == 0 )); then
        print_warn "wayscrollshot 下载失败，长截图功能暂时不可用"
        print_info "可稍后手动安装：paru -S wayscrollshot-bin"
    fi

    rm -rf "$tmp_dir"
    mark_done "install_wayscrollshot"
    log "wayscrollshot installation attempted"
}

# ==============================================================================
# 锁屏 PAM（quickshell lockscreen）
# ==============================================================================
# 锁屏组件用 Quickshell.Services.Pam 认证，两个 PAM service 分工：
#   qs-lock       → 只走密码（system-auth）
#   qs-lock-face  → 先试 howdy 人脸，失败再走密码（只在装了 howdy 时才有意义）
#
# 注意：这两个文件**不是**可选的。缺 qs-lock 的话锁屏起来输什么密码都失败，
# 而且界面上不会提示原因，很容易以为是自己密码打错了。
setup_qs_lock_pam() {
    section "Phase 7d" "Lockscreen PAM (quickshell)"

    # 刻意**不做** is_done 短路。这个函数本身是幂等的（每一步都先检查文件在不在），
    # 而 PAM 内容取决于「此刻装没装 howdy」。一旦短路，用户装完系统后再补装 howdy，
    # 重跑安装器也永远不会补出 qs-lock-face，锁屏的人脸按钮就成了永久摆设。

    if ! command_exists quickshell; then
        print_warn "quickshell 未安装，跳过锁屏 PAM 配置"
        print_info "锁屏（qs-lock）依赖 quickshell，装在 AUR_PACKAGES 里，Phase 2 应该装过"
        mark_done "setup_qs_lock_pam"
        return
    fi

    # Quickshell.Services.Pam 是编译期可选的。没有这个模块时锁屏能起来但认证必失败，
    # 所以这里提前探一下，把话说在前面（而不是等用户锁屏了才发现进不去）。
    local pam_module=""
    local candidate
    for candidate in \
        /usr/lib/qt6/qml/Quickshell/Services/Pam \
        /usr/lib/qt5/qml/Quickshell/Services/Pam \
        /usr/lib/quickshell/Services/Pam; do
        if [[ -e "$candidate" ]]; then
            pam_module="$candidate"
            break
        fi
    done
    if [[ -z "$pam_module" ]] \
       && ! pacman -Ql quickshell 2>/dev/null | grep -qi 'Services/Pam'; then
        print_warn "当前 quickshell 似乎不带 Quickshell.Services.Pam"
        print_info "锁屏能起来但无法验证密码。需要换 AUR 的 quickshell-git（编译时加 -D pam=true）"
    fi

    # ---- 1. 密码认证 ----
    local pam_file="/etc/pam.d/qs-lock"
    if [[ -f "$pam_file" ]]; then
        print_ok "PAM service qs-lock already exists"
    else
        print_info "Creating PAM configuration for qs-lock..."
        sudo tee "$pam_file" > /dev/null << 'PAM'
#%PAM-1.0
# Password-only authentication for quickshell lockscreen
auth       include    system-auth
account    include    system-auth
session    include    system-auth
PAM
        if [[ -f "$pam_file" ]]; then
            print_ok "Created $pam_file"
        else
            print_fail "Failed to create $pam_file"
            print_info "手动创建: sudo nano $pam_file"
        fi
    fi

    # ---- 2. 人脸认证（可选）----
    # howdy 的 PAM 接法有两种，取决于装的版本/打包方式：
    #   A. 自带 C 模块 pam_howdy.so
    #   B. 只提供 Python 桥 /lib/security/howdy/pam.py，靠 pam_python.so 加载
    # 写死其中一种，另一种环境就是「人脸永远失败，界面只显示识别失败」，极难排查。
    # 所以这里先探测，探不到就退化成只走密码——保证锁屏本身不会因此坏掉。
    local face_file="/etc/pam.d/qs-lock-face"

    # 2a. 没装 howdy 时问一次。它是可选项，默认不装：
    #     howdy 在 AUR，依赖 python-dlib / opencv 要编译；而且只有红外摄像头识别率才可靠。
    #     --yes 模式跳过询问：无人值守装机会被编译拖很久，也没人站在摄像头前录脸，装了白装。
    if ! command_exists howdy && [[ "${ASSUME_YES:-false}" != "true" ]]; then
        echo ""
        print_info "锁屏支持 howdy 人脸识别，当前未安装。"
        print_info "前置条件：红外摄像头识别才可靠（普通 RGB 头误识率明显偏高）"
        print_info "装完还必须 sudo howdy add 录入人脸，否则识别必定失败"
        if confirm "现在安装 howdy（人脸识别解锁）？" "n"; then
            _resolve_installer
            if [[ "$AUR_HELPER" == "sudo pacman" ]]; then
                print_warn "没有可用的 AUR helper，howdy 在 AUR，无法自动安装"
                print_info "先装 paru 或 yay，再执行: paru -S howdy"
            elif _install_each "人脸识别" howdy; then
                hash -r 2>/dev/null || true
                print_ok "howdy 已安装"
                print_info "必做两步: sudo howdy config（设 device_path）→ sudo howdy add（录脸）"
            else
                print_warn "howdy 安装失败（AUR 包需要编译，可能缺依赖）"
                print_info "手动重试: $AUR_HELPER -S howdy"
            fi
        else
            print_skip "跳过人脸识别，锁屏仍可正常用密码解锁"
            print_info "以后想用：装好 howdy 后重跑安装器，会自动补上 $face_file"
        fi
    fi

    # 2b. 按「此刻装没装 howdy」生成 PAM 文件
    if command_exists howdy; then
        if [[ -f "$face_file" ]]; then
            print_ok "PAM service qs-lock-face already exists"
        else
            local howdy_pam_line=""
            local candidate
            for candidate in /usr/lib/security/pam_howdy.so /lib/security/pam_howdy.so; do
                if [[ -e "$candidate" ]]; then
                    howdy_pam_line="auth       sufficient pam_howdy.so"
                    break
                fi
            done
            if [[ -z "$howdy_pam_line" ]]; then
                for candidate in /lib/security/howdy/pam.py /usr/lib/security/howdy/pam.py; do
                    if [[ -e "$candidate" ]]; then
                        howdy_pam_line="auth       sufficient pam_python.so $candidate"
                        break
                    fi
                done
            fi

            if [[ -z "$howdy_pam_line" ]]; then
                print_warn "装了 howdy，但找不到它的 PAM 模块（pam_howdy.so / howdy/pam.py）"
                print_info "qs-lock-face 先退化为只走密码；核实后手动补: sudo nano $face_file"
                howdy_pam_line="# howdy PAM 模块未找到，暂时只走密码"
            fi

            print_info "Creating PAM configuration for qs-lock-face (howdy)..."
            if printf '%s\n' \
                '#%PAM-1.0' \
                '# Face recognition first, password as fallback' \
                "$howdy_pam_line" \
                'auth       include    system-auth' \
                'account    include    system-auth' \
                'session    include    system-auth' \
                | sudo tee "$face_file" > /dev/null; then
                print_ok "Created $face_file"
            else
                print_fail "Failed to create $face_file"
                print_info "手动创建: sudo nano $face_file"
            fi
        fi
    else
        print_skip "未安装 howdy，跳过 qs-lock-face（锁屏只走密码）"
        print_info "以后装了 howdy 重跑安装器即可补上（这一步不再被 is_done 挡住）"
    fi

    mark_done "setup_qs_lock_pam"
    log "quickshell lockscreen PAM configured"
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

    # 首次安装不依赖 matugen，它只在以后换壁纸时用；缺了也不影响这一步
    if ! command_exists matugen; then
        print_warn "matugen 未安装，换壁纸时的配色生成会不可用（首次部署不依赖它）"
    fi

    local mode_cache="$HOME/.cache/matugen-strategy"
    mkdir -p "$mode_cache"
    local init_mode="light"
    if [[ -f "$mode_cache/mode" ]]; then
        init_mode=$(cat "$mode_cache/mode")
    else
        echo "light" > "$mode_cache/mode"
    fi

    # 首次部署**不跑 matugen**。
    # matugen 生成的是「当前那张壁纸」的配色，而全新安装应该先落在仓库自带的
    # 默认配色上，等用户真正换壁纸时再由 matugen-update.sh 接管。
    # --configs-only 只做文件还原，不碰 GSettings / fcitx / 图标缓存 ——
    # 那几段里有 sed -i 直接改 ~/.config 下的文件，等于改写 stow 软链背后的仓库。
    local restore_script="$HOME/.config/scripts/matugen-restore.sh"
    if [[ -f "$restore_script" ]]; then
        print_info "应用仓库自带的默认配色（不生成壁纸配色）"
        if exe "bash '$restore_script' --configs-only"; then
            print_ok "Default colors restored"
        else
            print_warn "还原默认配色失败（看 $LOG_FILE）"
            print_info "可手动重试: bash ~/.config/scripts/matugen-restore.sh --configs-only"
        fi
    else
        print_warn "找不到 matugen-restore.sh，跳过配色还原"
    fi

    # 同步 GNOME 的明暗基调。这一步和配色数值无关，纯粹是 dconf 状态：
    # matugen 只算颜色；真正决定「黑暗模式 / 白色模式」的是 color-scheme 这个键，
    # libadwaita（GTK4 / 现代 GNOME 系程序）只认它，不认 gtk-theme。
    if command_exists gsettings; then
        local scheme theme_name
        if [[ "$init_mode" == "light" ]]; then
            scheme="prefer-light"; theme_name="adw-gtk3"
        else
            scheme="prefer-dark";  theme_name="adw-gtk3-dark"
        fi
        if gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null \
            && gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null; then
            print_ok "系统明暗基调: $init_mode"
        else
            print_warn "gsettings 写入失败（可能不在图形会话），首次轮换壁纸时会补上"
        fi
    fi

    mark_done "setup_matugen"
    log "Default colors restored (matugen not run on first install)"
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
    # 该文件是按优先级排序的候选列表，第一行即默认终端。
    # 只把 kitty 提到第一行，其余条目原样保留（不覆盖用户自己排过的顺序）。
    if [[ -f "$term_list" ]] && [[ "$(head -n 1 "$term_list" 2>/dev/null)" == "kitty.desktop" ]]; then
        print_info "默认终端已是 kitty"
    else
        if [[ -f "$term_list" ]]; then
            cp "$term_list" "$term_list.bak.$(date +%Y%m%d%H%M%S)"
        fi
        {
            echo "kitty.desktop"
            grep -vx "kitty.desktop" "$term_list" 2>/dev/null || true
        } > "$term_list.tmp"
        mv "$term_list.tmp" "$term_list"
        print_ok "默认终端设为 kitty（原有条目已保留）"
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

# 蓝牙服务自检：单元 enabled ≠ 单元正在跑。
#
# bluez 的 unit 带 `ConditionPathIsDirectory=/sys/class/bluetooth` 且**没有** `Restart=`。
# 内核模块（btusb 等）还没加载时该目录不存在，systemd 会直接跳过启动，而
# `systemctl enable --now` 依然返回 0 —— 于是安装器打印「Enabled bluetooth」，
# 实际没有任何守护进程。之后打开 blueman 就会看到「蓝牙守护进程没有运行」。
#
# 这里只负责如实记账，补救提示交给完成页（99-completion.sh）。
_bluetooth_selfcheck() {
    BT_SELFCHECK_FAILED=false
    systemctl list-unit-files 2>/dev/null | grep -q "^bluetooth.service" || return 0

    if systemctl is-active --quiet bluetooth.service; then
        print_ok "Bluetooth daemon running"
        return 0
    fi

    BT_SELFCHECK_FAILED=true
    print_warn "蓝牙已启用但未运行（内核模块可能晚于服务加载），重启后仍不行就手动重启一次服务"
    log "bluetooth.service enabled but not active"
}

enable_services() {
    section "Phase 9" "System Services"

    if is_done "enable_services"; then
        print_skip "Services enabled (already done)"
        _bluetooth_selfcheck
        return
    fi

    local services=("NetworkManager" "bluetooth")

    local service unit
    for service in "${services[@]}"; do
        unit="$service.service"
        systemctl list-unit-files 2>/dev/null | grep -q "^$unit" || continue

        # 拆成 enable + start 两步，不用 `enable --now`：
        # ConditionPathIsDirectory 不满足时启动会被 systemd 静默跳过，但 `enable --now`
        # 仍返回 0，失败会被掩盖成成功（详见 _bluetooth_selfcheck 的注释）。
        if ! sudo systemctl enable "$unit" >> "$LOG_FILE" 2>&1; then
            print_warn "Failed to enable $service"
            continue
        fi
        if ! systemctl is-active --quiet "$unit"; then
            sudo systemctl start "$unit" >> "$LOG_FILE" 2>&1 || true
        fi

        if systemctl is-active --quiet "$unit"; then
            print_ok "Enabled $service"
        else
            print_warn "Enabled $service（已设为开机自启）"
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
    _bluetooth_selfcheck
    log "Services enabled"
}

# ==============================================================================
# 显示管理器：SDDM + lunar-glass 主题
# ==============================================================================
# 为什么是 SDDM 而不是 ly：
#   仓库里带了上游的 lunar-glass 主题（毛玻璃 + 农历 + 人脸登录），只有 SDDM 能加载。
#   ly 是纯 TTY 登录器，主题化能力几乎为零。
#
# 三个刻意的选择：
#   1. 配置写进 /etc/sddm.conf.d/ 的 drop-in，**不动** /etc/sddm.conf 原文件。
#      SDDM 先读 /etc/sddm.conf 再按文件名顺序读 conf.d/*.conf，后者覆盖前者。
#   2. 只 enable 不 start —— 安装过程中 start 会把当前图形会话当场踢掉。
#   3. 顺手 disable ly@tty1。两条 DM 同时 enabled 会抢 tty1，开机会互相踢。
setup_sddm() {
    section "Phase 9b" "Display Manager (SDDM)"

    if is_done "setup_sddm"; then
        print_skip "SDDM setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}SDDM 是图形登录界面，套用仓库里的 lunar-glass 主题${NC}"
    echo -e "   ${DIM}不装的话需要登录 TTY 后手动执行 niri-session${NC}"
    echo ""

    if ! confirm "Install and configure SDDM display manager?"; then
        print_skip "SDDM installation (user declined)"
        mark_done "setup_sddm"
        return
    fi

    # ---- 1. 装包 ----
    # 主题只 import QtQuick 2.7 和 SddmComponents 2.0，用不到 QtGraphicalEffects，
    # 所以依赖很薄。qt5-declarative 是 QML 运行时，qt5-wayland/qt6-wayland 给 greeter 用。
    #
    # greeter 的 Wayland 合成器沿用上游 jswysnemc 的 kwin_wayland。
    # 它是这套配置唯一有实机验证记录的方案；换成 weston --shell=kiosk 虽然少几十个
    # KDE 依赖，但等于把唯一验证过的环节换掉，出问题时无从对比。
    # 真不想装 kwin 有两条路（见 drop-in 里的注释）：
    #   · DisplayServer=x11 + 删掉整个 [Wayland] 段，走 X11 greeter
    #   · 不装 SDDM，TTY 登录后手动 niri-session（shorin-niri-main 的做法）
    print_info "Installing SDDM and dependencies..."
    local -a sddm_pkgs=(
        sddm
        qt5-declarative qt5-quickcontrols qt5-quickcontrols2
        # qt5-svg 是 QML Image 加载 .svg 的插件，缺了图标全空白（背景/头像是位图所以正常）
        qt5-svg
        qt5-wayland qt6-wayland
        kwin
    )
    if sudo pacman -S --needed --noconfirm "${sddm_pkgs[@]}" >> "$LOG_FILE" 2>&1; then
        print_ok "SDDM installed"
    else
        print_fail "Failed to install SDDM (看 $LOG_FILE)"
        return
    fi

    # ---- 2. 关掉其它显示管理器，避免抢 tty1 ----
    local other_dm
    for other_dm in ly@tty1 ly gdm lightdm greetd; do
        if systemctl is-enabled "$other_dm" &>/dev/null; then
            print_info "禁用冲突的 $other_dm"
            sudo systemctl disable "$other_dm" >> "$LOG_FILE" 2>&1 || true
        fi
    done

    # ---- 3. 安装主题 ----
    local theme_name="lunar-glass"
    local theme_src="$DOTFILES_DIR/sddm-theme"
    local theme_dst="/usr/share/sddm/themes/$theme_name"

    if [[ ! -d "$theme_src" ]]; then
        print_warn "主题目录不存在：$theme_src，跳过主题安装"
    else
        print_info "Installing SDDM theme: $theme_name"
        if [[ -d "$theme_dst" ]]; then
            sudo mv "$theme_dst" "${theme_dst}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
        fi
        sudo mkdir -p "$theme_dst"
        # 整个目录拷过去（含 icons/）。主题自己的 README.md 一并带过去，方便以后在
        # /usr/share/sddm/themes 里对着看。
        if sudo cp -rf "$theme_src"/. "$theme_dst"/ 2>>"$LOG_FILE"; then
            print_ok "Theme files copied to $theme_dst"
        else
            print_warn "主题拷贝有报错，看 $LOG_FILE"
        fi
    fi

    # ---- 4. 写配置（drop-in，不覆盖 /etc/sddm.conf）----
    local dropin_dir="/etc/sddm.conf.d"
    local dropin="$dropin_dir/10-lunar-glass.conf"
    print_info "Configuring SDDM (wayland + kwin_wayland greeter, theme: $theme_name)"
    sudo mkdir -p "$dropin_dir"
    sudo tee "$dropin" > /dev/null << EOF
# 由 Pullautumn dotfiles 的 setup_sddm 生成。
# 想临时换回 TTY 登录：sudo systemctl disable sddm && sudo systemctl enable ly@tty1
[General]
DisplayServer=wayland

[Wayland]
# kwin_wayland 是上游 jswysnemc 的默认值，也是这套配置唯一有实机验证记录的 greeter。
# 三个开关：不接管锁屏、不抢全局快捷键、不覆盖系统语言环境。
# 不想装 kwin 就把整个 [Wayland] 段删掉，并把上面的 DisplayServer 改成 x11
# （需要 xorg-server xorg-xauth，装 sddm 时一般已作为依赖带进来）。
CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1

[Theme]
Current=$theme_name
EOF
    print_ok "Wrote $dropin"

    # ---- 5. 启用（不 start）----
    if sudo systemctl enable sddm >> "$LOG_FILE" 2>&1; then
        print_ok "sddm enabled（重启后生效，没 start 所以当前会话不受影响）"
    else
        print_warn "Failed to enable sddm"
    fi

    print_info "如果开机停在黑屏：Ctrl+Alt+F2 进 TTY，然后"
    print_info "  sudo systemctl disable sddm && sudo systemctl enable --now ly@tty1"

    # ---- 6. 只读自检 ----
    # 以前写完 drop-in 就 mark_done，日志只留一句 "SDDM configured"；
    # 主题没拷过去、greeter 二进制不存在这类问题要等重启黑屏才发现。
    # 这里只检查、不修、不 start：不通过就给 WARN 且不标记完成，重跑会再走一遍。
    local sddm_check_failed=0 compositor_bin=""
    compositor_bin=$(grep -E '^CompositorCommand=' "$dropin" 2>/dev/null \
        | head -1 | cut -d= -f2- | awk '{print $1}') || compositor_bin=""

    if [[ ! -f "$theme_dst/metadata.desktop" ]]; then
        print_warn "SDDM 自检：主题缺 metadata.desktop（$theme_dst）"
        sddm_check_failed=1
    fi
    if [[ -z "$compositor_bin" ]]; then
        print_warn "SDDM 自检：drop-in 里没读到 CompositorCommand"
        sddm_check_failed=1
    elif ! command -v "$compositor_bin" >/dev/null 2>&1; then
        print_warn "SDDM 自检：greeter 合成器不存在（$compositor_bin）"
        sddm_check_failed=1
    fi
    if ! pacman -Q qt5-svg >/dev/null 2>&1; then
        print_warn "SDDM 自检：qt5-svg 未安装（QML 里的 svg 图标会空白）"
        sddm_check_failed=1
    fi
    if ! grep -qF "Current=$theme_name" "$dropin" 2>/dev/null; then
        print_warn "SDDM 自检：drop-in 里没有 Current=$theme_name"
        sddm_check_failed=1
    fi
    if ! systemctl is-enabled sddm >/dev/null 2>&1; then
        print_warn "SDDM 自检：sddm 未设为开机自启"
        sddm_check_failed=1
    fi

    if (( sddm_check_failed > 0 )); then
        SDDM_SELFCHECK_FAILED=true
        print_warn "SDDM 自检未全通过，不标记本阶段完成；修好后重跑安装器即可"
        log "SDDM self-check FAILED"
        return 0
    fi

    SDDM_SELFCHECK_FAILED=false
    print_ok "SDDM 自检通过（主题 / greeter / qt5-svg / drop-in / 自启）"
    log "SDDM self-check passed"
    mark_done "setup_sddm"
    log "SDDM configured"
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
