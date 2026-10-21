# shellcheck shell=bash

# 统一安装器：与 jswysnemc 原版一致，仓库包与 AUR 包一律走 AUR helper。
# 只有 paru/yay 都不可用时（极端情况），才退回 pacman。
_resolve_installer() {
    if [[ -z "$AUR_HELPER" ]]; then
        AUR_HELPER="sudo pacman"
    fi
}

# 逐个安装软件包：已装过的直接标 OK，不再重新装；每个包单独一行进度。
# 用法：_install_each "标题" 包名...
# 返回值为失败个数
_install_each() {
    local title="$1"
    shift

    local -a pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0

    local -a cmd=($AUR_HELPER -S --needed --noconfirm)
    if [[ "$AUR_HELPER" == "paru" ]]; then
        cmd=($AUR_HELPER -S --needed --skipreview --noconfirm)
    fi

    echo ""
    echo -e "   ${CYAN}>>> ${title}${NC} ${DIM}(${#pkgs[@]} 个)${NC}"

    local failed=0 p
    for p in "${pkgs[@]}"; do
        if pacman -Q "$p" &>/dev/null; then
            echo -e "   ${GREEN}[OK]${NC} $p ${DIM}(已安装)${NC}"
            continue
        fi

        echo -e "   ${YELLOW}[i]${NC} 安装 $p"
        exe_spin "$p" "${cmd[@]}" "$p" || failed=$((failed + 1))
    done

    return $failed
}

