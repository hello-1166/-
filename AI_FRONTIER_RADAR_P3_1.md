# AI Frontier Radar P3.1：创作者规则推荐

从泛关键词评分改为具体任务、变化线索和材料要求。摘要不足、缺有效链接或传闻不会自动推荐；区分研究观察、培训活动和专业医疗方案；默认同方向每轮最多3项。卡片显示命中依据、未推荐原因及针对方向的建议角度，导出保留这些信息。

[下载 P3.1 完整工程包](deliverables/AI_Frontier_Radar_P3_1.zip)（进入后点击 Download raw file）

[完整指南](deliverables/P3_1_GUIDE.md) · [验收记录](deliverables/P3_1_ACCEPTANCE.md) · [SHA256](deliverables/P3_1_SHA256SUMS.txt)

## Windows 升级

新包解压到独立目录。在能看到 scripts 的位置打开 PowerShell，逐条执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
.\scripts\upgrade_p3_1.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P3.1 code installed 后：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

```powershell
.\scripts\start_p0.ps1
```

打开 http://localhost:8000/topics ，Ctrl+F5 刷新并点“重新初筛”。已有选题、分类和策划保留；不需要把已选题恢复为待选择。沿用现有 Plus，无模型 API 调用。

最终ZIP解压后153项测试通过；Chromium验证推荐原因、导出和手机页面；完整P3副本升级保留240条新闻、9条选题、479条分类记录及既有策划。未操作用户Windows或重启其Docker Desktop。规则仍依赖标题/摘要，不能取代事实核查或预测流量。
