# AI Frontier Radar P0 实施与验收报告

日期：2026-11-13（Asia/Shanghai）
基线：用户上传的 `AI_Frontier_Radar_P0_Codex_Package_v2.zip`
结论：**PASS WITH ISSUES：P0 工程修复及 API 验证完成；未达到完整 P0 验收。n8n 运行和 Windows 本机验收仍待完成。**

## 完成内容

本次仅实施 P0 基础设施，没有进入新闻采集、评分、事实核查、内容生成、视频或发布阶段。飞书与模型接口仅检查配置，不访问远端，不需要真实 API Key。

- `/ready` 以只读方式检查 SQLite schema version；缺库、坏库或版本不符时返回 HTTP 503，不创建空数据库。连接及时关闭。
- 飞书检查包含六个字段：App ID、App Secret、Base Token、News / Content / Source Table ID；启用且全部齐全才标记 configured。
- 验证 provider YAML 结构与环境变量引用；错误配置阻止启动。缺少凭据仍可启动，未知默认 provider 报 unavailable。
- 应用日志使用 UTC JSON，输出至控制台和 `logs/radar.log`，按大小轮转。加入注入密钥后的响应与日志检查。
- API 文档静态资源随 Python 包发布，附上游许可证和资源校验记录；浏览器验证时阻断全部外部请求仍能正常显示。
- PowerShell 初始化使用 UTF-8 无 BOM 和 CreateNew，已有 `.env` 不覆盖，不输出生成的加密密钥。
- 冒烟脚本显式检查 Docker 原生命令退出码、两个服务运行状态、五个 API / 文档 / n8n 页面与健康端点，失败不会打印通过。
- Compose 保持宿主机回环端口、内部 `api:8000`、只读配置及持久化卷；API 健康检查改用 readiness。新增可选 UID/GID 配置解决 Linux bind mount 映射。
- Python 依赖增加跨平台版本锁；n8n 固定为实查官方 stable 多平台摘要（镜像标签版本 2.47.5）。增加 `.dockerignore`。

## 实测结果

| 项目 | 结果 | 证据 / 限制 |
| --- | --- | --- |
| pytest | PASS | **29 passed, 1 warning**；包含 PowerShell 脚本测试，没有 skip；工程包独立解压后复验同样通过 |
| Ruff 检查与格式 | PASS | `All checks passed`；14 files formatted |
| Compose 配置 | PASS | `docker compose config --quiet` |
| 回环端口、只读配置、n8n 卷 | PASS | 解析 Compose 实际展开配置并断言，未打印密钥 |
| API Docker 构建 | PASS | Python 3.12 slim；使用受信 CA secret，TLS 验证保持启用 |
| API 容器健康 | PASS | `radar-api` healthy，127.0.0.1:8000 |
| 五个 API | PASS | HTTP 200；无凭据时飞书和 provider 均为未配置 |
| API 文档浏览器 | PASS | Chromium + Playwright，阻断外部请求，文档与接口列表显示成功 |
| 初始化与密钥不覆盖 | PASS | PowerShell 7.4.13 / Linux；实际运行及独立目录测试 |
| SQLite 初始化 / schema | PASS | `system_state` 存在，schema_version=1 |
| SQLite 停止后保留 | PASS | 验证自建测试行经过 compose down 和 API 重建后仍存在；随后删除测试行 |
| Git 排除本地运行数据 | PASS | `.env`、DB、日志均被忽略；只跟踪 `.gitkeep` |
| 响应 / 日志密钥检查 | PASS | 单测注入哨兵凭据；运行日志与 API 响应另查实际生成的本地密钥 |
| n8n 官方镜像拉取 | BLOCKED | 两个官方入口均在解压时报告 `no space left on device` |
| n8n 容器、页面、内部 API 通信 | NOT VERIFIED | 容器未能启动，未标为通过 |
| 完整 smoke_test.ps1 | FAIL（环境阻断） | n8n 未运行，脚本按预期报 `Service is not running: n8n` |
| n8n 数据持久化 | NOT VERIFIED | 已配置卷，但没有 n8n 工作流/数据库运行验证 |
| Windows + Docker Desktop 全流程 | NOT VERIFIED | 当前是 Linux 云环境，无法代替目标本机验收 |

ZIP 已通过 CRC 校验、文件排除检查及实际密钥值扫描；独立解压到新目录后运行全部 29 项测试再次通过，记录见 `evidence/package-pytest.txt`。

pytest 有一条上游 Starlette/TestClient 关于 httpx 的弃用提示，测试未失败。未因该提示更换本阶段 HTTP 客户端。