install_packages() {
    section "Phase 4" "Install Packages"

    _resolve_installer
    local total=${#PKG_GROUP_NAMES[@]}
    local current=0
    local failed=0

    echo -e "   Installing ${WHITE}$total${NC} package groups..."
    echo ""

    for group_info in "${PKG_GROUP_NAMES[@]}"; do
        IFS=':' read -r key name <<< "$group_info"
        current=$((current + 1))
        local packages="${PKG_GROUPS[$key]}"

        if [[ -z "$packages" ]]; then
            continue
        fi

        # Check if already done
        if is_done "pkg_$key"; then
            echo -e "   ${GREEN}[${current}/${total}]${NC} $name ${DIM}(done)${NC}"
            continue
        fi

        echo -e "   ${CYAN}[${current}/${total}]${NC} $name"

        # 先看这一组里哪些真的没装，全都装了就直接算成功
        local -a want=()
        local p
        for p in $packages; do
            pacman -Q "$p" &>/dev/null || want+=("$p")
        done

        if [[ ${#want[@]} -eq 0 ]]; then
            echo -e "         ${DIM}$packages${NC}"
            printf "         ${GREEN}[OK]${NC} 已安装，跳过            \n"
            mark_done "pkg_$key"
            continue
        fi

        echo -e "         ${DIM}${want[*]}${NC}"

        # Spinner
        local spin_pid
        (
            local i=0
            local chars='|/-\'
            while true; do
                printf "\r         \033[0;33m[%c]\033[0m Installing..." "${chars:$i:1}"
                i=$(( (i + 1) % 4 ))
                sleep 0.12
            done
        ) &
        spin_pid=$!

        local result=0
        if $AUR_HELPER -S --needed --noconfirm "${want[@]}" >> "$LOG_FILE" 2>&1; then
            result=0
        else
            result=1
        fi

        kill "$spin_pid" 2>/dev/null
        wait "$spin_pid" 2>/dev/null || true

        if [[ $result -eq 0 ]]; then
            printf "\r         ${GREEN}[OK]${NC} Done            \n"
            mark_done "pkg_$key"
        else
            printf "\r         ${RED}[FAIL]${NC} Error          \n"
            failed=$((failed + 1))
        fi
    done

    echo ""
    if [[ $failed -gt 0 ]]; then
        print_warn "$failed group(s) had errors (check log)"
    else
        print_ok "All core packages installed"
    fi

    # AUR packages
    section "Phase 4b" "AUR Packages"

    if [[ -z "$AUR_HELPER" ]]; then
        print_skip "AUR packages (no AUR helper available)"
    elif is_done "aur_packages"; then
        print_skip "AUR packages (already done)"
    else
        # 逐个装、逐个显示，全程不再询问（已装的直接标 OK）
        local aur_failed=0
        _install_each "AUR 包" "${AUR_PACKAGES[@]}" || aur_failed=$?

        echo ""
        if [[ $aur_failed -eq 0 ]]; then
            mark_done "aur_packages"
            print_ok "AUR 包全部就绪"
        else
            print_warn "$aur_failed 个 AUR 包未装成功（见日志）"
        fi
    fi

    log "Packages installed"
}

# ==============================================================================
# 可选软件
# ==============================================================================
# 清单来源：setup/common-applist.txt
# 前缀约定：AUR:xxx / flatpak:xxx / 无前缀 = 官方仓库
# ==============================================================================

# 供列表显示的输入：<包名>\t<# 说明>
_optional_entries() {
    local list_file="$COMMON_APPLIST"

    [[ -f "$list_file" ]] || return 1

    grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$list_file" \
        | sed -E 's/[[:space:]]+#/\t#/' \
        | sed -E 's/[[:space:]]+$//'
}

# fzf 多选；被选中的条目写入 stdout（一行一个），提示信息一律走 stderr
_optional_select() {
    local entries
    if ! entries=$(_optional_entries); then
        print_warn "未找到可选清单: $COMMON_APPLIST"
        return 1
    fi

    if [[ -z "$entries" ]]; then
        print_warn "可选清单为空: $COMMON_APPLIST"
        return 1
    fi

    local count
    count=$(printf '%s\n' "$entries" | wc -l)

    echo "" >&2
    echo -e "   ${WHITE}可选软件${NC} ${DIM}(清单共 ${count} 项)${NC}" >&2
    echo -e "   ${DIM}Tab / Shift-Tab 多选 ｜ Enter 确认 ｜ Esc 全部跳过 ｜ 空确认 = 全不装${NC}" >&2

    if ! command -v fzf >/dev/null 2>&1; then
        print_warn "未找到 fzf，跳过可选软件（需要全装可改用 --yes）"
        return 1
    fi

    if ! _tty_ok; then
        print_warn "当前没有可用终端，跳过可选软件（无人值守请用 --yes）"
        return 1
    fi

    # fzf 的列表从 stdin 管道读，界面自动挂到 /dev/tty，故不加 < /dev/tty
    local selected
    selected=$(printf '%s\n' "$entries" | fzf \
        --multi \
        --layout=reverse \
        --height=90% \
        --border \
        --no-info \
        --delimiter='\t' \
        --with-nth=1,2 \
        --pointer='▶' \
        --marker='✓' \
        --header="选择要安装的软件（Tab 多选，Enter 确认）" \
        --prompt="可选软件 > " 2>/dev/tty)

    echo "" >&2
    if [[ -z "$selected" ]]; then
        print_info "未选择任何软件" >&2
        return 0
    fi

    local picked
    picked=$(printf '%s\n' "$selected" | wc -l)
    print_info "已选 $picked 项" >&2

    printf '%s\n' "$selected"
    return 0
}

# 把选中行解析进 OPT_REPO / OPT_AUR / OPT_FLATPAK
_optional_collect() {
    local selected="$1"
    local line raw

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        raw=$(printf '%s' "$line" | cut -f1 | xargs)
        [[ -z "$raw" ]] && continue

        case "$raw" in
            AUR:*)     OPT_AUR+=("${raw#AUR:}") ;;
            flatpak:*) OPT_FLATPAK+=("${raw#flatpak:}") ;;
            *)         OPT_REPO+=("$raw") ;;
        esac
    done <<< "$selected"
}

# 按来源分组安装（使用 _optional_collect 填充的数组）
_optional_install() {
    local failed=0

    _resolve_installer

    # --- 官方仓库 ---
    if [[ ${#OPT_REPO[@]} -gt 0 ]]; then
        local repo_rc=0
        _install_each "仓库包" "${OPT_REPO[@]}" || repo_rc=$?
        failed=$((failed + repo_rc))
    fi

    # --- AUR ---
    if [[ ${#OPT_AUR[@]} -gt 0 ]]; then
        if [[ -z "$AUR_HELPER" ]]; then
            print_warn "没有可用的 AUR helper，跳过 AUR 包"
            failed=$((failed + 1))
        else
            local aur_rc=0
            _install_each "AUR 包" "${OPT_AUR[@]}" || aur_rc=$?
            failed=$((failed + aur_rc))
        fi
    fi

    # --- Flatpak ---
    if [[ ${#OPT_FLATPAK[@]} -gt 0 ]]; then
        echo ""
        echo -e "   ${CYAN}>>> Flatpak 应用${NC} ${DIM}(${#OPT_FLATPAK[@]} 个)${NC}"

        if _ensure_flatpak; then
            local app
            for app in "${OPT_FLATPAK[@]}"; do
                _flatpak_install_one "$app" || failed=$((failed + 1))
            done
        else
            print_warn "flatpak 未就绪，跳过 flatpak 应用"
            failed=$((failed + 1))
        fi
    fi

    echo ""
    if [[ $failed -eq 0 ]]; then
        print_ok "可选软件处理完成"
    else
        print_warn "有 $failed 组可选软件未装成功（见日志）"
    fi
}

install_optional_packages() {
    section "Phase 4c" "可选软件"

    if $INSTALL_MINIMAL; then
        print_skip "可选软件（--minimal 跳过）"
        return 0
    fi

    if is_done "optional_packages"; then
        print_skip "可选软件（已完成）"
        return 0
    fi

    local selected=""
    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
        # --yes：不弹勾选界面，清单里的全部装上
        local all_entries
        all_entries=$(_optional_entries) || return 0
        selected=$(printf '%s\n' "$all_entries" | cut -f1)
        print_info "--yes 模式：安装清单内全部 $(wc -l <<< "$selected") 项可选软件"
    else
        selected=$(_optional_select) || return 0
    fi

    if [[ -z "$selected" ]]; then
        print_info "没有选择任何软件，跳过安装"
        return 0
    fi

    OPT_REPO=()
    OPT_AUR=()
    OPT_FLATPAK=()
    _optional_collect "$selected"

    echo ""
    print_info "已选择 $(( ${#OPT_REPO[@]} + ${#OPT_AUR[@]} + ${#OPT_FLATPAK[@]} )) 个软件，开始安装"
    _optional_install

    mark_done "optional_packages"
    log "Optional: ${OPT_REPO[*]:-} ${OPT_AUR[*]:-} ${OPT_FLATPAK[*]:-}"
}
