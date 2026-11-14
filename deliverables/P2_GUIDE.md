# P2 自动初筛与选题工作台

日期：2026-11-14（Asia/Shanghai）。本版沿用本地、半自动、多模型配置方向。P1 已在用户 Windows 完成采集及 n8n 定时运行验证。

## Windows 升级

保持 Docker Desktop 运行。下载 P2 ZIP 后解压到一个单独的新目录，进入包含 scripts 的目录，逐条执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\upgrade_p2.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P2 code installed 后切换回原工程，再启动：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
.\scripts\start_p0.ps1
```

脚本先核对已知 P0/P1 文件与本版源文件摘要，再备份修改的代码；遇到未知本地修改，在写入前停止。保留 .env、data、logs、未管理文件、n8n 数据卷。不要整目录覆盖，不要删除数据卷。解压目录名仍为 AI_Frontier_Radar_P0，这是为兼容已有工程。

启动时，schema 2（或1）迁移到 schema 3，迁移前数据库备份为 data/backups/radar-before-p2-*.db。代码备份在 backups/p2-code-*。回退需要同时核对代码和数据库版本，不要把 schema 3 交给旧 API。

## 如何使用

打开 http://localhost:8000/topics 。新闻收件箱右上角也有“选题工作台”入口。

- **规则推荐**：默认最多10项，达不到门槛可以少于10或为0。分数是固定启发式的编辑线索估计，不是爆款概率。
- **全部候选**：近期素材按候选事件显示，原始英文标题保留；不配置模型不会自动翻译。
- **查看原始出处与规则依据**：阅读来源摘要、打开原文，核对日期、开放范围和实际效果。
- **加入选题 / 忽略 / 恢复待选择**：人工决定会持久保存，下一轮初筛不会覆盖。
- **导出已选题**：下载 Markdown 选题清单，包含出处和待核实项。单次最多100项；不是可直接发布稿件。

现有 n8n 工作流不必重新导入。它仍调用 /api/v1/ingestion/run，每轮采集后自动执行规则初筛。API 启动也会初筛已有数据；“重新初筛”可立即刷新。工作台需刷新才能看到后台新一轮结果。

## 筛选依据和限制

近7天、最多1000条候选素材，按发布时间检查时效；未知或未来日期不自动推荐。固定关键词识别受众相关、变化线索、演示潜力、摘要完整度，提供可解释的维度分。研究材料默认降级并封顶55，避免把论文当作可用产品。

疑似事件合并只在标题高度相似、数字/版本一致、发布时间相距不超过48小时且否定词线索不冲突时进行。使用固定锚点避免连锁合并，同一素材不重复进入事件。跨语言、标题差异大时会漏合并，也可能误合并；UI明确标示“疑似”，保留每篇出处，不以报道数量提升分数。当前未提供自动语义聚类或人工拆分功能，请通过原始材料判断。

规则主要看标题和RSS摘要，不能判断全部技术突破或真正的重要性。来源可追溯不等于来源的全部说法正确；“已选题”不等于已核实。论文原始记录在新闻收件箱仍保留。

## 可选模型分析

默认关闭；没有密钥也能完整使用规则筛选。先使用默认模式验证，再在原目录 .env 设置：

```dotenv
SELECTION_MODEL_ENABLED=true
LLM_DEFAULT_PROVIDER=你的服务商标识
```

服务商标识支持 openai、anthropic、gemini、deepseek、qwen。填写对应的 API_KEY、MODEL（准确的账号可用模型ID），DeepSeek/Qwen同时填写原有 API_BASE。不要把示例中文字当作实际配置；不要在聊天、截图、GitHub泄露密钥。

模型ID不预填，不假定订阅聊天产品就包含API额度。每个账号的模型可用性、价格和网络访问条件由服务商决定。DeepSeek/Qwen仅允许配置中列明的官方HTTPS主机，不将密钥发送到任意中转地址。

在原目录执行以下命令应用 .env（模型配置变更不必重新构建镜像）：

```powershell
docker compose up -d --no-build --force-recreate api
```

工作台的“模型分析（可能收费）”就绪后，点击一条并确认，会读取最多两篇允许域名下的公开网页片段；读取不到则使用RSS摘要。不会登录网站、绕过付费墙或下载任意URL。网页截取可能含导航、缺段落或截断，界面明确区分片段和RSS回退。

模型会提供中文选题名、材料摘要、选题理由、角度、待核实项和材料ID引用。输出做格式和引用ID校验，但不会自动证明每句话正确。模型参考价值分独立展示，不改变规则推荐排序，不执行模型提供的工具或指令。

### 成本与失败处理

- 只有人工点击才调用；现有15分钟采集不会付费调用。
- 默认每次API请求最多3个选题，每个选题1次模型请求；UI每次分析1个。
- 每个选题最多两篇材料，每篇截取最多3500字符；输出最多1600 tokens。
- 每日最多12次模型请求（北京时间自然日），超时、失败与中断也占用次数；请求记录持久化，重启不会清零。
- 同样材料、模型、受众和提示词版本的成功分析使用缓存，不重复调用。
- 不自动重试付费请求；429按Retry-After冷却，接口/格式失败保留规则结果。
- 这不是人民币/美元金额上限。实际费用以服务商用量与账单为准，缺失token用量不当作已知的零成本。

配置位于 config/selection.yaml。小批量上限是为了控制费用。修改受众或提示词后可导致缓存失效并产生新调用。

## 与博主内容生产的关系

本版解决“几百条素材先看哪些”。你先检查推荐理由和原文，做必要实测，再把已选题导出交给写稿环节。下一阶段才能接完整抖音口播/小红书图文生成。本版不仿冒创作者经历，不编造实测，不自动发布。

## 接口依据

模型适配器参考服务商公开文档；实际账号联调仍需本机验证：
- OpenAI：https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create
- Anthropic：https://platform.claude.com/docs/en/api/messages/create
- Gemini：https://ai.google.dev/api/generate-content
- DeepSeek：https://api-docs.deepseek.com/api/create-chat-completion/
- Qwen：https://help.aliyun.com/zh/model-studio/compatibility-of-openai-with-dashscope
