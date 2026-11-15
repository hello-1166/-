# AI Frontier Radar P4：本地视频自动流程

从已有策划创建日报、周报或单条视频任务。导入Plus定稿JSON，上传真实素材或使用原文资料卡；Windows助手领取已确认任务，使用系统语音配音并上传，服务自动合成竖屏MP4、封面、SRT与来源清单。

不接写稿API或本地大语言模型、不调用云配音、不自动发布。专用skill在工程 `.agents/skills/radar-video-bulletin/SKILL.md`，日常运行不依赖安装Codex。

[下载P4完整工程包](deliverables/AI_Frontier_Radar_P4.zip)（进入后点击 Download raw file）

[完整Windows指南](deliverables/P4_GUIDE.md) · [验收记录与限制](deliverables/P4_ACCEPTANCE.md) · [SHA256](deliverables/P4_SHA256SUMS.txt)

## Windows 升级

将新包解压到独立目录，在能看到scripts的位置打开PowerShell，逐条运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
.\scripts\upgrade_p4.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

成功后切回原工程启动：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

```powershell
.\scripts\start_p0.ps1
```

在原工程另开PowerShell，运行助手并保持窗口开启：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\video_worker.ps1
```

打开 http://localhost:8000/videos ，导入策划与定稿JSON，确认文字，保存任务并准备素材，点击“素材准备完毕，加入自动队列”。没有画面素材时自动使用原文资料卡。

## 验证与限制

最终ZIP解压后171项测试通过；真实FFmpeg编码、浏览器、助手上传录音模式的队列协议、字幕与下载通过。升级演练保留240条新闻、9条选题、479条分类记录和1份原有策划。

**云端Docker完整镜像构建因磁盘不足未通过，需在Windows完成首次构建和健康检查；Windows中文系统语音实际发声也需在本机验证。** 首次构建会下载FFmpeg和中文字体，需给Docker留足空间。语音脚本解析已通过；测试音轨仅为仿真PCM，不能称为真实中文旁白验证。
