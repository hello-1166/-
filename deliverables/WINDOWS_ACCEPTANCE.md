# Windows 本机验收补充记录

日期：2026-11-13（Asia/Shanghai）

结论：本机核心启动链路与 n8n 工作流持久化验证通过。

## 证据与通过项

本记录依据用户在本次会话提供的 Windows PowerShell 截图、浏览器截图和明确反馈；操作由用户在其 Windows 电脑执行，并非助手远程执行。

- PowerShell 显示 Docker 引擎已就绪，存储驱动为 overlayfs。
- n8n 镜像下载、API 镜像构建及服务启动完成。
- 启动输出出现 `P0 smoke tests passed.` 和 `P0 startup checks passed.`，包含 n8n 到 API 的内部连接检查。
- 浏览器能访问 `http://localhost:5678` 并进入工作流编辑页面。
- 用户创建 `P0_验收测试`，刷新后确认名称仍保留。
- 按会话指导执行 `docker compose down`（不带 `-v`），再执行 `docker compose up -d --no-build --wait --wait-timeout 180` 后，用户确认仍能找到该工作流。

上述结果确认 n8n 工作流数据在容器停止并重新创建后仍保留。

## 网络问题与适用范围

本机曾因 `auth.docker.io` 连接超时而无法下载 Dockerfile 前端和 Python 基础镜像。已指导移除外部 Dockerfile 前端声明，并提供 Docker 官方 AWS 公共仓库的 Python 镜像地址作为可选来源。对照检查时，`public.ecr.aws/docker/library/python:3.12-slim` 与 Docker Hub 对应镜像的多平台摘要一致。用户随后提供了 API 构建与完整启动检查通过的截图；截图不足以确认其最终 Dockerfile 使用了哪个镜像仓库。

包内原验收报告记录的是此前云端环境的限制；本文件补充之后完成的 Windows 本机验证。29 项自动化测试和云端 API 构建验证仍见包内报告，不代表在用户电脑重新运行了 pytest。未据此将尚未逐项观察的验收条目全部标记通过。

P0 仍为基础设施初始化阶段，后续新闻采集、内容生成等业务工作需另行确定范围。

## 日常使用

先启动 Docker Desktop，再在工程目录运行：

```powershell
docker compose up -d --no-build --wait --wait-timeout 180
```

n8n：<http://localhost:5678>；API 文档：<http://localhost:8000/docs>。

暂时停止服务可运行 `docker compose stop`。保留 `.env` 中原有 n8n 加密密钥及持久化卷。
