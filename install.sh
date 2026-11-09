#!/bin/bash
# Thin bootstrapper for curl-based installs.

set -euo pipefail

DOTFILES_REPO="https://github.com/Pullautumn/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# ==============================================================================
# 参数预处理：--mirror / --no-mirror 在这一层消费掉，不转发给 setup/main.sh
# （setup/main.sh 的参数表里没有这两个选项，转发过去会被当成 Unknown option）
# ==============================================================================
MIRROR_CHOICE="${PULLAUTUMN_MIRROR:-}"
_forward=()
for _arg in "$@"; do
    case "$_arg" in
        --mirror)    MIRROR_CHOICE="on" ;;
        --no-mirror) MIRROR_CHOICE="off" ;;
        *)           _forward+=("$_arg") ;;
    esac
done
if ((${#_forward[@]})); then
    set -- "${_forward[@]}"
else
    set --
fi
export PULLAUTUMN_MIRROR="$MIRROR_CHOICE"

# ==============================================================================
# GitHub 镜像加速：安装前唯一一次询问
#
# 为什么放在这一层而不是 setup/main.sh 里：
#   1. 引导阶段那次 git clone 也要能被加速，它发生在本文件第 3 段；
#   2. 用户的心智是「跑安装脚本 → 先问一句」。
# 为什么不用 trap 还原：
#   下面三条路径全是 exec，本进程会被 setup/main.sh 替换掉，EXIT trap 永远不会触发。
#   所以「什么时候清除」交给 setup 结束时询问 + 其 cleanup 兜底。
# ==============================================================================
GH_MIRROR_BIN=""

_locate_gh_mirror() {
    local dir=""
    if dir=$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd); then
        if [[ -f "$dir/local-bin/.local/bin/gh-mirror" ]]; then
            GH_MIRROR_BIN="$dir/local-bin/.local/bin/gh-mirror"
            return 0
        fi
    fi
    if [[ -f "$DOTFILES_DIR/local-bin/.local/bin/gh-mirror" ]]; then
        GH_MIRROR_BIN="$DOTFILES_DIR/local-bin/.local/bin/gh-mirror"
        return 0
    fi
    return 1
}

_tty_available() {
    [[ -t 0 ]] && return 0
    { : < /dev/tty; } 2>/dev/null
}

# 没有默认值的询问：回车不算回答，必须明确输入 y 或 n
_ask_required() {
    local prompt="$1" ans
    while true; do
        printf '   [?] %s (y/n): ' "$prompt"
        # read 返回非零 = EOF/没有可读终端：直接按「不启用」退出，
        # 否则这里会无限循环刷「请输入 y 或 n」
        if { : < /dev/tty; } 2>/dev/null; then
            read -r ans < /dev/tty || { echo ""; return 1; }
        else
            read -r ans || { echo ""; return 1; }
        fi
        case "${ans,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            "")    echo "       直接回车不算回答，请输入 y 或 n" ;;
            *)     echo "       无效输入，请输入 y 或 n" ;;
        esac
    done
}

_mirror_bootstrap() {
    _locate_gh_mirror || return 0

    local has_yes=false a
    for a in "$@"; do
        [[ "$a" == "--yes" || "$a" == "-y" ]] && has_yes=true
    done

    # 已经有明确决定（参数或环境变量）：不再问
    if [[ -n "$MIRROR_CHOICE" ]]; then
        if [[ "$MIRROR_CHOICE" == "on" ]]; then
            bash "$GH_MIRROR_BIN" on --no-probe
            export PULLAUTUMN_MIRROR=on
        else
            export PULLAUTUMN_MIRROR=off
        fi
        return 0
    fi

    # 无人值守 / 没有终端：不弹问句，按「不启用」处理，避免卡死
    if $has_yes || ! _tty_available; then
        echo "   [i] 非交互安装：跳过镜像询问，按「不启用」处理"
        export PULLAUTUMN_MIRROR=off
        return 0
    fi

    echo ""
    echo "   [i] GitHub 连通性检测（最长约 7 秒）"
    bash "$GH_MIRROR_BIN" probe || true
    echo "   说明：启用后 paru / git 的 GitHub 下载走公共镜像（gh-proxy.com、ghfast.top）；"
    echo "         只改 \$HOME 下的用户级配置，不用 sudo。"
    echo "         安装结束会再问一次是否清除，选「保留」则重启后依然生效。"
    echo ""
    if _ask_required "安装期间是否启用 GitHub 镜像加速？"; then
        bash "$GH_MIRROR_BIN" on --no-probe
        export PULLAUTUMN_MIRROR=on
    else
        export PULLAUTUMN_MIRROR=off
    fi
}

# 仓库已在本地时，先问再干活
_mirror_bootstrap "$@"

# If running from a checked-out repo, delegate to the modular installer.
script_dir=""
if script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd); then
    if [[ -f "$script_dir/setup/main.sh" ]]; then
        exec bash "$script_dir/setup/main.sh" "$@"
    fi
fi

# If a repo already exists at the default location, use it.
if [[ -f "$DOTFILES_DIR/setup/main.sh" ]]; then
    exec bash "$DOTFILES_DIR/setup/main.sh" "$@"
fi

# Otherwise, bootstrap the repo for curl-based installs.
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    if ! command -v git >/dev/null 2>&1; then
        echo "[i] Installing git..."
        sudo pacman -S --needed --noconfirm git
    fi
    echo "[i] Cloning dotfiles to $DOTFILES_DIR..."
    git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"
    # Mark as freshly cloned via env var
    export DOTFILES_JUST_CLONED=1
fi

if [[ ! -f "$DOTFILES_DIR/setup/main.sh" ]]; then
    echo "[FAIL] setup/main.sh not found in $DOTFILES_DIR. Please update the repo."
    exit 1
fi

# 裸引导路径：仓库刚落地，此时才有 gh-mirror 可用，补问一次（仍然只问一次）
_mirror_bootstrap "$@"

exec bash "$DOTFILES_DIR/setup/main.sh" "$@"
