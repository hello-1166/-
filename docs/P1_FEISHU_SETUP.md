# P1 飞书 News Inbox 配置

先使用本地收件箱验证采集，再配置飞书。无需为 P1 连接 n8n AI 助手或填写模型 API Key。

## 1. 应用权限与表访问

在飞书开放平台准备企业自建应用，开通多维表格读取字段、读取记录、新增记录所需权限，并按控制台要求发布应用。将应用加入目标 Base 的可访问范围，赋予相应读写权限。具体权限名称和入口以当前飞书控制台为准。

准备一个 News Inbox 表，使用以下字段。系统不会替你创建或删除表：

| 字段名 | 类型 | 用途 |
| --- | --- | --- |
| 标题 | 文本（API type 1，可用主字段） | RSS 原标题 |
| Radar ID | 文本（type 1） | 系统去重键，不手工改写 |
| 原文链接 | 超链接（type 15） | 原始文章 URL |
| 来源 | 文本（type 1） | 最先收录的来源名称 |
| 发布时间 | 日期（type 5） | 原始发布时间，未知留空 |
| 采集时间 | 日期（type 5） | 首次收录时间 |
| 审核状态 | 单选（type 3） | 必须预建“待核查”选项，可自行加“已采用”“已忽略”等 |

如你已有表，可在 config/feishu_fields.yaml 修改映射字段名，保留相应字段类型与 Radar ID。重复或不匹配的字段配置会阻止同步。

## 2. 填写本机 .env

在旧工程目录的 `.env` 填写你自己的真实值，只保存在本机：

```dotenv
FEISHU_ENABLED=true
FEISHU_APP_ID=
FEISHU_APP_SECRET=
FEISHU_BITABLE_APP_TOKEN=
FEISHU_NEWS_TABLE_ID=
```

App ID / Secret 来自开放平台应用；App Token 来自目标 Base，News Table ID 来自该表。不要将网页访问令牌、文档 ID 或应用 ID 混当成 Base Token。

P1 News Inbox 同步只要求这四项信息与启用开关。P0 的完整配置状态仍会检查 Content / Source Table ID，但它们不阻止 P1 新闻同步。

.env 变更后需要重新创建 API 容器才能加载新环境变量：

```powershell
docker compose up -d --no-build --force-recreate api
```

## 3. 首次验证

打开 http://localhost:8000/radar。按钮从不可用变为“同步下一批 25 条”，只表示配置项已填写，不代表凭据或权限有效。

先在 API 文档的 POST /api/v1/integrations/feishu/sync 中使用 `{"limit":1}` 同步一条，在飞书核对标题、原文链接、来源、两个时间和待核查状态。确认正确后，再用页面按钮批量同步下一批。模型字段不参与这个步骤。

## 4. 行为与错误

同步仅从本地到飞书新增/关联。已有相同 Radar ID 的记录会关联到本地，不覆盖任何远端字段或人工审核结论。相同 Radar ID 出现多条时停止该条同步，供你检查；系统不会自动删重。

创建后连接中断时，记录保持待同步，下次先查找同一 Radar ID，避免重复创建。HTTP 429 会记录冷却时间，期间不再请求。网络、权限或字段错误不会被当成写入成功，也不会回显 token 或原始鉴权响应。

常见错误：table_schema_mismatch 表示字段名称/类型不符；review_option_missing 表示缺少待核查选项；http_403 或 feishu_数字 表示需要核对权限或开放平台错误码；network_error 表示连接失败。按照具体错误检查，不要删表或重新生成已有 n8n 加密密钥。

真实飞书身份、权限和写入必须在你本机配置后验证。代码中的 MockTransport 测试不能代替这一步。飞书审核状态暂不回写本地，平台内容发布继续由人工决定。
