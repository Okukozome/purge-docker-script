# Docker 环境清理脚本 Docker Environment Cleanup Script

> Environment: Ubuntu 22.04 LTS Server

**彻底清理服务器上预装的混乱 Docker 环境，或解决配置失误问题。**

**Thoroughly clean up pre-installed messy Docker environments on servers, or resolve misconfiguration issues.**

## 使用方法 Usage
```bash
sudo ./purge-docker.sh  
```

## 功能
- 清理所有 Docker 版本（CE/IO/Snap）
- 删除镜像/容器/卷/配置文件
- 验证并回显清理结果

## Features
- Remove all Docker versions (CE/IO/Snap)
- Delete images/containers/volumes/configuration files
- Verify and display cleanup results

## 警告
- **此脚本会永久删除所有Docker镜像、容器、卷和网络配置！**  
- 请在确定需要完全重置Docker环境的服务器上运行  
- 运行前请确认你不再需要任何Docker数据

## Warnings
- **This script will permanently delete all Docker images, containers, volumes, and network configurations!**
- Run only on servers where a complete Docker reset is required
- Confirm you no longer need any Docker data before execution
