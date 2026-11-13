# AI Frontier Radar P0 工程下载

工程包包含完整源码、Docker Compose、n8n 配置、Windows 一键启动脚本、测试与验收记录。当前 29 项测试通过；n8n 在 Windows 本机的实际运行与数据保留验收仍待完成。

## 下载

进入本分支的 `deliverables/` 目录，打开 `AI_Frontier_Radar_P0_implemented.zip`，点击 Download raw file 下载完整工程。验收报告及 SHA-256 校验文件位于同一目录。

也可以使用 GitHub 的 Code → Download ZIP 下载整个分支，然后从 `deliverables/` 中取出工程 ZIP。

## Windows 启动

1. 安装并启动 Docker Desktop，确认使用 Linux containers 和 WSL 2 backend。
2. 解压工程 ZIP，进入解压后的 `AI_Frontier_Radar_P0` 目录，打开 PowerShell。
3. 执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\start_p0.ps1
```

首次启动较慢时可运行 `.\scripts\start_p0.ps1 -WaitTimeout 600`。

全部检查通过后，浏览器打开 n8n：<http://localhost:5678>，按页面引导创建本地 owner 账号。API 文档：<http://localhost:8000/docs>。

出现报错时，按工程内 `docs/N8N_TROUBLESHOOTING.md` 处理。请勿执行 `docker compose down -v`，以免删除 n8n 数据。

## 验证范围

API、SQLite 持久化、无密钥启动、配置与密钥排除检查，以及 PowerShell 成功/失败流程测试已通过。脚本流程中的 Docker/HTTP 使用模拟测试；本次云环境因 VFS 空间及 inode 限制，n8n 未实际启动成功。不能据此宣称 Windows / n8n 最终验收通过。

工程包不包含真实密钥、`.env`、数据库、运行日志或虚拟环境。项目停留在 P0。

## API 构建网络超时修复

新版 Dockerfile 使用 Docker Desktop 自带的前端，省去额外拉取 `docker/dockerfile:1`。一键启动脚本将 API 构建与容器健康检查分成两个阶段。

已有工程可以在本机用记事本打开 Dockerfile，删除首行 `# syntax=docker/dockerfile:1`，保存后重跑 `scripts/start_p0.ps1`。仓库的 `patches/` 目录另提供新版 Dockerfile 与启动脚本，便于更新已有工程。保留已有 `.env` 和 n8n 卷。

如果下一步拉取 `python:3.12-slim` 仍在 `auth.docker.io` 超时，需检查 Docker Desktop 代理与网络；该依赖仍需要 Docker Hub。
