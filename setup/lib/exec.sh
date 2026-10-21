# shellcheck shell=bash

command_exists() {
    command -v "$1" &> /dev/null
}

# Run command with spinner
exe() {
    local cmd="$*"
    local spin_chars='|/-\'
    local spin_pid

    # Start spinner
    (
        local i=0
        while true; do
            printf "\r   ${YELLOW}[%c]${NC} Running..." "${spin_chars:$i:1}"
            i=$(( (i + 1) % 4 ))
            sleep 0.1
        done
    ) &
    spin_pid=$!

    # Run command
    local result=0
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        result=0
    else
        result=1
    fi

    # Stop spinner
    kill "$spin_pid" 2>/dev/null
    wait "$spin_pid" 2>/dev/null || true
    printf "\r\033[K"

    return $result
}

# Run command with a labeled spinner (output goes to log)
# 用法：exe_spin "标签" 命令 [参数...]
# 与 install_packages 里的转圈样式一致：一行标签 + 转圈，结束后留一行 OK/FAIL
exe_spin() {
    local label="$1"
    shift

    local spin_chars='|/-\'
    local spin_pid
    (
        local i=0
        while true; do
            printf "\r         \033[0;33m[%c]\033[0m %s..." "${spin_chars:$i:1}" "$label"
            i=$(( (i + 1) % 4 ))
            sleep 0.12
        done
    ) &
    spin_pid=$!

    local result=0
    "$@" >> "$LOG_FILE" 2>&1 || result=1

    kill "$spin_pid" 2>/dev/null
    wait "$spin_pid" 2>/dev/null || true
    printf "\r\033[K"

    if [[ $result -eq 0 ]]; then
        printf "         ${GREEN}[OK]${NC} %s\n" "$label"
    else
        printf "         ${RED}[FAIL]${NC} %s ${DIM}(see log)${NC}\n" "$label"
    fi

    return $result
}

# Run with live output
exe_live() {
    local msg="$1"
    shift
    local cmd="$*"

    echo ""
    echo -e "   ${CYAN}>>>${NC} ${WHITE}$msg${NC}"
    echo -e "   ${DIM}\$ $cmd${NC}"
    echo ""

    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
        echo ""
        print_ok "$msg"
        return 0
    else
        echo ""
        print_fail "$msg"
        return 1
    fi
}