## 环境与 n8n 阻断

实际环境为 Linux、Python 3.12.14、Docker 29.9.2 / Compose 2.40.3、rootless Docker，存储驱动 VFS；共享文件系统约 8 GB，inode 上限 524,288。

官方镜像先从 `docker.n8n.io/n8nio/n8n:latest` 拉取，再从 `docker.io/n8nio/n8n:stable` 拉取，都在注册解压层时失败。为了继续验证，用官方 crane 0.22.1 导出所选 amd64 摘要的完整文件系统，保留原镜像配置导入为临时单层镜像；导入成功，但创建 n8n 容器时仍耗尽 inode。实测观察到 inode 使用 100%。因此不能声称 n8n 已运行或系统完整验收通过。

临时单层镜像已删除，交付配置仍使用官方多平台镜像摘要。未改 Docker 存储驱动、未删除用户数据、未执行 `down -v`。测试环境使用 `RADAR_UID=0` / `RADAR_GID=0` 对应 rootless Docker 的当前宿主机用户映射；交付默认仍为 10001 / 10001。

P0 不需要更换镜像版本或编造凭据以绕过该环境限制。请在有足够磁盘和 inode 的 Windows Docker Desktop 环境完成剩余验收。

## 修改与新增文件

修改：`.env.example`、`Dockerfile`、`docker-compose.yml`、`pyproject.toml`、`README.md`、`scripts/init_env.ps1`、`scripts/smoke_test.ps1`、`src/radar/main.py`、`src/radar/core/config.py`、`src/radar/core/database.py`、`src/radar/integrations/feishu.py`、验收清单。

新增：`scripts/start_p0.ps1`、`docs/N8N_TROUBLESHOOTING.md`、`.dockerignore`、`requirements.lock`、`requirements-dev.lock`、`src/radar/core/logging.py`、`src/radar/static/*`、`tests/conftest.py`、`tests/test_p0.py`、`tests/test_scripts.py`、本报告、第三方资源说明及 `docs/evidence/` 实测证据。完整变更列表见 `docs/evidence/changed-files.txt`。

## 实际执行命令

以下命令均在解压后的工程目录运行；工具路径为本次环境路径，不要求 Windows 用户照搬。所有安装缓存与工具放在 `work/`。未输出 `.env` 或展开的 Compose 敏感内容。

```sh
# 导入原始包为 Git 基线
 git init
 git add .
 git -c user.name=Codex -c user.email=codex@local commit -m 'Import supplied P0 initialization package'

# 依赖与测试
 UV_CACHE_DIR=/workspace/work/.uv-cache uv venv .venv
 UV_CACHE_DIR=/workspace/work/.uv-cache uv pip install --python .venv/bin/python -e '.[dev]'
 UV_CACHE_DIR=/workspace/work/.uv-cache uv pip compile pyproject.toml --universal -o requirements.lock
 UV_CACHE_DIR=/workspace/work/.uv-cache uv pip compile pyproject.toml --universal --extra dev -o requirements-dev.lock
 .venv/bin/ruff check src tests
 .venv/bin/ruff format --check src tests
 P0_PWSH=/workspace/work/powershell/pwsh XDG_CACHE_HOME=/workspace/work/.cache XDG_CONFIG_HOME=/workspace/work/.config XDG_DATA_HOME=/workspace/work/.local .venv/bin/pytest

# PowerShell 设置（Linux 工具路径和 XDG 配置用于本次验证）
 XDG_CACHE_HOME=/workspace/work/.cache XDG_CONFIG_HOME=/workspace/work/.config XDG_DATA_HOME=/workspace/work/.local /workspace/work/powershell/pwsh -NoLogo -NoProfile -File scripts/init_env.ps1
 docker compose config --quiet
 docker build --secret id=proxy_ca,src=/etc/ssl/certs/ca-certificates.crt -t ai_frontier_radar_p0-api .
 docker compose up -d --no-build api
 docker compose ps
 docker compose logs --no-color api

# n8n 常规拉取均失败
 docker pull docker.n8n.io/n8nio/n8n:latest
 docker pull n8nio/n8n:stable
 docker buildx imagetools inspect n8nio/n8n:stable

# 独立云端诊断：官方文件系统导出/导入
 /workspace/work/crane/crane config docker.io/n8nio/n8n@sha256:3c0d3d321e4c000a6f91d71a77d568905e2ebefa2f63d4f5a62a9f6030acedb0
 /workspace/work/crane/crane export docker.io/n8nio/n8n@sha256:3c0d3d321e4c000a6f91d71a77d568905e2ebefa2f63d4f5a62a9f6030acedb0 /workspace/work/n8n-flat.tar
 python /workspace/work/import_flat_image.py
 # 导入脚本从原始 JSON 恢复 ENV / USER / WORKDIR / ENTRYPOINT / LABEL / EXPOSE，调用 docker import
 # 临时 .env 选用该镜像后尝试启动；失败后还原为官方镜像
 docker compose up -d --no-build --wait --wait-timeout 180

# API 数据保留验证，未使用 -v
 docker compose down
 docker compose up -d --no-build --wait --wait-timeout 60 api

# 完整冒烟在 n8n 缺失处报错
 XDG_CACHE_HOME=/workspace/work/.cache XDG_CONFIG_HOME=/workspace/work/.config XDG_DATA_HOME=/workspace/work/.local /workspace/work/powershell/pwsh -NoLogo -NoProfile -File scripts/smoke_test.ps1
 git diff --check
 git check-ignore .env data/radar.db logs/radar.log
```

