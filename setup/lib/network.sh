# shellcheck shell=bash

# ==============================================================================
# GitHub 可达性修复（/etc/hosts 方案）
# ==============================================================================
# 为什么用 hosts 而不是镜像前缀改写 URL：
#   makepkg 下载 source 用的是 curl，AUR 的 *-git 包用的是 git clone，
#   这两条路径都会读 /etc/hosts。改解析结果**不改变 URL**，服务端返回的
#   字节完全一致，所以 sha256sums 与 PGP 签名校验全部照常通过。
#   任何 URL 改写方案（gh-proxy 前缀、替代域名）都做不到这一点；而 makepkg
#   的 source 由上游 PKGBUILD 维护，本地改了会被 paru 下次拉取覆盖。
#
# 安全阀：
#   1. 探测通过就一个字节都不改，直连正常时零副作用。
#   2. 写入前后各探测一次，写后仍不通立即回滚到备份，绝不留更糟的状态。
#   3. 只动带标记的块，不碰用户自己的 hosts 条目。
# ==============================================================================

GH_HOSTS_MARK_START="# GitHub IP hosts Start"
GH_HOSTS_MARK_END="# GitHub IP hosts End"
GH_HOSTS_SOURCE=""
GH_HOSTS_BACKUP=""
# 正常运行时恒为 /etc/hosts；留出环境变量是为了能在不碰系统文件的前提下做端到端测试
GH_HOSTS_FILE="${GH_HOSTS_FILE:-/etc/hosts}"

# 数据源：ittuann/GitHub-IP-hosts，每周由 GitHub Actions 自动更新。
# 用 hosts（每域名多个 IP）而不是 hosts_single（单 IP），避免单点失效。
_gh_hosts_mirrors() {
    cat <<'EOF'
https://cdn.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts
https://fastly.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts
https://testingcf.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts
https://gcore.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts
https://ghfast.top/https://raw.githubusercontent.com/ittuann/GitHub-IP-hosts/refs/heads/main/hosts
https://gh-proxy.com/https://raw.githubusercontent.com/ittuann/GitHub-IP-hosts/refs/heads/main/hosts
EOF
}

# 单个域名是否真的可用：发 GET 取前 1 MiB 真实字节，而不是 HEAD。
# 日志体检（install-20261107-061308.log）里那次假阳性就是：HEAD 被中间设备
# 直接应答了状态码，于是 hosts 修复没触发、AUR 闸门也放行了 12 个包，
# 而同一时段 git clone 到 github.com:443 全部卡满 21 秒超时。
#   · -sL            跟随跳转（Releases 会 302 到 release-assets 域）
#   · --range        只取前 1 MiB，避免为了探测把大文件整个下完
#   · size_download>0 才算通：响应体里必须真的有字节
#   · min_bps        最低吞吐（B/s），只对内容足够大的 URL 设置，见下方注释
_gh_probe_one() {
    local url="$1" min_bps="${2:-0}"
    local out="" code="000" size=0 speed=0 bps=0

    out=$(curl -sL --connect-timeout 5 --max-time 12 \
              --range 0-1048575 -o /dev/null \
              -w '%{http_code} %{size_download} %{speed_download}' "$url" 2>/dev/null) || return 1
    read -r code size speed <<< "$out" || true
    code="${code:-000}"; size="${size:-0}"; speed="${speed:-0}"
    [[ "$code" != "000" && "$size" -gt 0 ]] || return 1

    bps=${speed%%.*}
    [[ "$bps" =~ ^[0-9]+$ ]] || bps=0
    log "[github] probe ok: $url (${size} B, ${bps} B/s)"
    if (( min_bps > 0 && bps < min_bps )); then
        log "[github] slow link: $url (${bps} B/s < ${min_bps} B/s)"
        return 1
    fi
    return 0
}

