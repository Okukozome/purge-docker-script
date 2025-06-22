#!/usr/bin/env bash

# =====================================================================================
# Docker 环境彻底清理脚本
#
# 描述：
# 1. 清理所有已知的 Docker 版本 (CE, IO, Snap) 及其相关组件。
# 2. 任何步骤的失败（如文件/软件包不存在）都不会中断整个脚本的执行。
# 3. 删除相关的配置文件、数据目录和用户配置。
# =====================================================================================

# 必须使用 sudo 运行
if [ "$EUID" -ne 0 ]; then
  echo "错误：此脚本必须使用 sudo 权限运行"
  echo "请使用: sudo $0"
  exit 1
fi

# 危险操作确认
echo "================================================================"
echo "警告：此脚本将永久删除 Docker 镜像、容器、卷和网络配置"
echo "请在确定需要完全重置 Docker 环境的服务器上运行"
echo "================================================================"
echo ""

read -p "您确定要继续执行吗？(y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "操作已取消"
  exit 0
fi

echo ""
echo "### 阶段 1: 停止 Docker 相关服务..."
# 停止所有可能的服务，使用 || true 确保即使服务不存在也不会报错退出
systemctl stop docker.service docker.socket containerd.service || true
systemctl disable docker.service docker.socket containerd.service || true
echo "--- 阶段 1 完成 ---"
echo ""

echo "### 阶段 2: 卸载 Docker 相关软件包 (apt & snap)..."
# 卸载所有已知的 Docker 相关包
# 使用 -y 自动确认，使用 || true 避免因找不到包而中断
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras > /dev/null 2>&1 || true
apt-get purge -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc > /dev/null 2>&1 || true
snap remove docker > /dev/null 2>&1 || true
echo "--- 阶段 2 完成 ---"
echo ""

echo "### 阶段 3: 删除残留目录和文件..."
# 删除 Docker 相关目录和文件
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -rf /var/run/docker.sock
rm -rf /var/lib/buildkit
rm -rf /root/.docker
# 删除 systemd 配置文件
rm -rf /etc/systemd/system/docker.service.d
# 删除 apt 源配置文件
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.gpg
echo "--- 阶段 3 完成 ---"
echo ""

echo "### 阶段 4: 清理系统依赖包并更新缓存..."
apt-get autoremove -y > /dev/null 2>&1
apt-get autoclean > /dev/null 2>&1
apt-get clean > /dev/null 2>&1
echo "--- 阶段 4 完成 ---"
echo ""

echo "========================================================="
echo "### 验证: 检查 Docker 组件是否已移除"
echo "========================================================="
echo ""

# 初始化状态变量：0 表示已移除，1 表示仍存在
overall_status=0
docker_found=0
compose_v1_found=0
compose_v2_found=0
runtime_found=0
remaining_components=()

echo "检查 docker 命令..."
if command -v docker &> /dev/null; then
  echo ">> [⚠️ 存在] docker 命令位置: $(command -v docker)"
  docker_found=1
  remaining_components+=("docker")
else
  echo ">> [✅ 已移除] docker 命令未找到"
fi

echo ""
echo "检查 docker-compose (v1) 命令..."
if command -v docker-compose &> /dev/null; then
  echo ">> [⚠️ 存在] docker-compose 命令位置: $(command -v docker-compose)"
  compose_v1_found=1
  remaining_components+=("docker-compose (v1)")
else
  echo ">> [✅ 已移除] docker-compose 命令未找到"
fi

echo ""
echo "检查 docker compose (v2) 插件..."
# v2 插件依赖于 docker 主程序
if docker compose version &> /dev/null; then
  echo ">> [⚠️ 存在] docker compose 插件仍可执行"
  compose_v2_found=1
  remaining_components+=("docker compose (v2)")
else
  echo ">> [✅ 已移除] docker compose 插件不可用"
fi

echo ""
echo "检查 containerd 和 runc..."
if command -v containerd &> /dev/null || command -v runc &> /dev/null; then
  echo ">> [⚠️ 存在] containerd 或 runc 命令仍可找到"
  runtime_found=1
  remaining_components+=("containerd/runc")
else
  echo ">> [✅ 已移除] containerd 和 runc 命令未找到"
fi

# 检查是否有任何组件残留
if [ $docker_found -ne 0 ] || [ $compose_v1_found -ne 0 ] || [ $compose_v2_found -ne 0 ] || [ $runtime_found -ne 0 ]; then
    overall_status=1
fi

echo ""
echo "========================================================="
echo "### 清理结果总结"
echo "========================================================="

if [ $overall_status -eq 0 ]; then
  echo "✅ 全部清除！所有关键的 Docker 组件均已从系统中移除。"
  echo "系统现在处于一个干净的状态。"
else
  remaining_str=$(IFS=, ; echo "${remaining_components[*]}")
  echo "⚠️ 清理未完全！发现以下残留组件: [${remaining_str}]"
  echo "这可能是因为它们被手动安装在非标准路径下，或者由其他软件包管理。"
  echo "请根据上面的验证路径信息手动检查并删除。"
fi
echo "========================================================="
