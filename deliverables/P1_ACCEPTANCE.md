# P1 实施与验收报告

日期：2026-11-13（Asia/Shanghai）

结论：P1 核心功能已实现，公开 RSS 实采、本地收件箱、URL 去重、数据库迁移与代码升级保护已验证。飞书实际凭据/表权限联调、Windows 本机 P1 升级以及 n8n 工作流实际导入执行仍需要在用户本机验证；不能用模拟测试代替这些项目。

## 完成的功能

- 7 个已验证的公开 RSS：OpenAI、Google DeepMind、Hugging Face、arXiv cs.AI / cs.LG、Google AI Blog、Google Research Blog。综合 Hacker News 默认不启用。
- 原标题、原文 URL、原始发布时间文本、UTC 发布时间、独立采集时间、来源及有限长度的纯文本摘要。
- 缺失原始发布时间明确标记未知；Atom 更新日期不会冒充原始发布时间。
- URL 去重与稳定 Radar ID，跨来源出处保留。每轮回看 7 天，每源最多考虑 100 条；已有历史保留。
- ETag / Last-Modified、HTTP 304、响应体上限、超时、有限网络重试和同站点 Retry-After 冷却。
- 采集历史与明示的部分失败/失败状态；重启时标记意外中断的采集。
- 离线静态资源的中文本地收件箱，支持搜索、来源筛选、翻页、手动采集与可选飞书同步。
- 可选的 News Inbox 单向新增/关联：先验证字段，按 Radar ID 查重，创建结果不确定时下次先查询；不覆盖已有飞书记录和人工审核状态。
- 默认未激活的 n8n 手动/15 分钟采集工作流，包含失败分支和人工审核入口。
- P0 到 P1 的 SQLite schema 1→2 备份迁移；文件升级先校验、备份，保留已有 .env、data、logs 和用户文件。
- 启动防护：已有 n8n 属于另一目录，或本目录缺少 .env 但已有对应 n8n 数据卷时，不生成新加密密钥覆盖既有工作环境。

## 实测结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 自动化测试 | 59 passed，1 条上游弃用提示，无 skip；完整工程包另解压复验通过 | evidence-p1/pytest.txt、evidence-p1/package-pytest.txt |
| Ruff / 格式 / JS 语法 | 通过 | 实际执行 ruff check / ruff format --check / node --check |
| RSS 可访问性 | 7 个地址均为 HTTP 200 且能解析 | evidence-p1/feed-endpoints.json |
| 真实首次采集 | 620 条有效候选被考虑，240 条入库，380 条超出回看范围，0 个来源失败 | evidence-p1/live-ingestion.json |
| 再次真实采集 | 新增 0，26 条链接去重，支持 304；没有重复新闻行 | evidence-p1/live-ingestion.json |
| 浏览器交互 | 搜索、来源筛选、翻页、实际采集按钮通过；页面无 JS 错误 | evidence-p1/browser-qa.json |
| 移动布局 | 390px 宽无横向溢出 | evidence-p1/inbox-mobile.png |
| API Docker 镜像 | 实际构建通过，版本 0.2.0 | evidence-p1/docker-build.txt |
| Docker 基本运行 | 禁用外部网络，使用模拟 RSS 验证 ready、收件箱、插入与再次去重 | evidence-p1/container-proof.txt |
| 升级脚本 | PowerShell 7.4.13/Linux 验证数据保留、备份、重复执行、未知本地修改和校验失败保护 | 自动化测试；完整旧包、模拟用户数据及迁移见 evidence-p1/full-upgrade-proof.json |
| 飞书同步 | 通过模拟鉴权、字段不符、创建结果丢失、重复远端 ID、限流及错误回显检查 | tests/test_p1_feishu.py |
| 真实飞书写入 | 尚未验证：本环境没有用户的飞书凭据与目标表权限 | 需按 P1_FEISHU_SETUP.md 在本机先同步 1 条 |
| n8n 工作流 | JSON、节点连接、错误分支、未激活和无凭据检查通过 | 导入和定时执行需用户本机验证 |

真实 RSS 条数取决于执行时间、网络与来源更新。测试数据不预装到交付包中，用户本机需要点击采集以获取自己的记录。页面截图来自本次实际 RSS 数据；内容本身仍未经独立事实核查。

## 迁移与兼容性

原工程目录名、n8n 镜像、容器名与持久化卷名保持兼容。Compose 为内部 api / n8n 地址补充 NO_PROXY / no_proxy，避免 HTTP 请求节点把内部流量送到外部代理。原 .env 中的 n8n 加密密钥保留；升级工具不触碰运行数据。

新版默认使用此前核验过、与 Docker Hub 对应版本摘要一致的 Docker 官方 AWS Python 镜像，并保留 PYTHON_BASE_IMAGE 配置入口。Dockerfile 使用内置前端，避免额外拉取 docker/dockerfile:1。外部 RSS、pip、飞书与镜像依然需要可用网络，未关闭 TLS 验证。

SQLite 迁移前生成 data/backups/radar-before-p1-*.db。代码备份放在 backups/p1-code-*。如果需要回退，先保留当前代码与数据库副本，再由熟悉工程的人同时核对代码和 schema 版本；不要把 schema 2 直接交给旧 P0 API 使用。

## 未执行事项与下一步

没有获取用户的飞书或模型密钥，没有真实调用模型，没有执行自动评分、事实核查结论、内容改写、视频或平台发布。飞书审核状态暂不回写本地。

先在用户已运行的 P0 目录应用升级并重新构建，打开 /radar 完成一次采集。确认旧 P0_验收测试 工作流仍存在，再导入 P1 的 n8n 工作流并手动执行。飞书配置后先验证 1 条，再决定是否批量同步。完成这些本机项目后才能声称 P1 的本机联调全部通过。

## 完整旧包升级演练

使用已交付的完整 P0 ZIP，在独立测试目录中加入模拟 .env、schema 1 数据库、用户表、用户笔记和日志，再将 Dockerfile 按本机遇到的情况改为官方 AWS 镜像与 Windows 行尾。实际执行升级脚本成功：既有 .env 字节、用户文件、日志和用户表保留，旧代码备份存在，API 从升级后的目录导入并启动，数据库迁移至 schema 2，迁移前 schema 1 备份可读取，n8n 卷与镜像配置保持不变。

该演练使用 PowerShell 7.4.13 / Linux 和模拟用户数据，并非助手在用户 Windows 电脑执行。真实 n8n 工作流保留与新工作流导入，仍需用户更新后在本机确认。