# github.com 负责 API/网页/git clone，codeload.github.com 才是 tarball 302
# 之前的真实下载域 —— 两个都必须通，否则 makepkg 下 source 仍然会失败。
# codeload 根路径只会回一个很短的 404，速度数字没有意义，所以不设吞吐门槛。
# release-assets.githubusercontent.com 才是 Releases 大文件 302 之后的落点，
# 但 hosts 数据源不一定带它的条目 —— 只记日志、不参与判定，否则会出现
# 「主域明明修好了，却因为附加域不通把 hosts 回滚掉」。
_gh_reachable() {
    _gh_probe_one "https://github.com/" 8192 || return 1
    _gh_probe_one "https://codeload.github.com/" 0 || return 1
    if ! _gh_probe_one "https://release-assets.githubusercontent.com/" 0; then
        log "[github] release-assets.githubusercontent.com 不可达（Releases 大文件可能下载失败）"
    fi
    return 0
}

# 整体网络是否可用（用 pacman 镜像判断，不依赖 GitHub）。
# 完全没网时不值得花 6×20 秒逐个试 hosts 镜像源，直接认输。
_gh_net_up() {
    curl -m 4 -sI -o /dev/null "https://mirrors.bfsu.edu.cn/" 2>/dev/null \
        || curl -m 4 -sI -o /dev/null "https://mirrors.tuna.tsinghua.edu.cn/" 2>/dev/null
}

# 内容校验：标记齐全 + 关键域名存在，避免把错误页写进 /etc/hosts
_gh_hosts_valid() {
    local f="$1"
    [[ -s "$f" ]] || return 1
    grep -qF "$GH_HOSTS_MARK_START" "$f" || return 1
    grep -qF "$GH_HOSTS_MARK_END" "$f" || return 1
    grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}[[:space:]]+github\.com$' "$f" || return 1
    grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}[[:space:]]+codeload\.github\.com$' "$f" || return 1
    return 0
}

# 依次尝试镜像源，第一个通过校验的即采用
_gh_fetch_hosts() {
    local dst="$1"
    local src
    while IFS= read -r src; do
        [[ -z "$src" ]] && continue
        if curl -fsSL --connect-timeout 5 --max-time 15 -o "$dst" "$src" 2>/dev/null \
            && _gh_hosts_valid "$dst"; then
            GH_HOSTS_SOURCE="$src"
            return 0
        fi
    done < <(_gh_hosts_mirrors)
    return 1
}

# 备份到用户缓存目录（/etc/hosts 全局可读，不需要 sudo 就能复制）
_gh_backup_hosts() {
    local backup_dir="${XDG_CACHE_HOME:-$HOME/.cache}/pullautumn"
    local backup="$backup_dir/hosts.bak.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir" || return 1
    cp -f "$GH_HOSTS_FILE" "$backup" || return 1
    GH_HOSTS_BACKUP="$backup"
    return 0
}

_gh_apply_hosts() {
    local src_file="$1"

    _gh_backup_hosts || return 1

    # 先删旧块：脚本重复运行时不会累积；再追加新块
    sudo sed -i '\|^# GitHub IP hosts Start$|,\|^# GitHub IP hosts End$|d' "$GH_HOSTS_FILE" || return 1

    # 末行没有换行时补一个，否则新块会和原最后一行粘成一条无效记录
    if [[ -n "$(tail -c 1 "$GH_HOSTS_FILE")" ]]; then
        printf '\n' | sudo tee -a "$GH_HOSTS_FILE" > /dev/null || return 1
    fi

    sudo tee -a "$GH_HOSTS_FILE" < "$src_file" > /dev/null || return 1
    return 0
}

_gh_rollback_hosts() {
    [[ -n "$GH_HOSTS_BACKUP" && -f "$GH_HOSTS_BACKUP" ]] || return 0
    sudo cp -f "$GH_HOSTS_BACKUP" "$GH_HOSTS_FILE" || return 1
    print_info "已恢复原始 /etc/hosts（备份留在 $GH_HOSTS_BACKUP）"
    GH_HOSTS_BACKUP=""
    return 0
}

