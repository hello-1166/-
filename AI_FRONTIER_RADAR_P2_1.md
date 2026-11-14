# AI Frontier Radar P2.1：分类选题

新增六类资讯与待分类、内容栏目、开放情况、证据类型和制作进度。新闻收件箱与选题工作台均可组合筛选、人工更正；导出包含标签和备注。默认规则归类不调用模型，继续用现有Plus审稿。

[下载 P2.1 完整工程包](deliverables/AI_Frontier_Radar_P2_1.zip)（打开后点 Download raw file）

[完整使用指南](deliverables/P2_1_GUIDE.md) · [验收报告](deliverables/P2_1_ACCEPTANCE.md) · [SHA256](deliverables/P2_1_SHA256SUMS.txt)

## Windows升级

将新ZIP解压到一个单独的新目录，保持Docker Desktop运行。在新目录中能看到scripts的位置打开PowerShell，每条命令单独执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
.\scripts\upgrade_p2_1.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P2.1 code installed 后，先切回原工程：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

确认提示符是原路径，再启动：

```powershell
.\scripts\start_p0.ps1
```

打开 http://localhost:8000/topics ，按Ctrl+F5刷新。不要从新解压目录启动，不要整目录覆盖或删除数据卷。未知本地修改会阻止升级，请保留报错排查。

原.env、新闻和已选题保留，n8n工作流无需重导。新数据库迁移前会备份，代码备份在backups/p2-1-code-*。

## 分类怎么用

- 主类别：模型与技术突破、产品与功能更新、开发者与智能体、行业应用、商业与生态、工作与社会影响；无法判断留待分类。
- 用筛选框组合开放情况、证据、栏目和制作进度，点击筛选。类别统计是近期全部候选，下方仍保留选题状态过滤。
- 展开卡片的“调整分类与制作进度”，修改需要变更的字段、勾选栏目，保存即可；人工修改下次初筛仍保留。
- “恢复自动分类”保留人工制作进度和备注。
- 右上导出会按当前分类条件导出已选题，带标签、人工/规则来源与出处。清空分类条件可导出全部已选题。

规则分类可能误判，标签不代表已核实或当前账号可用。栏目是制作计划，“本人实测”和“已发布”仅由人工标记。制作进度与加入/忽略选题分别保存，不触发平台发布。原始新闻和事件主条目的标签分别管理，避免一篇新闻的结论自动扩散到整组。

## 验证

125项自动化测试通过，完整ZIP另解压复验通过；桌面和390px浏览器交互通过，JS错误0，模型请求0。PowerShell7/Linux完整P2升级演练保留240条新闻、模拟的9个已选题、模型缓存、配置和笔记，schema3备份与schema4启动验证通过。

本轮未构建/运行P2.1 Docker镜像；Windows最终构建、启动和原定时流程仍需本机验收。源码、测试与证据均在ZIP中，未预装新闻数据。

本交付在独立分支，未合并主分支。历史P2文件保留，当前升级步骤以本页为准。
