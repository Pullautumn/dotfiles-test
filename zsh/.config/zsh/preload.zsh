# 优化性能

skip_global_compinit=1
DISABLE_MAGIC_FUNCTIONS=true
ZSH_DISABLE_COMPFIX=true

# 补全系统设置
COMPLETION_WAITING_DOTS="true"
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# 早加载 vi (zsh-vi-mode 必须同步加载，需要此变量)
export ZVM_INIT_MODE=sourcing


# 定义zi 相关目录
typeset -Ag ZI
typeset -gx ZI[HOME_DIR]="${HOME}/.local/share/zi"
typeset -gx ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"

# 安装 zi（只在缺失时克隆，且不往已有目录里塞）
# 之所以不用「git clone 到 BIN_DIR」：HOME_DIR 下可能已有 zi 的插件数据，
# clone 会因为目标非空而失败，进而让 zi 完全不可用。
if [ ! -f "${ZI[BIN_DIR]}/zi.zsh" ]; then
    if command -v git >/dev/null 2>&1; then
        mkdir -p "${ZI[HOME_DIR]}"

        if [ -d "${ZI[BIN_DIR]}/.git" ]; then
            # 已有仓库但缺 zi.zsh：尝试原地更新
            command git -C "${ZI[BIN_DIR]}" pull --ff-only >/dev/null 2>&1 \
                || print -u2 "zi: 更新失败，继续用现有文件"
        else
            local _zi_tmp="${ZI[HOME_DIR]}/.zi-clone-$$"
            rm -rf "$_zi_tmp"
            if command git clone --depth 1 https://github.com/z-shell/zi.git "$_zi_tmp" >/dev/null 2>&1; then
                # 把克隆结果整体搬到 bin/（bin 已存在时先挪开）
                [ -d "${ZI[BIN_DIR]}" ] && mv "${ZI[BIN_DIR]}" "${ZI[BIN_DIR]}.bak.$$" 2>/dev/null
                mv "$_zi_tmp" "${ZI[BIN_DIR]}" \
                    && rm -rf "${ZI[BIN_DIR]}.bak.$$" \
                    || print -u2 "zi: 移动到 ${ZI[BIN_DIR]} 失败"
            else
                rm -rf "$_zi_tmp"
                print -u2 "zi: 克隆失败，请检查网络后重试（或手动 git clone 到 ${ZI[BIN_DIR]}）"
            fi
        fi
    else
        print -u2 "zi: 未找到 git，无法自动安装"
    fi
fi

# 加载zi 插件（缺失时给出可读的提示，而不是 command not found: zi）
if [ -f "${ZI[BIN_DIR]}/zi.zsh" ]; then
    source "${ZI[BIN_DIR]}/zi.zsh"
else
    print -u2 "zi: 未安装，插件（补全/语法高亮/自动建议）将不可用"
    _zi_missing=1
fi

# 指定 补全缓存的路径
local zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zinit ice compinit-opts'-d "${zsh_cache_dir}/zcompdump"'

# 启用补全
#autoload -Uz compinit
#compinit

# 加载zi 相关补全
#autoload -Uz _zi
#(( ${+_comps} )) && _comps[zi]=_zi

export EDITOR=nvim
autoload -z edit-command-line
zle -N edit-command-line
bindkey '^v' edit-command-line

source $HOME/.config/zsh/plugins.zsh