# 对外入口：能直连就什么都不做；不能则尝试修好，修不好回滚并返回非零
ensure_github_reachable() {
    if _gh_reachable; then
        print_ok "GitHub 直连正常（真实 GET 探测通过）"
        return 0
    fi

    # 完全没网时不用试镜像源，逐个超时纯属浪费时间
    if ! _gh_net_up; then
        print_warn "网络整体不可达，跳过 GitHub 修复"
        return 1
    fi

    print_warn "GitHub 直连不通（TCP 连接建立失败）"
    print_info "尝试用 hosts 修复：不改变 URL，不影响校验和与 PGP 签名"

    local tmp
    tmp=$(mktemp) || return 1

    if ! _gh_fetch_hosts "$tmp"; then
        rm -f "$tmp"
        print_fail "所有 hosts 镜像源均不可用"
        print_info "如果你有代理：export https_proxy=http://127.0.0.1:7890 后重跑"
        return 1
    fi

    if ! _gh_apply_hosts "$tmp"; then
        rm -f "$tmp"
        print_fail "写入 /etc/hosts 失败"
        _gh_rollback_hosts || true
        return 1
    fi
    rm -f "$tmp"

    # glibc 直接读 /etc/hosts，不需要 flush；curl 也不缓存 DNS
    if _gh_reachable; then
        print_ok "GitHub 已恢复（来源: ${GH_HOSTS_SOURCE%%/gh/*}）"
        log "github hosts applied from $GH_HOSTS_SOURCE"
        return 0
    fi

    print_warn "hosts 写入后仍不通，说明对端 IP 也不可达，恢复原状"
    _gh_rollback_hosts || true
    return 1
}

# 提示用户当前 /etc/hosts 里留了 GitHub 块（安装完成页会用到）
# 返回 0 = 确实改过并已打印提示，1 = 没改过（调用方据此决定要不要留空行）
github_hosts_notice() {
    grep -qF "$GH_HOSTS_MARK_START" "$GH_HOSTS_FILE" 2>/dev/null || return 1
    print_info "已优化 /etc/hosts 直连 GitHub；如需还原："
    print_info "  sudo sed -i '/# GitHub IP hosts Start/,/# GitHub IP hosts End/d' $GH_HOSTS_FILE"
    return 0
}

# ==============================================================================
# 组件级 GitHub 下载重试
# ==============================================================================
# clone_dotfiles 自带 3 次重试，但 Anime4K / yazi 插件 / wayscrollshot 这些
# 后续步骤以前都是「单次卡 21 秒超时就放弃」，日志里留下 fatal 后脚本照常跑完，
# 完成页还显示成功。这里给它们统一加重试与退避。
# ==============================================================================

# git clone：每次重试前清掉半成品目录，否则 git 会因目标非空直接失败
# 用法: gh_clone URL DST [tries=3] [delay=3]
gh_clone() {
    local url="$1" dst="$2" tries="${3:-3}" delay="${4:-3}"
    local i=1 rc=0

    [[ -n "$dst" && "$dst" != "/" ]] || return 1
    while (( i <= tries )); do
        rm -rf "$dst"
        if git clone --depth 1 "$url" "$dst" >> "$LOG_FILE" 2>&1; then
            if (( i > 1 )); then
                print_ok "git clone 第 $i 次尝试成功"
            fi
            return 0
        else
            rc=$?
        fi
        if (( i < tries )); then
            print_warn "git clone 第 $i/$tries 次失败，$delay 秒后重试"
            log "[retry] git clone failed ($i/$tries): $url"
            sleep "$delay"
        fi
        i=$((i + 1))
    done

    rm -rf "$dst"
    log "[retry] git clone gave up after $tries attempts: $url"
    return "$rc"
}

# 通用命令重试（内部 eval，输出进日志）：适合 ya pkg install 这种「命令内部
# 自己 clone」、以及 curl 下 Release 包的场景。
# 用法: gh_retry "cd '$HOME/.config/yazi' && ya pkg install" [tries=3] [delay=3]
gh_retry() {
    local cmd="$1" tries="${2:-3}" delay="${3:-3}"
    local i=1 rc=0

    while (( i <= tries )); do
        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
            if (( i > 1 )); then
                print_ok "第 $i 次尝试成功"
            fi
            return 0
        else
            rc=$?
        fi
        if (( i < tries )); then
            print_warn "第 $i/$tries 次失败，$delay 秒后重试"
            log "[retry] failed ($i/$tries): $cmd"
            sleep "$delay"
        fi
        i=$((i + 1))
    done

    log "[retry] gave up after $tries attempts: $cmd"
    return "$rc"
}
