# AI Frontier Radar P1：Windows 升级指南

本版按既定的本地、半自动、飞书和多模型方向，完成公开 AI RSS 采集、链接去重、原文出处保留、中文待审核列表和可选飞书同步。当前不调用模型。

[下载完整 P1 工程包](deliverables/AI_Frontier_Radar_P1.zip)（打开页面后点击 Download raw file 下载）

[验收报告](deliverables/P1_ACCEPTANCE.md) · [SHA256](deliverables/P1_SHA256SUMS.txt) · [飞书配置](docs/P1_FEISHU_SETUP.md)

## 升级原来的 Windows 工程

1. 保持 Docker Desktop 运行。
2. 将新 ZIP 解压到单独的新目录，不直接覆盖旧工程。包内目录名仍为 AI_Frontier_Radar_P0，以兼容已有项目。
3. 在新解压目录（包含 scripts 文件夹的位置）打开 PowerShell，执行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\upgrade_p1.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 P1 code installed 后，再执行：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
.\scripts\start_p0.ps1
```

升级先校验并备份代码，保留旧 .env、data、logs 与用户文件。若出现未知本地修改，脚本会停止；保留错误输出排查，不要强行覆盖。不要删除数据卷或执行 docker compose down -v。

## 启动后

打开 http://localhost:8000/radar ，点击“采集一次”，检查来源和采集结果。开发环境首次实采 240 条，交付包不预装新闻，用户实际条数随时间和网络变化。

打开 http://localhost:5678 ，确认 P0_验收测试 仍在。导入原工程目录中的 workflows/01_news_ingestion.json，先手动执行并检查结果，再启用定时采集。

飞书默认关闭。按配置文档在本机设置应用和表权限，先验证 1 条写入。不要把密钥发到聊天或提交 GitHub。

## 验证状态

59 项自动化测试通过，7 个公开 RSS 实测可用，链接去重和本地浏览器交互已验证。真实 Windows P1 升级、n8n 导入执行、飞书写入仍需用户本机验收；模拟测试不能代替这些项目。所有收录内容仍需人工核查。

交付位于独立 P1 分支，尚未合并 main。完整源码、测试、文档和测试证据均在 ZIP 内。
