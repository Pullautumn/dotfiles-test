# shellcheck shell=bash

# ==============================================================================
# Flatpak 运行时辅助
# ==============================================================================
# 可选软件清单里可能有 flatpak: 前缀的项，安装前需要确保 flatpak 本体和
# flathub 源就绪。这里提供按需准备的能力，不做成独立阶段——没人选 flatpak
# 应用时就不必装 flatpak。
# ==============================================================================

# flathub 镜像（国内加速）
_select_flathub_mirror() {
    local names=(
        "官方源 (dl.flathub.org)"
        "上海交大镜像 (mirror.sjtu.edu.cn)"
        "中科大镜像 (mirrors.ustc.edu.cn)"
    )
    local urls=(
        "https://dl.flathub.org/repo/"
        "https://mirror.sjtu.edu.cn/flathub"
        "https://mirrors.ustc.edu.cn/flathub"
    )

    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
        return 0
    fi

    echo ""
    echo -e "   ${WHITE}选择 Flathub 镜像源（20 秒无操作走官方源）${NC}"
    local i
    for i in "${!names[@]}"; do
        echo -e "      ${CYAN}[$((i + 1))]${NC} ${names[$i]}"
    done
    echo ""

    local choice=""
    printf "   请选择 [1-%d]: " "${#names[@]}"
    if _tty_ok; then
        read -r -t 20 choice < /dev/tty || true
    fi
    echo ""

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#names[@]} )); then
        print_info "使用官方源"
        return 0
    fi

    local url="${urls[$((choice - 1))]}"
    print_info "切换 flathub 到 ${names[$((choice - 1))]}"
    sudo flatpak remote-modify flathub --url="$url" >> "$LOG_FILE" 2>&1 \
        && print_ok "镜像已切换" \
        || print_warn "镜像切换失败，继续用当前源"
}

# 确保 flatpak 与 flathub 源可用；失败返回 1
_ensure_flatpak() {
    if ! command_exists flatpak; then
        print_info "安装 flatpak..."
        if ! sudo pacman -S --needed --noconfirm flatpak >> "$LOG_FILE" 2>&1; then
            print_warn "flatpak 安装失败"
            return 1
        fi
    fi

    if ! flatpak remotes 2>/dev/null | grep -qw flathub; then
        print_info "添加 flathub 源..."
        if ! sudo flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1; then
            print_warn "flathub 源添加失败（网络问题？可稍后手动添加）"
            return 1
        fi
        _select_flathub_mirror
    fi

    return 0
}

# 安装单个 flatpak 应用（已装则跳过）
_flatpak_install_one() {
    local app="$1"

    if flatpak info "$app" &>/dev/null; then
        echo -e "   ${GREEN}[OK]${NC} $app ${DIM}(installed)${NC}"
        return 0
    fi

    if sudo flatpak install -y --noninteractive flathub "$app" >> "$LOG_FILE" 2>&1; then
        echo -e "   ${GREEN}[OK]${NC} $app"
        return 0
    fi

    echo -e "   ${RED}[FAIL]${NC} $app"
    return 1
}
