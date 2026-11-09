# shellcheck shell=bash

# ------------------------------------------------------------------------------
# sudo 保活
# 整个安装流程远超 sudo 默认的 15 分钟时间戳，中途会反复要密码。这里只在**本次
# 运行内**缓存凭证：不改 /etc/sudoers、不做免密，脚本退出后行为完全恢复默认。
# ------------------------------------------------------------------------------
SUDO_KEEPALIVE_PID=""

stop_sudo_keepalive() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        SUDO_KEEPALIVE_PID=""
    fi
}

start_sudo_keepalive() {
    print_info "接下来只需输入一次 sudo 密码（仅本次安装有效）"
    if ! sudo -v; then
        print_fail "sudo 验证失败"
        exit 1
    fi

    # sudo -n 不交互，失败也不会弹密码，只用来刷新时间戳
    ( while true; do sudo -n true 2>/dev/null || true; sleep 50; done ) &
    SUDO_KEEPALIVE_PID=$!
    print_ok "sudo 凭证已缓存"
}

# ------------------------------------------------------------------------------
# pacman 残留锁
# 强制重启留下的 db.lck 可以直接删；但真有包管理器在跑时删锁会损坏数据库，
# 所以先确认没有活进程，等 60 秒仍不结束就报错退出，绝不强删。
# ------------------------------------------------------------------------------
_pkg_manager_running() {
    pgrep -x pacman >/dev/null 2>&1 \
        || pgrep -x paru >/dev/null 2>&1 \
        || pgrep -x yay >/dev/null 2>&1 \
        || pgrep -x pamac >/dev/null 2>&1
}

clear_pacman_lock() {
    local lock=/var/lib/pacman/db.lck
    [[ -f "$lock" ]] || return 0

    if _pkg_manager_running; then
        print_warn "检测到包管理器正在运行，等待其结束（最多 60 秒）"
        local i
        for i in $(seq 1 60); do
            _pkg_manager_running || break
            sleep 1
        done
        if _pkg_manager_running; then
            print_fail "包管理器仍在运行，不删除锁文件（强删会损坏数据库）"
            print_info "等它结束后重跑：./install.sh"
            exit 1
        fi
        print_ok "包管理器已结束"
    fi

    print_warn "清理 pacman 残留锁（上次强制重启遗留）"
    sudo rm -f "$lock"
    print_ok "Lock removed"
}

check_system() {
    section "Pre-Flight" "System Check"

    local checks=(
        "Arch Linux:/etc/arch-release:file"
        "Non-root:0:notroot"
        "Pacman:pacman:cmd"
    )

    local failed=false

    for check in "${checks[@]}"; do
        IFS=':' read -r name target type <<< "$check"

        local result=false
        case "$type" in
            file)   [[ -f "$target" ]] && result=true ;;
            notroot) [[ $EUID -ne 0 ]] && result=true ;;
            ping)   ping -c 1 -W 3 "$target" &>/dev/null && result=true ;;
            cmd)    command_exists "$target" && result=true ;;
        esac

        if $result; then
            print_ok "$name"
        else
            print_fail "$name"
            failed=true
        fi
    done

    # 网络单独判断：国内优先探测阿里 DNS，不通再试 Google DNS
    if ping -c 1 -W 3 223.5.5.5 &>/dev/null || ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        print_ok "Network"
    else
        print_warn "Network unreachable (可以继续，但 pacman 会失败)"
    fi

    if $failed; then
        echo ""
        print_fail "System check failed. Exiting."
        print_info "请以普通用户（非 root）在 Arch Linux 上运行：./install.sh"
        exit 1
    fi

    if [[ $EUID -eq 0 ]]; then
        print_fail "Do not run this script as root."
        exit 1
    fi

    # 锁在装任何东西之前处理；凭证也只在这里问一次，后面全程复用
    clear_pacman_lock
    start_sudo_keepalive

    # 上一轮若中断（断电 / kill -9 / 强制关窗）会留下镜像配置，
    # 本轮没打算启用就先清掉，避免「偷偷常驻」到用户察觉不到的地步。
    if [[ -f "$ROOT_DIR/local-bin/.local/bin/gh-mirror" ]]; then
        if bash "$ROOT_DIR/local-bin/.local/bin/gh-mirror" stale-check --quiet; then
            print_warn "检测到上次安装遗留的 GitHub 镜像配置，已自动清除"
            log "Stale gh-mirror config cleaned"
        fi
    fi

    # AUR 包（makepkg 的 curl + *-git 包的 git clone）、Anime4K、yazi 插件
    # 全都依赖 github.com。在这里一次性修好，后面所有阶段都受益；
    # 修不好也不中断，交给 Phase 4b 的交互闸门决定是否跳过 AUR。
    #
    # 镜像与 hosts 是两种不同的药，不能互相替代：
    #   · hosts 治 DNS 污染（解析到错 IP，curl 报 (6)）
    #   · 镜像治链路阻断（能解析但连不上，curl 报 (7)）
    # 镜像已开着就说明走的是另一条路，hosts 修补没有意义，跳过。
    if [[ "${PULLAUTUMN_MIRROR:-off}" == "on" ]]; then
        print_ok "GitHub 镜像加速已启用，跳过 /etc/hosts 修补"
        log "GitHub mirror active; skip hosts patch"
    else
        ensure_github_reachable || true
    fi

    log "System check passed"
}

