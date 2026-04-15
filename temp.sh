#!/bin/bash
  set -e
  # 当前命令将基于nobody用户和/bin/bash命令进行执行
  echo "====== 开始执行构建脚本 ======"

  npm install -g --silent http://lf-nocache.bytedeliver.com/obj/eden-cn/uvzhlzeh7pbyubz/iga-cli-latest.tgz > /dev/null 2>&1
  echo "[INFO] iga-cli 安装完成"

  # ========================= 配置项 =========================
  WorkSpaceDir="${CP_WORKSPACE}"
  ENV_FILE="${WorkSpaceDir}/env"

  echo "[INFO] WorkSpaceDir: ${WorkSpaceDir}"
  echo "[INFO] ENV_FILE: ${ENV_FILE}"

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

      if [ ! -f "$env_file" ]; then
          echo "[ERROR] 文件 $env_file 不存在！" >&2
          exit 1
      fi

      local var_value
      var_value=$(grep -E "^${var_name}=" "$env_file" | head -n 1 | cut -d '=' -f 2-)

      if [ -z "$var_value" ]; then
          return 0
      fi

      echo "$var_value"
      return 0
  }

  # 主逻辑：遍历映射关系，读取短变量值，导出长环境变量名
  echo ""
  echo "====== 读取环境变量配置 ======"
  for short_var in "${!VAR_MAPPING[@]}"; do
      long_var="${VAR_MAPPING[$short_var]}"
      var_value=$(read_env_var "$short_var" "$ENV_FILE")
      if [ -n "$var_value" ]; then
          export "$long_var"="$var_value"
          echo "[CONFIG] ${short_var} = ${var_value}"
      else
          echo "[CONFIG] ${short_var} = (未设置，已跳过)"
      fi
  done

  # ========================= 切换 Node.js 版本 =========================
  echo ""
  echo "====== 切换 Node.js 版本 ======"
  if [ -n "${IGA_PROJECT_SETTINGS_NODE_VERSION:-}" ]; then
      raw_node_version="${IGA_PROJECT_SETTINGS_NODE_VERSION}"
      if [[ "${raw_node_version}" =~ (20|22|24) ]]; then
          IGA_PROJECT_SETTINGS_NODE_VERSION="${BASH_REMATCH[1]}"
          export IGA_PROJECT_SETTINGS_NODE_VERSION
          echo "[INFO] 归一化后 Node 主版本: ${IGA_PROJECT_SETTINGS_NODE_VERSION} (原始值: ${raw_node_version})"
      else
          echo "[ERROR] IGA_PROJECT_SETTINGS_NODE_VERSION 非法: ${raw_node_version}，仅支持 20/22/24" >&2
          exit 1
      fi

      export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
      # 在非交互 shell 中显式加载 nvm，避免 `nvm use` 不可用
      if [ -s "${NVM_DIR}/nvm.sh" ]; then
          . "${NVM_DIR}/nvm.sh"
      elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
          . "/opt/homebrew/opt/nvm/nvm.sh"
      elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
          . "/usr/local/opt/nvm/nvm.sh"
      else
          echo "[ERROR] 未找到 nvm.sh，无法切换 Node 版本。请先安装并配置 nvm。" >&2
          exit 1
      fi

      echo "[INFO] 当前 Node 版本: $(node -v 2>/dev/null || echo '未安装')"
      echo "[INFO] 目标 Node 版本: ${IGA_PROJECT_SETTINGS_NODE_VERSION}"

      nvm use "${IGA_PROJECT_SETTINGS_NODE_VERSION}" > /dev/null 2>&1
      # nvm install "${IGA_PROJECT_SETTINGS_NODE_VERSION}" > /dev/null 2>&1

      echo "[INFO] 切换后 Node 版本: $(node -v)"
  else
      echo "[INFO] 未指定 Node 版本，跳过切换。当前版本: $(node -v 2>/dev/null || echo '未安装')"
  fi

  # 执行核心命令
  echo ""
  echo "====== 执行 iga pages build ======"
  iga pages build
  echo "[INFO] iga pages build 执行完成"

  # ========================= 复制.iga文件夹 =========================
  echo ""
  echo "====== 复制 .iga 文件夹 ======"
  if [ -z "${IGA_PROJECT_SETTINGS_ROOT_DIRECTORY:-}" ]; then
      echo "[INFO] IGA_PROJECT_SETTINGS_ROOT_DIRECTORY 未设置，跳过 .iga 文件夹复制"
  else
      src_dir="${IGA_PROJECT_SETTINGS_ROOT_DIRECTORY}/.iga"
      dest_dir="${WorkSpaceDir}/.iga"

      echo "[INFO] 源目录: ${src_dir}"
      echo "[INFO] 目标目录: ${dest_dir}"

      if [ -d "$src_dir" ]; then
          cp -rpf "$src_dir" "$dest_dir"
          if [ -d "$dest_dir" ]; then
              echo "[INFO] .iga 文件夹复制成功"
          else
              echo "[ERROR] .iga 文件夹复制失败，目标目录不存在！" >&2
              exit 1
          fi
      else
          echo "[WARN] 源目录 ${src_dir} 不存在，跳过复制"
      fi
  fi

  echo ""
  echo "====== 构建脚本执行完毕 ======"