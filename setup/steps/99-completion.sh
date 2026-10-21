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
    if systemctl is-enabled ly@tty1 &>/dev/null; then
        echo -e "   ${CYAN}${step}.${NC} ly 会接管 tty1，登录后自动进入 niri"
        step=$((step + 1))
    else
        echo -e "   ${CYAN}${step}.${NC} 没有显示管理器：登录 TTY 后执行 ${YELLOW}niri-session${NC}"
        step=$((step + 1))
    fi

    echo -e "   ${CYAN}${step}.${NC} 换壁纸：     ${YELLOW}waypaper${NC} ${DIM}(自动触发 matugen 换色)${NC}"
    step=$((step + 1))
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

    if [[ "${NO_REBOOT:-false}" == "true" ]]; then
        echo -e "${YELLOW}>>> 已跳过重启（--no-reboot），请手动执行 reboot${NC}"
        echo ""
        return 0
    fi

    echo -e "${YELLOW}>>> System requires a REBOOT.${NC}"
    echo ""

    local i input
    for i in {10..1}; do
        echo -ne "\r   ${DIM}Auto-rebooting in ${i}s... (Press 'n' to cancel)${NC}"

        if read -t 1 -n 1 input 2>/dev/null; then
            if [[ "$input" == "n" || "$input" == "N" ]]; then
                echo -e "\n\n   ${BLUE}>>> Reboot cancelled.${NC}"
                return 0
            fi
        fi
    done

    echo -e "\n\n   ${GREEN}>>> Rebooting...${NC}"
    sudo systemctl reboot
}
