# shellcheck shell=bash

# ==============================================================================
# ASCII Banners
# ==============================================================================
banner1() {
cat << "BANNER"
    ____        __  _____ __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/
BANNER
}

banner2() {
cat << "BANNER"
 ___   ___ ___ ___ ___ _    ___ ___
|   \ / _ \_  _| __|_ _| |  | __/ __|
| |) | (_) || || _| | || |__| _|\__ \
|___/ \___/ |_||_| |___|____|___|___/
BANNER
}

banner3() {
cat << "BANNER"
     _       _    __ _ _
  __| | ___ | |_ / _(_) | ___  ___
 / _` |/ _ \| __| |_| | |/ _ \/ __|
| (_| | (_) | |_|  _| | |  __/\__ \
 \__,_|\___/ \__|_| |_|_|\___||___/
BANNER
}

show_banner() {
    clear
    local r=$(( RANDOM % 3 ))
    echo -e "${CYAN}"
    case $r in
        0) banner1 ;;
        1) banner2 ;;
        2) banner3 ;;
    esac
    echo -e "${NC}"
    echo -e "${DIM}   :: Pullautumn Niri Dotfiles Installer :: v2.0 ::${NC}"
    echo ""
}

# ==============================================================================
# TUI Functions
# ==============================================================================
show_cursor() { printf '\033[?25h'; }
hide_cursor() { printf '\033[?25l'; }

cleanup() {
    show_cursor
    # 由 01-preflight.sh 定义；正常 exit 和 Ctrl+C 都会走到这里
    if declare -F stop_sudo_keepalive >/dev/null 2>&1; then
        stop_sudo_keepalive
    fi
    # GitHub 镜像兜底：中途 Ctrl+C / 报错退出时还原（用户选过 keep 则不动）。
    # 完成页那条正常路径不依赖这里 —— 它在 systemctl reboot 之前就清完了。
    if [[ "${PULLAUTUMN_MIRROR:-off}" == "on" ]] && [[ -n "${ROOT_DIR:-}" ]] \
        && [[ -f "$ROOT_DIR/local-bin/.local/bin/gh-mirror" ]]; then
        bash "$ROOT_DIR/local-bin/.local/bin/gh-mirror" cleanup --quiet
    fi
}

log() {
    # 日志文件由 main.sh 打开；极早期调用（或单测）时可能还没赋值
    [[ -n "${LOG_FILE:-}" ]] || return 0
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_ok() {
    echo -e "   ${GREEN}[OK]${NC} $1"
    # 以前 OK 只上屏不落盘，事后查日志无从判断 GitHub 探测当时判的是通还是不通
    log "[OK] $1"
}

print_fail() {
    echo -e "   ${RED}[FAIL]${NC} $1"
    log "[FAIL] $1"
}

print_skip() {
    echo -e "   ${YELLOW}[SKIP]${NC} $1"
}

print_info() {
    echo -e "   ${BLUE}[i]${NC} $1"
}

print_warn() {
    echo -e "   ${YELLOW}[!]${NC} $1"
    log "[WARN] $1"
}

# Section header
section() {
    local phase="$1"
    local title="$2"
    echo ""
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${NC} ${BOLD}${phase}${NC} :: ${WHITE}${title}${NC}"
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo ""
}

# System dashboard
sys_dashboard() {
    echo -e "${BLUE}+============ SYSTEM INFO =====================================+${NC}"
    echo -e "${BLUE}|${NC} ${BOLD}Kernel${NC}   : $(uname -r)"
    echo -e "${BLUE}|${NC} ${BOLD}User${NC}     : $(whoami)"
    echo -e "${BLUE}|${NC} ${BOLD}Home${NC}     : $HOME"

    if [[ -f "$STATE_FILE" ]]; then
        local done_count
        done_count=$(wc -l < "$STATE_FILE")
        echo -e "${BLUE}|${NC} ${BOLD}Progress${NC} : ${GREEN}Resuming${NC} ($done_count steps completed)"
    else
        echo -e "${BLUE}|${NC} ${BOLD}Progress${NC} : Fresh install"
    fi
    echo -e "${BLUE}+==============================================================+${NC}"
    echo ""
}

# /dev/tty 是否可以真正读写（Git Bash、CI 等环境里存在但不可用）
_tty_ok() {
    [[ -r /dev/tty ]] || return 1
    { : < /dev/tty; } 2>/dev/null || return 1
    return 0
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local response

    # --yes 模式：直接按默认值通过
    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
        print_info "$prompt (--yes)"
        return 0
    fi

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    echo -ne "   ${YELLOW}[?]${NC} $prompt"
    if _tty_ok; then
        read -r response < /dev/tty || response=""
    else
        read -r response || response=""
    fi
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

# 没有默认值的询问：回车不算回答，必须明确输入 y 或 n 才会返回。
# 用于「不回复就不往下走」的场合（GitHub 镜像开关）。
ask_required() {
    local prompt="$1" response

    if [[ "${ASSUME_YES:-false}" == "true" ]]; then
        print_info "$prompt (--yes：按不启用处理)"
        return 1
    fi

    while true; do
        # 颜色变量是字面 '\033[...' 形式（见 config.sh），必须用 %b 才会被解释；
        # 用 %s 会把 \033[0;33m 原样打在屏幕上。prompt 仍走 %s，避免提示语含 % 时被当格式符。
        printf '   %b[?]%b %s (y/n): ' "$YELLOW" "$NC" "$prompt"
        # read 返回非零 = EOF/无终端，此时必须直接退出，否则会无限循环刷提示
        if { : < /dev/tty; } 2>/dev/null; then
            read -r response < /dev/tty || { echo ""; return 1; }
        else
            read -r response || { echo ""; return 1; }
        fi
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            "")    echo "       直接回车不算回答，请输入 y 或 n" ;;
            *)     echo "       无效输入，请输入 y 或 n" ;;
        esac
    done
}
