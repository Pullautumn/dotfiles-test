#!/bin/bash
# Pullautumn Niri Dotfiles Installer v2.0 (modular)
# Architecture based on jswysnemc/dotfiles, adapted for Pullautumn's niri setup.
#
# 目标系统：刚用 archinstall 装好的 Arch Linux
# 运行方式：普通用户执行 ./install.sh（脚本内部按需 sudo）

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SETUP_DIR="$ROOT_DIR/setup"

source "$SETUP_DIR/lib/config.sh"
source "$SETUP_DIR/lib/ui.sh"
source "$SETUP_DIR/lib/exec.sh"
source "$SETUP_DIR/lib/state.sh"
source "$SETUP_DIR/lib/flatpak.sh"

for step in "$SETUP_DIR/steps/"*.sh; do
    source "$step"
done

trap cleanup EXIT

show_help() {
    cat << EOF
Pullautumn Niri Dotfiles Installer v2.0

Usage: ./install.sh [options]

Options:
    --minimal    Install core packages only (skip optional groups & flatpak)
    --no-stow    Skip config deployment
    --yes        Answer yes to every prompt (unattended runs)
    --no-reboot  Do not reboot automatically when finished
    --reset      Clear progress and start fresh
    --help       Show this help

Examples:
    ./install.sh              # Full installation
    ./install.sh --minimal    # Minimal installation
    ./install.sh --reset      # Clear progress, start fresh

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --minimal)
                INSTALL_MINIMAL=true
                shift
                ;;
            --no-stow)
                SKIP_STOW=true
                shift
                ;;
            --yes|-y)
                ASSUME_YES=true
                shift
                ;;
            --no-reboot)
                NO_REBOOT=true
                shift
                ;;
            --reset)
                rm -f "$STATE_FILE"
                echo "Progress cleared."
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

main() {
    echo "Pullautumn Dotfiles Installation Log - $(date)" > "$LOG_FILE"

    parse_args "$@"

    show_banner
    sys_dashboard

    if ! confirm "Start installation?"; then
        print_info "Cancelled"
        exit 0
    fi

    [[ ! -f "$STATE_FILE" ]] && touch "$STATE_FILE"

    # --- 基础环境 ---
    check_system
    install_base
    install_aur_helper
    clone_dotfiles

    # --- 软件包 ---
    install_packages
    install_optional_packages

    # --- 配置部署（stow）---
    apply_dotfiles

    # --- 各应用配置 ---
    setup_nvim
    setup_zsh
    setup_mpv
    setup_yazi

    # --- 系统集成 ---
    setup_locale
    setup_bash_path
    setup_local_bin
    setup_gtklock_pam
    setup_matugen
    setup_desktop_tweaks
    enable_services
    setup_ly
    setup_user_dirs

    show_completion
}

main "$@"
