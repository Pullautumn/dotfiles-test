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
        if exe_spin "$p" "${cmd[@]}" "$p"; then
            :
        else
            failed=$((failed + 1))
            FAILED_PACKAGES+=("$p")
        fi
    done

    return $failed
}

# AUR 前置网络闸门
# 01-preflight 已经尝试用 hosts 修过一次；这里再测一次，仍不通就别让 12 个包
# 逐个超时 21 秒再一起失败 —— 那既浪费时间，也会把"装成功了"的假象留给用户。
# 返回 0 = 继续装 AUR，1 = 跳过
_aur_network_gate() {
    # 安装开头已经问过并启用了镜像：后面一律不再问，也不重复探测。
    # 这里直接放行是安全的 —— 镜像真的不可用时，失败包会进补装清单。
    if [[ "${PULLAUTUMN_MIRROR:-off}" == "on" ]]; then
        print_ok "GitHub 镜像加速生效中，AUR 包直接安装"
        log "AUR gate: mirror active, continue"
        return 0
    fi

    if _gh_reachable; then
        return 0
    fi

    echo ""
    print_warn "GitHub 仍不可达，AUR 包会逐个超时失败"
    print_info "  1) 继续尝试"
    print_info "  2) 跳过 AUR 包（推荐）"
    print_info "  3) 退出安装，先配好代理再重跑"

    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
        print_warn "非交互模式（--yes）：自动跳过 AUR 包"
        return 1
    fi

    local choice=""
    echo -ne "   ${YELLOW}[?]${NC} 选择 [1/2/3，默认 2]: "
    if _tty_ok; then
        read -r choice < /dev/tty || choice=""
    else
        read -r choice || choice=""
    fi

    case "${choice:-2}" in
        1) print_warn "继续，预计大量失败"; return 0 ;;
        3)
            print_fail "已退出。配置代理后重跑：sudo -E ./install.sh"
            exit 1
            ;;
        *) print_skip "跳过 AUR 包"; return 1 ;;
    esac
}

