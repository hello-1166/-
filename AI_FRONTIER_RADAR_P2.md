# AI Frontier Radar P2：自动初筛与选题工作台

本版把“收集新闻”继续推进到“挑出值得讲的候选选题”。自动规则初筛无需密钥；模型分析为可选、手动触发。

[下载完整 P2 工程包](deliverables/AI_Frontier_Radar_P2.zip)（打开后点击 Download raw file）

[完整升级与使用指南](deliverables/P2_GUIDE.md) · [验收报告](deliverables/P2_ACCEPTANCE.md) · [SHA256](deliverables/P2_SHA256SUMS.txt)

## Windows 升级

保持 Docker Desktop 运行。将 ZIP 解压到一个单独的新目录，在包含 scripts 的位置打开 PowerShell。

每条命令单独执行。先在新解压目录运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\upgrade_p2.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P2 code installed 后，先切换到原工程目录：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

确认提示符是原工程路径，再启动：

```powershell
.\scripts\start_p0.ps1
```

脚本校验并备份旧代码，保留 .env、数据库和 n8n 数据卷。发现未知本地修改会在写入前停止，不要强行覆盖。不要整目录覆盖，不要删除数据卷。Windows P2 的最终构建和启动仍需本机验收。

## 开始选题

打开 http://localhost:8000/topics ：

1. 浏览“规则推荐”，查看推荐理由与待核实事项。
2. 展开原始出处，打开原文，核对或实测。
3. 点击“加入选题”或“忽略”，人工决定会保存。
4. 用“导出已选题”取得带出处的 Markdown 清单。

原有15分钟 n8n 工作流无需重新导入；新采集完成后自动初筛。刷新选题页面查看新结果。

规则依据标题和RSS摘要，保留英文原题。事件合并仅为疑似匹配，推荐分不是热度预测。可选模型能补充中文摘要、角度与待核实项，默认关闭；真实模型调用须本机配置准确模型ID和密钥后验证，可能产生费用。

## 验证

94项自动化测试通过；ZIP另目录解压再次通过。使用旧RSS数据快照验证了页面与筛选（239条近期候选、7项推荐，结果随时间变化），模型请求0次；完成P1完整包升级及数据库备份迁移演练。

真实模型测试尚未进行，五类适配器用模拟服务验证；本轮未构建运行P2 Docker镜像，原生API与Compose配置检查通过。完整限制见验收报告。

本版尚不输出完整抖音口播/小红书图文稿，不自动发布。交付保留P1历史文件，P2使用本页指南。