另外以 Python 断言 Compose 配置、SQLite 内容、API JSON 及日志中不包含实际生成的本地加密密钥；用 Playwright / 系统 Chromium 验证文档。结果保存至 `docs/evidence/`。临时测试镜像、旧版自建 API 镜像和本次构建缓存已做清理；未清理其他项目资产。

## 本轮补充：n8n 启动与文件交付

新增 `scripts/start_p0.ps1`，按阶段检查 Docker 引擎、Linux containers、Compose 配置，按需创建 `.env`，拉取固定 n8n 镜像并等待服务健康，最后执行完整冒烟检查。默认等待 300 秒，可通过 `-WaitTimeout 600` 延长。脚本不会覆盖已有 `.env`，不会删除卷，不会自动修改 Docker 存储驱动。

冒烟检查增加真实 n8n 容器内部到 `http://api:8000/ready` 的连接验证；该检查将在实际 n8n 容器运行后执行。新增 6 个脚本流程测试，覆盖 Docker 引擎不可用、Windows 容器模式、镜像拉取失败、API 镜像构建失败、内部连接失败和成功路径。测试中的 Docker 与 HTTP 返回采用模拟，不代表 n8n 在本次云环境启动成功。

当前完整单测为 **29 passed, 1 warning**，没有 skip。n8n 的云端资源阻断仍未解除，Windows 实际启动与持久化验收仍待完成。排障说明见 `N8N_TROUBLESHOOTING.md`。

指定的聊天附件输出目录位于当前环境的只读根文件系统下。目录写入授权已申请并获准，但创建目录仍返回 `Read-only file system`。工程 ZIP 和报告已经完成并通过排除密钥检查，另准备仅包含交付文件的私有下载页作为交付方式。该页面不运行 API 或 n8n；项目部署模式保持本地运行。

## Docker 构建前端网络超时修复

Windows 本机反馈 n8n 镜像已拉取成功，但构建 API 时，Dockerfile 的 `# syntax=docker/dockerfile:1` 触发额外前端镜像下载，在 `auth.docker.io/token` 连接超时。已删除该指令，使用当前 Docker Desktop / BuildKit 内置的 Dockerfile 前端，保留可选 CA secret 与 TLS 验证。

云端实际执行 `docker build --secret id=proxy_ca,src=/etc/ssl/certs/ca-certificates.crt -t radar-api:frontend-fix .` 成功，日志直接从 Python 基础镜像解析进入构建，不再下载 `docker/dockerfile:1`。实测构建摘要见 `evidence/docker-frontend-fix-build.txt`。

一键启动脚本现在先单独构建 API，再启动容器并等待健康；构建失败会标记 `API image build`，避免将镜像下载失败误报成服务不健康。新增构建失败立即停止的流程测试，完整测试为 29 passed、1 条上游弃用提示。

Python 基础镜像、pip 依赖以及 n8n 镜像依然需要网络。此修复消除一个不必要的拉取步骤，不代表 Docker Hub 的所有网络问题已解决。Windows 本机仍需重跑启动与冒烟检查。

## Windows 剩余验收

解压工程包，在 PowerShell 中进入包含 `docker-compose.yml` 的目录，确认 Docker Desktop 已运行，再执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\start_p0.ps1
```

测试依赖与 pytest 安装步骤见 README。服务地址（在运行它的本机访问）：API 文档 `http://localhost:8000/docs`；n8n `http://localhost:5678`。本次云环境仅 API 已实际运行，n8n 地址为预期入口。

工程包不包含 `.env`、生成的加密密钥、数据库、日志、虚拟环境或 Git 内部目录。验收后仍停留在 P0；P1 需要另行授权。
