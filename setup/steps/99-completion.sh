# shellcheck shell=bash

# ------------------------------------------------------------------------------
# GitHub 镜像：安装期间开过就在这里问是否清除
#
# 必须在 systemctl reboot 之前同步跑完 —— 不能指望 EXIT trap：
# systemctl reboot 之后 shutdown 可能先杀掉会话，还原来不及执行，
# 结果就是文件残留、重启后镜像还开着，而用户以为已经还原了。
# ------------------------------------------------------------------------------
gh_mirror_finish() {
    [[ "${PULLAUTUMN_MIRROR:-off}" == "on" ]] || return 0
    local bin="${ROOT_DIR:-}/local-bin/.local/bin/gh-mirror"
    [[ -f "$bin" ]] || return 0

    # 无人值守 / 没有终端：按安全侧自动清除（把第三方镜像留成默认值不合适）
    if [[ "${ASSUME_YES:-false}" == "true" ]] || ! _tty_ok; then
        bash "$bin" off --quiet
        export PULLAUTUMN_MIRROR=off
        print_info "已自动清除 GitHub 镜像配置（--yes / 非交互环境）"
        log "gh-mirror auto off (non-interactive)"
        return 0
    fi

    echo -e "   ${BOLD}GitHub 镜像加速${NC} ${DIM}(本次安装期间已启用)${NC}"
    if ask_required "是否清除镜像配置（y=清除并恢复直连，n=保留）？"; then
        bash "$bin" off
        export PULLAUTUMN_MIRROR=off
        log "gh-mirror off (user choice)"
    else
        bash "$bin" keep --quiet
        print_info "已保留。以后清除： ${YELLOW}gh-mirror off${NC}"
        print_info "镜像开着时 ${YELLOW}git push${NC} 会失败（镜像只读不写）"
        log "gh-mirror keep (user choice)"
    fi
    echo ""
}

show_completion() {
    # 待补装清单在清屏前落盘（此时打印的内容会被 clear 抹掉，完成页里单独给路径）
    local pending_written=false
    if declare -F write_pending_list >/dev/null 2>&1; then
        if write_pending_list >/dev/null 2>&1; then
            pending_written=true
        fi
    fi

    clear
    show_banner

    echo -e "${GREEN}+==============================================================+${NC}"
    echo -e "${GREEN}|              INSTALLATION COMPLETE                           |${NC}"
    echo -e "${GREEN}+==============================================================+${NC}"
    echo ""

    echo -e "   ${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "   ${CYAN}1.${NC} 重启系统"

    local step=2
    if systemctl is-enabled sddm &>/dev/null; then
        echo -e "   ${CYAN}${step}.${NC} SDDM 会接管登录，输密码后自动进入 niri（主题 lunar-glass）"
        step=$((step + 1))
    else
        echo -e "   ${CYAN}${step}.${NC} 没有显示管理器：登录 TTY 后执行 ${YELLOW}niri-session${NC}"
        step=$((step + 1))
    fi

    echo -e "   ${CYAN}${step}.${NC} 换壁纸：     ${YELLOW}waypaper${NC} ${DIM}(自动触发 matugen 换色)${NC}"
    step=$((step + 1))
    if [[ -d "$HOME/.config/waybar-quickshell" ]]; then
        echo -e "   ${CYAN}${step}.${NC} 状态栏样式： ${YELLOW}Mod+F2 / F3 / F4${NC} ${DIM}(主样式 / Win11Like / Quickshell)${NC}"
        step=$((step + 1))
    fi
    echo -e "   ${CYAN}${step}.${NC} 输入法设置： ${YELLOW}fcitx5-configtool${NC}"
    step=$((step + 1))
    echo -e "   ${CYAN}${step}.${NC} 显示器配置： ${YELLOW}~/.config/niri/conf.d/output.kdl${NC}"

    if [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]]; then
        echo ""
        echo -e "   ${DIM}旧配置备份在：$BACKUP_DIR${NC}"
    fi

    echo -e "   ${DIM}安装日志：$LOG_FILE${NC}"

    if $pending_written; then
        echo ""
        echo -e "   ${YELLOW}[!] 本次有包没装成功${NC}：重启联网后打开 ${WHITE}$PENDING_LIST_FILE${NC}"
        echo -e "   ${DIM}整段复制粘贴即可补装（文件里只有一行是命令，其余都是注释）${NC}"
    fi
    if [[ "${SDDM_SELFCHECK_FAILED:-false}" == "true" ]]; then
        echo -e "   ${YELLOW}[!] SDDM 自检未全通过${NC}，登录界面可能起不来；详见安装日志"
    fi
    if [[ "${BT_SELFCHECK_FAILED:-false}" == "true" ]]; then
        echo -e "   ${YELLOW}[!] 蓝牙服务已启用但未运行${NC}（blueman 会提示「蓝牙守护进程没有运行」）"
        echo -e "   ${DIM}登录后执行：${NC} ${YELLOW}sudo systemctl restart bluetooth${NC}"
    fi
    echo ""

    # 安装期间若改过 /etc/hosts 直连 GitHub，这里给出还原方式
    if github_hosts_notice; then
        echo ""
    fi

    # 安装期间启用的 GitHub 镜像：问一句要不要清除（重启之前必须处理完）
    if declare -F gh_mirror_finish >/dev/null 2>&1; then
        gh_mirror_finish
    fi

    # 成功完成后清空进度，下次运行是全新安装；
    # SDDM 自检没过时保留进度，重跑只会补做 SDDM 这一步，不必把整套流程再走一遍
    if [[ "${SDDM_SELFCHECK_FAILED:-false}" == "true" ]]; then
        print_info "已保留安装进度：修好 SDDM 后重跑，只会补做未完成阶段"
    else
        rm -f "$STATE_FILE"
    fi

    # 主动要求不重启：--no-reboot，或 --yes 无人值守（无人确认的倒计时等于强制重启）
    if [[ "${NO_REBOOT:-false}" == "true" || "${ASSUME_YES:-false}" == "true" ]]; then
        echo -e "${YELLOW}>>> 已跳过自动重启（--no-reboot / --yes）${NC}"
        echo -e "   请手动执行： ${YELLOW}reboot${NC}"
        echo ""
        return 0
    fi

    # 没有可交互终端（管道、CI、< /dev/null）时倒计时毫无意义：read 会立即 EOF 空转十次
    if ! _tty_ok; then
        echo -e "${YELLOW}>>> 非交互环境，跳过自动重启。请手动执行： ${YELLOW}reboot${NC}"
        echo ""
        return 0
    fi

    echo -e "${YELLOW}>>> System requires a REBOOT.${NC}"
    echo ""

    local i input
    for i in {10..1}; do
        echo -ne "\r   ${DIM}Auto-rebooting in ${i}s... (Press 'n' to cancel)${NC}"

        if read -t 1 -n 1 input < /dev/tty 2>/dev/null; then
            if [[ "$input" == "n" || "$input" == "N" ]]; then
                echo -e "\n\n   ${BLUE}>>> Reboot cancelled.${NC}"
                return 0
            fi
        fi
    done

    echo -e "\n\n   ${GREEN}>>> Rebooting...${NC}"
    sudo systemctl reboot
}
