# shellcheck shell=bash

# 统一安装器：与 jswysnemc 原版一致，仓库包与 AUR 包一律走 AUR helper。
# 只有 --no-aur 让 AUR_HELPER 为空时，才退回 pacman。
_resolve_installer() {
    if [[ -z "$AUR_HELPER" ]]; then
        AUR_HELPER="sudo pacman"
    fi
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
        echo -e "         ${DIM}$packages${NC}"

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
        if $AUR_HELPER -S --needed --noconfirm $packages >> "$LOG_FILE" 2>&1; then
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
        echo -e "   ${DIM}${AUR_PACKAGES[*]}${NC}"
        echo ""

        local aur_opts=(-S --needed)
        if [[ "$AUR_HELPER" == "paru" ]]; then
            aur_opts+=(--skipreview)
        fi

        if [[ "${ASSUME_YES:-false}" == "true" ]]; then
            print_info "Installing AUR packages (--yes mode, no prompts)"
            if $AUR_HELPER "${aur_opts[@]}" --noconfirm "${AUR_PACKAGES[@]}" >> "$LOG_FILE" 2>&1; then
                mark_done "aur_packages"
                print_ok "AUR packages installed"
            else
                print_warn "Some AUR packages failed (check log)"
            fi
        elif confirm "安装 ${#AUR_PACKAGES[@]} 个 AUR 包？（会逐个询问）" "n"; then
            # 交互安装：逐个 AUR 包让 paru 自己确认（provider 选择、PKGBUILD 审阅等）
            print_info "AUR 包会逐个询问，请按需确认（paru 可能还会问 provider 选择）"
            echo ""

            local pkg aur_failed=0
            for pkg in "${AUR_PACKAGES[@]}"; do
                if is_done "aur_$pkg"; then
                    echo -e "   ${GREEN}[OK]${NC} $pkg ${DIM}(done)${NC}"
                    continue
                fi

                print_info "安装 $pkg"
                local aur_rc=0
                if _tty_ok; then
                    $AUR_HELPER "${aur_opts[@]}" "$pkg" < /dev/tty || aur_rc=$?
                else
                    $AUR_HELPER "${aur_opts[@]}" "$pkg" || aur_rc=$?
                fi

                if [[ $aur_rc -eq 0 ]]; then
                    mark_done "aur_$pkg"
                    print_ok "$pkg"
                else
                    print_warn "$pkg 安装失败（可能已跳过）"
                    aur_failed=$((aur_failed + 1))
                fi
            done

            if [[ $aur_failed -eq 0 ]]; then
                mark_done "aur_packages"
            else
                print_warn "$aur_failed 个 AUR 包未装成功（见日志）"
            fi
        else
            print_skip "AUR packages (user declined)"
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

# 逐项询问是否安装；被选中的条目写入 stdout（一行一个）
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
    echo -e "   ${DIM}逐项确认：y = 安装 ｜ n 或回车 = 跳过 ｜ 全部完成后自动继续${NC}" >&2

    # 交互输入走 fd9：终端可用时读 /dev/tty，否则读 stdin 的副本，
    # 避免与下面的 while read 抢同一路输入。
    local tty_ok=false input_file=""
    _tty_ok && tty_ok=true
    if ! $tty_ok; then
        input_file=$(mktemp)
        cat > "$input_file"
        exec 9< "$input_file"
    fi

    local line name desc idx=0 picked=0 answer
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        idx=$((idx + 1))
        name=$(printf '%s' "$line" | cut -f1 | xargs)
        desc=$(printf '%s' "$line" | cut -f2 | sed 's/^#[[:space:]]*//')
        [[ -z "$name" ]] && continue

        echo "" >&2
        printf "   ${DIM}[%2d/%d]${NC} %-38s ${DIM}%s${NC}\n" \
            "$idx" "$count" "$name" "$desc" >&2
        printf "   ${YELLOW}[?]${NC} 安装 %s？[y/N]: " "${name}" >&2

        answer=""
        if $tty_ok; then
            read -r answer < /dev/tty || break
        else
            read -r -u 9 answer || break
        fi

        case "$answer" in
            [yY]*)
                printf '%s\n' "$line"
                picked=$((picked + 1))
                ;;
        esac
    done <<< "$entries"

    if ! $tty_ok; then
        exec 9<&-
        rm -f "$input_file"
    fi

    echo "" >&2
    print_info "已选 $picked 项" >&2
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
        echo ""
        echo -e "   ${CYAN}>>> 仓库包${NC} ${DIM}(${#OPT_REPO[@]} 个)${NC}"
        echo -e "       ${DIM}${OPT_REPO[*]}${NC}"

        if $AUR_HELPER -S --needed --noconfirm "${OPT_REPO[@]}" >> "$LOG_FILE" 2>&1; then
            print_ok "仓库包安装完成"
        else
            print_warn "部分仓库包安装失败（见日志）"
            failed=$((failed + 1))
        fi
    fi

    # --- AUR ---
    if [[ ${#OPT_AUR[@]} -gt 0 ]]; then
        echo ""
        echo -e "   ${CYAN}>>> AUR 包${NC} ${DIM}(${#OPT_AUR[@]} 个)${NC}"
        echo -e "       ${DIM}${OPT_AUR[*]}${NC}"

        if [[ -z "$AUR_HELPER" ]]; then
            print_warn "没有可用的 AUR helper，跳过 AUR 包"
            failed=$((failed + 1))
        else
            local aur_opts=(-S --needed)
            if [[ "$AUR_HELPER" == "paru" ]]; then
                aur_opts+=(--skipreview)
            fi

            local aur_rc=0
            if _tty_ok; then
                $AUR_HELPER "${aur_opts[@]}" "${OPT_AUR[@]}" < /dev/tty || aur_rc=$?
            else
                $AUR_HELPER "${aur_opts[@]}" "${OPT_AUR[@]}" || aur_rc=$?
            fi

            if [[ $aur_rc -eq 0 ]]; then
                print_ok "AUR 包安装完成"
            else
                print_warn "部分 AUR 包安装失败"
                failed=$((failed + 1))
            fi
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
