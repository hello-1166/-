# P1 工程实施范围

本轮授权依据：P0 在用户 Windows 本机完成核心启动与 n8n 工作流持久化验证后，用户要求按此前想法继续。沿用本地、半自动、飞书、多模型配置、面向小红书与抖音的方向。

本轮实现公开 RSS/Atom 采集 → 规范化与来源留存 → URL 去重 → SQLite 原始收件箱 → 人工检查 → 可选 News Inbox 同步。收件箱保留原文语言，摘要有长度上限，发布时间与采集时间分开。更新日期不冒充原始发布时间，缺失发布时间留空。

SQLite schema 2 新增 news_items、news_origins、feed_state、ingestion_runs；从 schema 1 升级前创建完整 SQLite 备份，保留原有 system_state 和用户表。未知 schema 版本拒绝改写。采集记录以规范化 URL 生成稳定 UUID，跨源或重复执行不会重复建新闻行，但跨源出处仍保留。

API 以单进程、单次采集锁运行；RSS 请求有超时、响应体上限、同主机 HTTPS 重定向限制、ETag / Last-Modified 和限流冷却。单源失败记录明确信息，部分结果不会冒充全部成功。意外中断的运行在下一次服务初始化时标为 interrupted。没有额外 Python 后台定时器；定时由导入后显式启用的 n8n 工作流承担。

新接口：GET /api/v1/sources、GET /api/v1/news、GET /api/v1/news/stats、GET /api/v1/ingestion/runs、POST /api/v1/ingestion/run、POST /api/v1/integrations/feishu/sync。POST 接口要求 JSON 请求体。保留 P0 健康、ready、配置及 provider 状态接口。

Feishu News Inbox 使用已有 Base / 表，不自动建表。先验证字段结构，再按 Radar ID 查重，只新增或关联已有记录，不改写远端人工审核字段。创建响应丢失时不盲目重发创建请求，下次先查询远端。没有双向审核同步；没有获取飞书凭据时，功能明确报告未配置，核心 RSS 收件箱仍可使用。

工作流默认 inactive。它提供手动触发与每 15 分钟的定时入口，调用容器内部 api:8000，返回本地人工审核入口或错误提示。人工审核入口是待办提醒，未实现独立事实核查或“已审核”的自动判定。

本轮不调用收费模型，不实现语义事件聚类、自动评分、事实核查结论、内容改写、视频制作、远端消息通知或社交平台发布。多模型 provider 入口保留给后续阶段。
