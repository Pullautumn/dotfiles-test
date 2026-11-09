# shellcheck shell=bash

setup_nvim() {
    section "Phase 6a" "Neovim Editor"

    if is_done "setup_nvim"; then
        print_skip "Neovim setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}配置是一套 LazyVim 发行版（~/.config/nvim）${NC}"
    echo -e "   ${DIM}首次启动会自动拉取 lazy.nvim 与全部插件。${NC}"
    echo ""

    # 只问一次：Neovim 和它的 LSP 依赖是同一件事，分成两次问没有意义
    if ! confirm "安装 Neovim 并同步 LSP 依赖?"; then
        print_skip "Neovim installation (user declined)"
        mark_done "setup_nvim"
        return
    fi

    print_info "Installing Neovim..."
    if sudo pacman -S --needed --noconfirm neovim >> "$LOG_FILE" 2>&1; then
        print_ok "Neovim installed"
    else
        print_fail "Failed to install Neovim"
        return
    fi

    # 配置由 apply_dotfiles 的 stow 负责，这里只做插件同步
    if [[ ! -d "$HOME/.config/nvim" ]]; then
        print_warn "~/.config/nvim 不存在，先确认 stow 部署成功"
        mark_done "setup_nvim"
        return
    fi

    print_info "Bootstrapping LazyVim plugins (may take a while)..."
    if nvim --headless "+Lazy! sync" +qa >> "$LOG_FILE" 2>&1; then
        print_ok "LazyVim plugins installed"
    else
        print_warn "LazyVim 同步可能未完成，稍后手动执行: nvim 然后 :Lazy sync"
    fi

    # 上面已经确认过，这里不再单独询问
    local lsp_pkgs="tree-sitter-cli clang stylua ruff pyright lua-language-server"
    print_info "Installing LSP dependencies..."
    if sudo pacman -S --needed --noconfirm $lsp_pkgs >> "$LOG_FILE" 2>&1; then
        print_ok "LSP dependencies installed"
    else
        print_warn "Some LSP dependencies failed (AUR 部分可稍后用 paru 补装)"
    fi

    mark_done "setup_nvim"
    log "Neovim configured"
}

setup_zsh() {
    section "Phase 6b" "Zsh Shell"

    if is_done "setup_zsh"; then
        print_skip "Zsh setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}Zsh 配置位于 ~/.config/zsh，由 zsh 包 stow 部署${NC}"
    echo -e "   ${DIM}~/.zshenv 由 zshenv 包提供，安装器不再另行生成。${NC}"
    echo ""

    # 只问一次：装 Zsh 和设默认 shell 是同一件事，分成两次问没有意义
    if ! confirm "安装 Zsh 并设为默认 shell?"; then
        print_skip "Zsh installation (user declined)"
        mark_done "setup_zsh"
        return
    fi

    print_info "Installing Zsh..."
    if sudo pacman -S --needed --noconfirm zsh >> "$LOG_FILE" 2>&1; then
        print_ok "Zsh installed"
    else
        print_fail "Failed to install Zsh"
        return
    fi

    if [[ -f "$HOME/.config/zsh/.zshrc" ]]; then
        print_ok "Zsh configuration present"
    else
        print_warn "~/.config/zsh/.zshrc 缺失，检查 stow 是否成功"
    fi

    # ~/.zshenv 必须指向 ZDOTDIR
    if [[ -f "$HOME/.zshenv" ]]; then
        print_ok "~/.zshenv 已存在"
    else
        print_warn "~/.zshenv 缺失（zshenv 包未部署？）"
    fi

    # 默认 shell：不再单独询问，上面已经确认过
    local zsh_bin
    zsh_bin=$(command -v zsh || true)
    if [[ -n "$zsh_bin" ]]; then
        if [[ "$SHELL" != *"zsh"* ]]; then
            # 必须走 sudo：chsh 自己用 PAM 验密码，不吃 sudo 的时间戳缓存，
            # 直接裸调会在这里再弹一次 Password:
            if sudo chsh -s "$zsh_bin" "$USER"; then
                print_ok "Default shell changed to zsh (重新登录生效)"
            else
                print_warn "Failed to change shell"
            fi
        else
            print_ok "Zsh is already default"
        fi
    fi

    mark_done "setup_zsh"
    log "Zsh configured"
}

