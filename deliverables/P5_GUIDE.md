# P5 多来源 AI 资讯采集

本次扩展采集范围，保留 P4.1 的选题、策划、视频、FredTalk 接力与 n8n 工作流。无需模型 API、本地大模型或新建飞书。

## 升级

将完整 ZIP 解压到新目录，在解压后含 docker-compose.yml 的项目文件夹打开 PowerShell，逐条执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\upgrade_p5.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
cd "F:\github1113\AI_Frontier_Radar_P0"
.\scripts\start_p0.ps1
```

升级成功后再从原目录启动。不要从下载解压目录启动第二套容器。升级前检查已知文件校验，保留 .env、数据库、日志、用户素材和 n8n 卷，原代码备份到 backups/p5-code-*；遇到未知本地改动会在写入前停止，提供报错核对，不能删除 .env 或重置加密密钥。此增量不改变 schema 7，较老数据库沿用既有逐阶段备份升级机制。重复执行应提示 already installed。

## 使用

1. 打开 http://localhost:8000/radar ，点击“采集一次”。原有已发布的 n8n 工作流仍会每 15 分钟调用同一采集入口，无需重复导入新工作流。关机、睡眠或 Docker 停止期间不会采集。
2. 默认看最近 24 小时，按原始发布时间筛选。可切换最近 3 天、7 天或全部历史；未知发布时间的记录保留在全部历史中，不把采集时间冒充发布时间。
3. 使用“来源类型”分别看公司官方、媒体、开源与开发者、研究和作者文章。它与“资讯类别”不同：前者是信息来自哪里，后者是消息在讲什么。来源类型筛选按全部出处匹配，同链接多源仍合并保留。
4. 右侧显示启用情况、采集方式、最后检查时间、失败原因、读取数量、非 AI 线索、未知日期和条数截断。返回 304 表示来源未变更；它仍只证明检查成功，不证明全站没有更新。
5. 收件箱不使用推荐分数删消息。再去 /topics 重新初筛，从候选中人工挑选、核实原文，进入内容策划和视频制作。推荐 0 个不会阻止收录。

首次采集某来源只回溯最近 7 天；无日期记录明确标注并保留。初始扫描中被排除的旧记录记为基线，后续持续收录新出现的条目，包括发布时间较早、延迟进入 feed 的条目，避免每次固定回看造成遗漏。首次跳过的历史档案不会在第二轮全部灌入。已有数据不会因过期删除。采集故障后的恢复程度受来源自身历史窗口影响。

## 来源覆盖

当前配置 33 个来源，启用 25 个。公开 RSS/Atom 优先；无可用 feed 的 Anthropic 新闻使用有边界的公开新闻页发现及文章元数据，先检查 robots.txt，同站、指定新闻路径、有限请求，遇到限制停止，不绕过登录或反爬。

- 公司官方：OpenAI News、Google DeepMind Blog、Google AI Blog、NVIDIA Blog、AWS Machine Learning、Anthropic News、Mistral News。
- 新闻媒体：TechCrunch AI、VentureBeat AI、MIT Technology Review AI、The Decoder、量子位、IT之家。
- 开源与开发者：Hugging Face Blog、DeepSeek-V3 发布、Ollama 发布、Transformers 发布、vLLM 发布、llama.cpp 发布、GitHub AI & ML。
- 研究机构与论文：arXiv cs.AI、arXiv cs.LG、Google Research Blog、Microsoft Research。
- 作者文章：Simon Willison。

未启用来源继续显示覆盖缺口，例如失效的 Microsoft AI feed、受限的 IBM 地址、无可用条目的 Qwen releases。未启用不等于该机构没有消息。研究页、媒体与社区内容都不自动标为已核实。

综合科技源（NVIDIA、IT之家、Simon Willison）仅做可解释的 AI 关键词匹配，以免整站无关内容灌入；关键词不足可能漏掉隐含相关报道，可在来源配置调整。IT之家只按标题匹配，避免摘要中的站内推广词误收无关财经新闻；可通过 relevance_scope 配置 title 或 title_summary。专门的 AI feed 不应用选题分数或热度门槛。

## 可扩展配置与边界

`config/source_registry.yaml` 是来源清单。可增加公开 HTTPS RSS/Atom，使用唯一 source_id，填写 name、category、language、website、rss_url、enabled；collection_method 默认 rss。通用科技源可指定 relevance_terms；留空表示收录该 feed 返回的所有条目。不要把整个综合站当作已筛好的 AI 专栏。

HTML 仅用于适配过的静态新闻列表：collection_method=html 和 article_path_prefix。它读取当前列表前若干篇的标题、原始摘要、JSON-LD/元标签发布日期；不是全站爬虫，也不抓完整正文或执行页面脚本。文章路径变更、纯前端站、嵌入式日期缺失需要新增适配器。

`config/ingestion.yaml` 控制首次 lookback_days、单源最多 5000 条、单响应最多 5MB、HTML 每轮最多 10 篇及至少 1 秒间隔。超出限制显示可能漏采，不能据此声称完整。来源只返回最近 10 条时，本系统不能恢复被来源删掉的第 11 条；RSS 正常也不代表覆盖官网全部栏目。

当前不自动采集登录后的抖音/小红书/微信群、付费墙内容、X 全量动态，也没有全网搜索引擎与全部产品目录。社交消息可用于人工发现线索，再核对公开原始来源。全网一切最新发布无法保证穷尽；此版交付的是已配置公开来源的广泛、可见状态采集。

原始链接和摘要保留出处；用于稿件、截图或视频的素材需另行核实和取得适用授权。系统不自动发表。
