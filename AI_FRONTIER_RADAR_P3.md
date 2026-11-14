# AI Frontier Radar P3：内容策划台

新增从已选题创建单条视频、周报、对比或教程策划。支持材料排序、增减、来源快照、受众与主题、核实记录、分镜、人工稿件保存、制作进度和创作材料包导出。沿用现有 ChatGPT Plus，不调用外部模型或自动发布。

[下载 P3 完整工程包](deliverables/AI_Frontier_Radar_P3.zip)（进入后点击 Download raw file）

[完整升级指南](deliverables/P3_GUIDE.md) · [验收记录](deliverables/P3_ACCEPTANCE.md) · [SHA256](deliverables/P3_SHA256SUMS.txt)

## Windows 安装

将 ZIP 解压到独立新目录，在能看到 scripts 的文件夹打开 PowerShell。每条命令单独运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
.\scripts\upgrade_p3.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P3 code installed 后，切回原工程启动：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

```powershell
.\scripts\start_p0.ps1
```

打开 http://localhost:8000/plans ，点“新建内容策划”，勾选已选题后创建；填写内容、保存并导出。材料包交给现有 Plus 完善稿件，粘贴回来保存。新闻、9条已选题、分类和 n8n 无需重新导入。

## 验证

133 项测试通过（包含 PowerShell 升级测试）；打包后解压再运行全部通过。Chromium 已验证桌面和手机、创建、排序、保存刷新、草稿和下载。完整 P2.1 副本升级保留 240 条新闻、9 条已选题及 479 条分类数据。未实际操作用户 Windows 或重启其 Docker Desktop；安装后仍需执行本地启动检查。