setup_mpv() {
    section "Phase 6c" "MPV Media Player"

    if is_done "setup_mpv"; then
        print_skip "MPV setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}MPV 配置、4 个 Lua 脚本与图标字体由 dotfiles 的 mpv 包提供${NC}"
    echo -e "   ${DIM}可选下载 Anime4K 着色器用于动画超分。${NC}"
    echo ""

    # 只问一次：跑不跑 MPV 包含要不要 Anime4K，不拆成两问
    if ! confirm "安装 MPV 并下载 Anime4K 着色器?"; then
        print_skip "MPV installation (user declined)"
        mark_done "setup_mpv"
        return
    fi

    print_info "Installing MPV..."
    if sudo pacman -S --needed --noconfirm mpv >> "$LOG_FILE" 2>&1; then
        print_ok "MPV installed"
    else
        print_fail "Failed to install MPV"
        return
    fi

    if [[ -f "$HOME/.config/mpv/mpv.conf" ]]; then
        print_ok "MPV configuration present"
    else
        print_warn "~/.config/mpv/mpv.conf 缺失，检查 stow 是否成功"
    fi

    # 上面已经确认过，这里直接下
    print_info "Downloading Anime4K shaders..."
    local shader_dir="$HOME/.config/mpv/shaders"
    mkdir -p "$shader_dir"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    # 带重试的 clone：以前单次卡 21 秒超时就放弃，日志留下 fatal 但脚本照常跑完
    if gh_clone "https://github.com/bloc97/Anime4K.git" "$tmp_dir/Anime4K" 3 3; then
        cp -r "$tmp_dir/Anime4K/glsl_4.0/"* "$shader_dir/" 2>/dev/null || true
        print_ok "Anime4K shaders installed to $shader_dir"
    else
        print_warn "Anime4K 着色器下载失败（已重试 3 次），可稍后手动安装"
    fi
    rm -rf "$tmp_dir"

    mark_done "setup_mpv"
    log "MPV configured"
}

setup_yazi() {
    section "Phase 6d" "Yazi File Manager"

    if is_done "setup_yazi"; then
        print_skip "Yazi setup (already done)"
        return
    fi

    echo ""
    echo -e "   ${WHITE}Yazi 是终端文件管理器，支持图片预览与 Plugins${NC}"
    echo -e "   ${DIM}依赖 ffmpegthumbnailer / poppler / fd / ripgrep / fzf（已随核心包安装）${NC}"
    echo ""

    # 只问一次：Yazi 和 exiftool 一起装，不拆成两问
    if ! confirm "安装 Yazi 并附带 exiftool?"; then
        print_skip "Yazi installation (user declined)"
        mark_done "setup_yazi"
        return
    fi

    print_info "Installing Yazi and dependencies..."
    if sudo pacman -S --needed --noconfirm yazi ffmpegthumbnailer poppler jq imagemagick ffmpeg p7zip >> "$LOG_FILE" 2>&1; then
        print_ok "Yazi installed"
    else
        print_fail "Failed to install Yazi"
        return
    fi

    # 上面已经确认过，这里直接装
    sudo pacman -S --needed --noconfirm perl-image-exiftool >> "$LOG_FILE" 2>&1 \
        && print_ok "exiftool installed" \
        || print_warn "Failed to install exiftool"

    if [[ -f "$HOME/.config/yazi/yazi.toml" ]]; then
        print_ok "Yazi configuration present"
    else
        print_warn "~/.config/yazi/yazi.toml 缺失，检查 stow 是否成功"
    fi

    # 配置里声明了 plugins，首次运行需要下载
    if command -v ya >/dev/null 2>&1; then
        print_info "Installing Yazi plugins..."
        # ya pkg install 内部自己 clone，用通用重试包一层（输出照旧进日志）
        if gh_retry "cd '$HOME/.config/yazi' && ya pkg install" 3 3; then
            print_ok "Yazi plugins installed"
        else
            print_warn "Yazi 插件安装失败（已重试 3 次），可稍后执行: cd ~/.config/yazi && ya pkg install"
        fi
    fi

    mark_done "setup_yazi"
    log "Yazi configured"
}
