#!/bin/bash
set -e
# 当前命令将基于nobody用户和/bin/bash命令进行执行
npm install -g --silent http://lf-nocache.bytedeliver.com/obj/eden-cn/uvzhlzeh7pbyubz/iga-cli-latest.tgz > /dev/null 2>&1

# ========================= 配置项 =========================
WorkSpaceDir="${CP_WORKSPACE}"
ENV_FILE="${WorkSpaceDir}/env"

# 建立短变量名（文件里的）和长环境变量名（要导出的）的映射关系
declare -A VAR_MAPPING=(
    ["Framework"]="IGA_PROJECT_SETTINGS_FRAMEWORK"
    ["BuildCmd"]="IGA_PROJECT_SETTINGS_BUILD_COMMAND"
    ["InstallCmd"]="IGA_PROJECT_SETTINGS_INSTALL_COMMAND"
    ["OutputDir"]="IGA_PROJECT_SETTINGS_OUTPUT_DIRECTORY"
    ["NodejsVersion"]="IGA_PROJECT_SETTINGS_NODE_VERSION"
    ["RootDir"]="IGA_PROJECT_SETTINGS_ROOT_DIRECTORY"
)
# ==========================================================

# 函数：从env文件中读取指定变量的值（未找到则返回空，不报错）
read_env_var() {
    local var_name="$1"
    local env_file="$2"
    
    # 检查文件是否存在（致命错误，仍需退出）
    if [ ! -f "$env_file" ]; then
        # echo "错误：文件 $env_file 不存在！请确认上一个脚本已成功生成该文件。" >&2
        exit 1
    fi

    # 读取变量值（处理值中含空格/特殊字符的情况）
    local var_value
    var_value=$(grep -E "^${var_name}=" "$env_file" | head -n 1 | cut -d '=' -f 2-)
    
    # 未找到变量时：直接返回空值，不打印警告、不返回错误
    if [ -z "$var_value" ]; then
        # echo ""  # 返回空字符串
        return 0
    fi

    # 找到变量时返回对应值
    echo "$var_value"
    return 0
}

# 主逻辑：遍历映射关系，读取短变量值，导出长环境变量名
for short_var in "${!VAR_MAPPING[@]}"; do
    long_var="${VAR_MAPPING[$short_var]}"
    var_value=$(read_env_var "$short_var" "$ENV_FILE")
    # 仅当变量值非空时，才导出为长名称的环境变量
    if [ -n "$var_value" ]; then
        export "$long_var"="$var_value"
    fi
    # 未找到的变量会自动跳过，不设置环境变量
done

# ========================= 切换 Node.js 版本 =========================
if [ -n "${IGA_PROJECT_SETTINGS_NODE_VERSION:-}" ]; then
  # 加载 nvm
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 安装并使用指定版本（如 20.x / 22.x / 24.x）
    # nvm install "${IGA_PROJECT_SETTINGS_NODE_VERSION}" > /dev/null 2>&1
    nvm use "${IGA_PROJECT_SETTINGS_NODE_VERSION}" > /dev/null 2>&1
fi
# 执行核心命令
iga pages build

# ========================= 复制.iga文件夹 =========================
# 检查长名称环境变量是否已设置且非空（修正if语句语法格式）
if [ -z "${IGA_PROJECT_SETTINGS_ROOT_DIRECTORY:-}" ]; then
    # echo "警告：IGA_PROJECT_SETTINGS_ROOT_DIRECTORY 变量未设置，跳过.iga文件夹复制操作。" >&2
    :   # 空操作，满足 bash 对 then 块必须有命令的要求
else
    # 定义源目录和目标目录
    src_dir="${IGA_PROJECT_SETTINGS_ROOT_DIRECTORY}/.iga"
    dest_dir="${WorkSpaceDir}/.iga"

    # 检查源.iga文件夹是否存在（修正if语句格式）
    if [ -d "$src_dir" ]; then
        # 执行复制（-r 递归复制文件夹，-p 保留权限/时间戳，-f 强制覆盖）
        cp -rpf "$src_dir" "$dest_dir"
        
        # 验证复制是否成功（修正if语句格式）
        if [ -d "$dest_dir" ]; then
            # echo ".iga文件夹已成功从 ${src_dir} 复制到 ${dest_dir}" >&2
            :
        else
            # echo "错误：.iga文件夹复制失败，目标目录 ${dest_dir} 不存在！" >&2
            exit 1
        fi
    else
        # echo "警告：源目录 ${src_dir} 不存在，跳过.iga文件夹复制操作。" >&2
        :
    fi
fi