# 装完统一核对：把 21 个包组 + AUR 清单展开去重后交给 pacman -T，
# 它会把「未安装或不满足」的条目原样打出来。
# 注意 pacman -T 不认包组名：PKG_GROUPS[input] 里的 fcitx5-im 会被原样打成
# "缺失"（日志体检那次 5/107 里就有 1 个是它，实际组内 4 个成员早就装好了）。
# 所以核对前先用 pacman -Sgq 把组展开成成员包名，再一并交给 -T。
_verify_installed_packages() {
    local -a all=() to_check=() missing=()
    local seen=" " group_info key p members m

    for group_info in "${PKG_GROUP_NAMES[@]}"; do
        IFS=':' read -r key _ <<< "$group_info"
        for p in ${PKG_GROUPS[$key]}; do
            [[ "$seen" == *" $p "* ]] && continue
            seen+="$p "
            all+=("$p")
        done
    done

    for p in "${AUR_PACKAGES[@]}"; do
        [[ "$seen" == *" $p "* ]] && continue
        seen+="$p "
        all+=("$p")
    done

    # 展开包组；普通包名 pacman -Sgq 返回空，原样保留
    for p in "${all[@]}"; do
        members=$(pacman -Sgq "$p" 2>/dev/null) || members=""
        if [[ -n "$members" ]]; then
            log "package group expanded for verification: $p"
            while IFS= read -r m; do
                [[ -n "$m" ]] && to_check+=("$m")
            done <<< "$members"
        else
            to_check+=("$p")
        fi
    done

    # 组成员可能与清单里其它包名重复，去重后再核对
    mapfile -t to_check < <(printf '%s\n' "${to_check[@]}" | sort -u)

    mapfile -t missing < <(pacman -T "${to_check[@]}" 2>/dev/null | sed '/^[[:space:]]*$/d')
    MISSING_PACKAGES=("${missing[@]}")

    if [[ ${#missing[@]} -eq 0 ]]; then
        print_ok "包核对通过：${#to_check[@]} 项全部就绪（清单 ${#all[@]} 条，组已展开）"
        log "Package verification passed: ${#to_check[@]} items from ${#all[@]} entries"
        return 0
    fi

    echo ""
    print_fail "包核对：${#missing[@]}/${#to_check[@]} 项未安装（清单 ${#all[@]} 条，组已展开为成员）"
    printf '         %s\n' "${missing[@]}"
    print_info "补装：paru -S --needed ${missing[*]}"
    log "MISSING PACKAGES (${#missing[@]}/${#to_check[@]}): ${missing[*]}"
    write_pending_list || true
    return 1
}

# 待补装清单：终端会滚过去、重启后又看不到，所以把没装上的包落盘成 .txt。
# 文件内容只有一行是命令，其余全是注释 —— 开机后整段复制粘贴即可补装。
write_pending_list() {
    local -a pending=()
    local seen=" " p helper install_cmd

    for p in "${FAILED_PACKAGES[@]}" "${MISSING_PACKAGES[@]}"; do
        [[ -z "$p" ]] && continue
        [[ "$seen" == *" $p "* ]] && continue
        seen+="$p "
        pending+=("$p")
    done

    if [[ ${#pending[@]} -eq 0 ]]; then
        return 1
    fi

    helper="${AUR_HELPER:-paru}"
    if [[ "$helper" == "sudo pacman" ]]; then
        helper="paru"   # 缺的都是 AUR 包，pacman 装不了
    fi
    install_cmd="$helper -S --needed"
    if [[ "$helper" == "paru" ]]; then
        install_cmd+=" --skipreview"
    fi
    install_cmd+=" --noconfirm ${pending[*]}"

    {
        printf '# ===== Pullautumn 待补装清单 =====\n'
        printf '# 生成时间: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '# 本次有 %d 个包没装成功：%s\n' "${#pending[@]}" "${pending[*]}"
        printf '# 安装日志: %s\n' "${LOG_FILE:-}"
        printf '#\n'
        printf '# 说明：GitHub hosts 修复只能解决域名解析与建连，解决不了\n'
        printf '#       Releases 大文件下载到一半被断开（curl 35 / git clone 超时）。\n'
        printf '#       等网络稳定后，把下面这一整行复制粘贴到终端执行即可；\n'
        printf '#       上面全是注释，整段复制也不会多执行任何东西。\n'
        printf '#\n'
        printf '%s\n' "$install_cmd"
        printf '#\n'
        printf '# --- 关于 GitHub 镜像（gh-mirror）---\n'
        printf '# 补装时如果又出现 curl: (7) / git clone 超时，是可以临时借道镜像的：\n'
        printf '#     gh-mirror on      # 开启（写 ~/.makepkg.conf 与 ~/.gitconfig）\n'
        printf '#     （执行上面的补装命令）\n'
        printf '#     gh-mirror off     # 用完关掉，否则 git push 会失败（镜像只读不写）\n'
        printf '# 当前状态随时可查：gh-mirror status\n'
        printf '#\n'
        printf '# 补装成功后可删除本文件：rm %s\n' "$PENDING_LIST_FILE"
    } > "$PENDING_LIST_FILE" || return 1

    print_info "待补装清单已写入：$PENDING_LIST_FILE"
    log "Pending package list written: $PENDING_LIST_FILE (${#pending[@]} packages)"
    return 0
}

install_packages() {
    section "Phase 4" "Install Packages"

    _resolve_installer

    # 与 _install_each 保持同一套参数：paru 必须带 --skipreview，
    # 否则 PKG_GROUPS 里的 AUR 包（如 cliphist-tui-git）在无人值守安装时会卡在 PKGBUILD 审阅。
    local -a pkg_cmd=($AUR_HELPER -S --needed --noconfirm)
    if [[ "$AUR_HELPER" == "paru" ]]; then
        pkg_cmd=($AUR_HELPER -S --needed --skipreview --noconfirm)
    fi

    local total=${#PKG_GROUP_NAMES[@]}
    local current=0
    local failed=0

    # 进度按「包组」计，末尾核对按展开后的「包」计，两者不同源，写清楚免得被当成漏装
    echo -e "   ${WHITE}$total${NC} 个包组 ${DIM}(进度按组计；末尾核对按展开后的包计)${NC}"
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
        if "${pkg_cmd[@]}" "${want[@]}" >> "$LOG_FILE" 2>&1; then
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
    elif ! _aur_network_gate; then
        print_skip "AUR packages (GitHub unreachable, skipped)"
        log "AUR packages skipped: github unreachable"
    else
        # 逐个装、逐个显示，全程不再询问（已装的直接标 OK）
        # AUR_PACKAGES 里也混了仓库包（matugen / uv），所以标题不写死"AUR"
        local aur_failed=0 aur_start=${#FAILED_PACKAGES[@]}
        _install_each "必装依赖包（AUR / 仓库）" "${AUR_PACKAGES[@]}" || aur_failed=$?

        echo ""
        if [[ $aur_failed -eq 0 ]]; then
            mark_done "aur_packages"
            print_ok "必装依赖包全部就绪"
        else
            local -a aur_missing=("${FAILED_PACKAGES[@]:$aur_start}")
            print_warn "$aur_failed 个必装依赖包未装成功："
            printf '         %s\n' "${aur_missing[@]}"
            log "AUR FAILED (${aur_failed}): ${aur_missing[*]}"
            print_info "这些包名也已写进待补装清单，开机后可照着补装"
            write_pending_list || true
        fi
    fi

    # 全部包装完后统一核对一遍：pacman 装完不等于全部就位，
    # 而且 AUR 失败在日志里看不到，只有主动查才知道缺了什么
    _verify_installed_packages || true

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
    # 可选软件也可能失败，再落一次盘（内容累积，覆盖写不会丢之前的失败包）
    write_pending_list || true
}