install_base() {
    section "Phase 1" "Base Tools"

    if is_done "base_tools"; then
        print_skip "Base tools (already done)"
        return
    fi

    # 锁与 sudo 凭证已在 check_system 处理，这里不再重复询问

    exe_live "Updating system" "sudo pacman -Syu --noconfirm"
    exe_live "Installing base tools" "sudo pacman -S --needed --noconfirm git stow base-devel"

    mark_done "base_tools"
    log "Base tools installed"
}

install_aur_helper() {
    section "Phase 2" "AUR Helper (paru)"

    if command_exists paru; then
        print_ok "paru already installed"
        AUR_HELPER="paru"
        return
    elif command_exists yay; then
        print_ok "yay already installed"
        AUR_HELPER="yay"
        return
    fi

    if is_done "aur_helper"; then
        print_skip "AUR helper (already done)"
        AUR_HELPER="paru"
        return
    fi

    print_info "Adding archlinuxcn repository (BFSU mirror)..."

    # Add archlinuxcn repo if not exists
    if ! grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
        sudo tee -a /etc/pacman.conf > /dev/null << 'REPO'

[archlinuxcn]
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch
REPO
        print_ok "archlinuxcn repo added"
    else
        print_info "archlinuxcn repo exists"
    fi

    exe_live "Syncing pacman database" "sudo pacman -Syu"
    exe_live "Installing archlinuxcn-keyring" "sudo pacman -S --noconfirm archlinuxcn-keyring"
    exe_live "Installing paru" "sudo pacman -S --noconfirm paru"

    AUR_HELPER="paru"
    mark_done "aur_helper"
    print_ok "paru installed via archlinuxcn"
    log "AUR helper installed"
}

clone_dotfiles() {
    section "Phase 3" "Locate Dotfiles"

    # 脚本本身就在仓库里运行（本地安装）：直接使用当前仓库，避免重复克隆
    if [[ -f "$ROOT_DIR/install.sh" && -d "$ROOT_DIR/niri/.config/niri" ]]; then
        DOTFILES_DIR="$ROOT_DIR"
        print_ok "使用本地仓库: $DOTFILES_DIR"
        mark_done "clone_dotfiles"
        return
    fi

    # 由 install.sh 引导克隆而来
    if [[ "${DOTFILES_JUST_CLONED:-}" == "1" ]]; then
        print_ok "Repository cloned (bootstrap)"
        mark_done "clone_dotfiles"
        return
    fi

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        print_info "Directory exists: $DOTFILES_DIR"
        if confirm "Update existing repo?"; then
            if exe "cd '$DOTFILES_DIR' && git pull --ff-only"; then
                print_ok "Repository updated"
            else
                print_warn "Update failed, continuing with local copy..."
            fi
        fi
        return
    fi

    # 目录存在但不是 git 仓库：非空则拒绝处理，避免掉进下面的重试逻辑被 rm -rf 清掉
    if [[ -d "$DOTFILES_DIR" ]]; then
        if [[ -n "$(ls -A "$DOTFILES_DIR" 2>/dev/null)" ]]; then
            print_fail "$DOTFILES_DIR 已存在但不是 git 仓库，且非空"
            print_info "请先手动移走它（如 mv ~/.dotfiles ~/.dotfiles.bak）后重跑"
            exit 1
        fi
        rmdir "$DOTFILES_DIR" 2>/dev/null || true
    fi

    if is_done "clone_dotfiles"; then
        print_skip "Clone dotfiles (already done)"
        return
    fi

    # 大仓库 / 网络不稳时的 git 参数
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 1000
    git config --global http.lowSpeedTime 60

    local max_retries=3
    local retry=0
    # 记录 clone 前该目录是否存在，重试清理时只删本次新建的半成品
    local dst_preexisted=false
    if [[ -e "$DOTFILES_DIR" ]]; then
        dst_preexisted=true
    fi

    while [[ $retry -lt $max_retries ]]; do
        retry=$((retry + 1))
        print_info "Clone attempt $retry/$max_retries"

        if exe "git clone --depth 1 '$DOTFILES_REPO' '$DOTFILES_DIR'"; then
            exe "cd '$DOTFILES_DIR' && git fetch --unshallow" || true
            print_ok "Repository cloned"
            mark_done "clone_dotfiles"
            log "Dotfiles cloned"
            return 0
        fi

        # 只清理本次 clone 留下的半成品，绝不碰用户原有目录
        if [[ "$dst_preexisted" == "false" ]]; then
            rm -rf "$DOTFILES_DIR" 2>/dev/null || true
        fi
        if [[ $retry -lt $max_retries ]]; then
            sleep 3
        fi
    done

    print_fail "Clone failed after $max_retries attempts"
    print_info "Try: git clone $DOTFILES_REPO $DOTFILES_DIR"
    exit 1
}
