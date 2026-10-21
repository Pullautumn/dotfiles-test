# shellcheck shell=bash

# ==============================================================================
# 辅助函数
# ==============================================================================

# 列出一个 stow 包会落到 $HOME 的目标相对路径
#   x/.config/niri/...      -> .config/niri
#   x/.local/bin/...        -> .local/bin
#   x/.zshenv               -> .zshenv
_pkg_targets() {
    local pkg="$1"
    local top name child
    while IFS= read -r -d '' top; do
        name=$(basename "$top")
        case "$name" in
            .config|.local)
                while IFS= read -r -d '' child; do
                    printf '%s\n' "${child#"$DOTFILES_DIR/$pkg/"}"
                done < <(find "$top" -mindepth 1 -maxdepth 1 -print0)
                ;;
            *)
                printf '%s\n' "${top#"$DOTFILES_DIR/$pkg/"}"
                ;;
        esac
    done < <(find "$DOTFILES_DIR/$pkg" -mindepth 1 -maxdepth 1 -print0)
}

# 备份并移走会被整体替换的现有配置（只处理 .config/* 与 .zshenv）
_dotfiles_backup_existing() {
    print_info "Backing up existing configs..."

    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    local pkg target abs real moved=false

    for pkg in "${STOW_PACKAGES[@]}"; do
        [[ -d "$DOTFILES_DIR/$pkg" ]] || continue
        while IFS= read -r target; do
            # 共享目录（.local/bin 等）交给 stow 合并，不整体搬走
            case "$target" in
                .config/*) ;;
                .zshenv)   ;;
                *) continue ;;
            esac

            abs="$HOME/$target"
            [[ -e "$abs" || -L "$abs" ]] || continue

            # 已经是指向本仓库的链接就不动
            if [[ -L "$abs" ]]; then
                real=$(readlink -f "$abs" 2>/dev/null || true)
                if [[ -n "$real" && "$real" == "$DOTFILES_DIR"/* ]]; then
                    continue
                fi
            fi

            mkdir -p "$backup_dir/$(dirname "$target")"
            if mv "$abs" "$backup_dir/$target" 2>/dev/null; then
                moved=true
            else
                print_warn "无法备份 $abs"
            fi
        done < <(_pkg_targets "$pkg")
    done

    if $moved; then
        print_ok "Backed up to: $backup_dir"
        log "Backup dir: $backup_dir"
        BACKUP_DIR="$backup_dir"
    fi
}

# 逐个 stow
_dotfiles_stow_all() {
    print_info "Applying configs with stow..."

    local pkg
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
            print_warn "missing package: $pkg"
            continue
        fi

        # mimeapps 用绝对路径链接：系统/桌面环境会写入该文件，避免写穿 stow 链接
        if [[ "$pkg" == "mimeapps" ]]; then
            mkdir -p "$HOME/.config"
            rm -f "$HOME/.config/mimeapps.list"
            if ln -sfn "$DOTFILES_DIR/mimeapps/.config/mimeapps.list" "$HOME/.config/mimeapps.list"; then
                print_ok "mimeapps ${DIM}(absolute link)${NC}"
            else
                print_warn "mimeapps link failed"
            fi
            continue
        fi

        if stow -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg" >> "$LOG_FILE" 2>&1; then
            print_ok "$pkg"
        else
            print_warn "stow failed: $pkg ${DIM}(see log)${NC}"
        fi
    done
}

# 壁纸目录：单独链接，不作为 stow 包
_dotfiles_link_wallpapers() {
    local src=""
    if [[ -d "$DOTFILES_DIR/wallpaper/Pictures/Wallpapers" ]]; then
        src="$DOTFILES_DIR/wallpaper/Pictures/Wallpapers"
    elif [[ -d "$DOTFILES_DIR/wallpapers" ]]; then
        src="$DOTFILES_DIR/wallpapers"
    fi
    [[ -n "$src" ]] || return 0

    mkdir -p "$HOME/Pictures"
    local dst="$HOME/Pictures/Wallpapers"

    if [[ -d "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || rm -rf "$dst"
    fi
    rm -f "$dst"

    if ln -sfn "$src" "$dst"; then
        print_ok "壁纸目录已链接: $dst"
    else
        print_warn "壁纸链接失败"
    fi
}

# 脚本可执行权限
_dotfiles_fix_permissions() {
    local dirs=(
        "$HOME/.local/bin"
        "$HOME/.config/scripts"
        "$HOME/.config/niri/scripts"
        "$HOME/.config/waybar/scripts"
        "$HOME/.config/matugen/scripts"
        "$HOME/.config/rofi"
    )
    local d
    for d in "${dirs[@]}"; do
        [[ -d "$d" ]] || continue
        find -L "$d" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
    done

    # rofi 的 scripts/launcher_tN、powermenu_tN 是「跳到对应主题脚本」的入口，
    # 没有 .sh 后缀，上面的 *.sh 规则扫不到，必须单独赋权，
    # 否则 waybar 的 launcher 点击后无反应。
    if [[ -d "$HOME/.config/rofi" ]]; then
        find -L "$HOME/.config/rofi" -type f \( -name "launcher_t*" -o -name "powermenu_t*" \) \
            -exec chmod +x {} + 2>/dev/null || true
    fi

    print_ok "脚本可执行权限已设置"
}

# 把配置里硬编码的 pullautumn / /home/pullautumn 换成当前用户
_dotfiles_rewrite_legacy_paths() {
    if [[ "$TARGET_USER" == "$LEGACY_USER" && "$HOME" == "$LEGACY_HOME" ]]; then
        print_info "当前用户即配置作者，跳过路径替换"
        return 0
    fi

    print_info "正在把配置里的 $LEGACY_USER 替换为 $TARGET_USER ..."

    local search_dirs=()
    [[ -d "$HOME/.config" ]] && search_dirs+=("$HOME/.config")
    [[ -d "$HOME/.local" ]] && search_dirs+=("$HOME/.local")
    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        print_info "没有需要处理的配置目录"
        return 0
    fi

    local patched=0 link real
    while IFS= read -r link; do
        real=$(readlink -f "$link" 2>/dev/null || true)
        [[ -n "$real" && -f "$real" ]] || continue
        [[ "$real" == "$DOTFILES_DIR"/* ]] || continue
        # 只处理文本文件，跳过图片/字体等二进制
        grep -Iq . "$real" 2>/dev/null || continue
        # /home/shorin 是配置里残留的第三方路径（waypaper 的 stylesheet）
        grep -qE "$LEGACY_USER|/home/$LEGACY_USER|/home/shorin" "$real" 2>/dev/null || continue

        if sed -i \
            -e "s|/home/$LEGACY_USER|$HOME|g" \
            -e "s|/home/shorin|$HOME|g" \
            -e "s|file://~/|file://$HOME/|g" \
            -e "s|=$LEGACY_USER|=$TARGET_USER|g" \
            -e "s|$LEGACY_USER|$TARGET_USER|g" \
            "$real" 2>/dev/null; then
            patched=$((patched + 1))
            log "  patched: $real"
        fi
    done < <(find "${search_dirs[@]}" -type l 2>/dev/null)

    print_ok "已替换 $patched 个配置文件中的用户名/路径"
}

# Flatpak 权限覆盖（装了 flatpak 才有意义）
_dotfiles_flatpak_overrides() {
    command_exists flatpak || return 0

    flatpak override --user --filesystem=xdg-config/gtk-3.0 >/dev/null 2>&1 || true
    flatpak override --user --filesystem=xdg-config/gtk-4.0 >/dev/null 2>&1 || true
    flatpak override --user --filesystem=xdg-config/fontconfig >/dev/null 2>&1 || true
    flatpak override --user --filesystem=xdg-data/themes >/dev/null 2>&1 || true
    flatpak override --user --filesystem="$HOME/.themes" >/dev/null 2>&1 || true
    print_ok "Flatpak 主题/字体权限已放行"
}

# 把仓库里的使用说明复制到用户主目录
_dotfiles_copy_guides() {
    local src_dir="${SETUP_DIR:-$DOTFILES_DIR/setup}/resources"
    [[ -d "$src_dir" ]] || return 0

    local guides=("必看-pullautumn-Niri使用方法.txt")

    local name copied=0
    for name in "${guides[@]}"; do
        [[ -f "$src_dir/$name" ]] || continue
        cp "$src_dir/$name" "$HOME/$name" 2>/dev/null && copied=$((copied + 1))
    done
    [[ $copied -gt 0 ]] && print_ok "使用说明已复制到 $HOME"
}

# ==============================================================================
# 主流程
# ==============================================================================
apply_dotfiles() {
    section "Phase 5" "Apply Configurations"

    if $SKIP_STOW; then
        print_skip "Config deployment (--no-stow)"
        return
    fi

    if is_done "apply_dotfiles"; then
        print_skip "Dotfiles applied (already done)"
        return
    fi

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_fail "Dotfiles not found: $DOTFILES_DIR"
        return 1
    fi

    if ! command_exists stow; then
        print_info "Installing stow..."
        sudo pacman -S --needed --noconfirm stow >> "$LOG_FILE" 2>&1 || true
    fi
    if ! command_exists stow; then
        print_fail "stow 不可用，跳过配置部署"
        return 1
    fi

    cd "$DOTFILES_DIR" || return 1

    _dotfiles_backup_existing
    _dotfiles_stow_all
    _dotfiles_link_wallpapers
    _dotfiles_fix_permissions
    _dotfiles_rewrite_legacy_paths
    _dotfiles_flatpak_overrides
    _dotfiles_copy_guides

    # niri 显示器配置：写死在仓库里，换机器时需要按实际输出改名
    if [[ -f "$HOME/.config/niri/conf.d/output.kdl" ]]; then
        print_info "显示器配置: ~/.config/niri/conf.d/output.kdl ${DIM}(按实际输出名调整)${NC}"
    fi

    # 两套状态栏都已部署，用快捷键切换
    if [[ -d "$HOME/.config/waybar-niri-Win11Like" ]]; then
        print_info "状态栏: Mod+F2 → waybar ${DIM}Mod+F3 → waybar-niri-Win11Like${NC}"
    fi

    mark_done "apply_dotfiles"
    print_ok "Configs applied"
    log "Dotfiles applied"
}
