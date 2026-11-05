# shellcheck shell=bash

show_completion() {
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
    echo ""

    # 成功完成后清空进度，下次运行是全新安装
    rm -f "$STATE_FILE"

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
