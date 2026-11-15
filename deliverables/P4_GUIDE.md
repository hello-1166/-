# P4：不接写稿模型的视频自动流程

本版提供本地视频制作台、Windows系统语音助手和供Codex使用的专用skill。写稿和新闻判断继续由你与现有Plus完成；不调用写稿API、不部署本地大模型、不使用云端配音API，不自动发布。

## 实际自动流程

保存策划 → 导出创作材料包与视频脚本JSON模板 → 在Plus中完善并人工确认文字 → 导入脚本JSON → 可选上传真实素材 → 加入自动队列 → Windows助手生成系统语音并上传 → 服务自动编排字幕和画面 → 输出MP4、封面、SRT及来源清单 → 人工预览发布。

没有演示素材时，自动使用原始标题和摘要组成资料卡，不会虚构演示。可上传有权使用的PNG、JPG、WebP、MP4、MOV替换卡片。外部素材原声不会混入旁白；短视频会循环，结果页会提示。

## Windows 升级

1. 保持Docker Desktop运行，将P4 ZIP解压到独立的新目录。在能看到 `scripts` 的新目录打开PowerShell。
2. 每条命令单独运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

```powershell
.\scripts\upgrade_p4.ps1 -ExistingProjectPath "F:\github1113\AI_Frontier_Radar_P0"
```

看到 `P4 code installed` 后切回原工程，启动：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

```powershell
.\scripts\start_p0.ps1
```

首次重建需要联网安装FFmpeg、中文字体等依赖，下载和磁盘占用会明显增加，请给Docker留足空间。默认基础镜像改为Python 3.12 Debian bookworm；已有 `.env` 中的自定义 `PYTHON_BASE_IMAGE` 不会被覆盖。

升级前检查整个清单，备份被替换代码；保留 `.env`、data、logs、n8n卷、新闻、选题和策划。数据库首次启动先备份版本5，再新增视频任务表，升级到版本6。不要从新解压目录另起一套容器。

3. 打开 <http://localhost:8000/videos>；旧页面可用Ctrl+F5刷新。内容策划台也有“保存并进入视频制作”按钮。

## 启动一次本机助手

在原项目另开一个PowerShell窗口：

```powershell
cd "F:\github1113\AI_Frontier_Radar_P0"
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\video_worker.ps1
```

保持窗口开启。它每8秒检查一次已加入队列的任务，一次只处理一个；服务离线时等待重连。Ctrl+C停止助手。它不会自动启动Windows任务计划或修改系统启动项。

自动配音使用Windows `System.Speech` 中已启用的中文声音。没有中文声音时任务会显示失败原因，可在Windows设置安装中文语音，或选择“上传本人录音”新建视频任务。不需要购买模型API，但音质取决于本机安装的声音。

指定已安装声音和语速可用：

```powershell
.\scripts\video_worker.ps1 -VoiceName "已安装的声音名称" -Rate 0
```

声音名称应来自本机，不能直接使用上面占位文字。保持一个助手窗口即可。

## 第一期怎么做

1. 在内容策划台保存本期，填好主旨、核实记录和口播；单条策划可直接带入口播，多事件可使用JSON模板。
2. 点击“保存并进入视频制作”。点击“下载本期写稿模板JSON”，与原来的创作材料包一起交给Plus。
3. 要求Plus保留 `plan_id`、`plan_revision`、每条 `topic_id` 和原顺序，填写 `title`、中文 `headline`、`narration`、`credit`。待核实的核心事实先补材料，不编造或强行填入。模型不应替你将 `confirmed` 改成true。
4. 将结果保存为UTF-8 JSON，使用“导入Plus整理好的脚本JSON”。导入不会自动勾选确认。检查来源和文字，选择日报/周报/单条、720p或1080p和配音方式，勾选确认后保存视频任务。
5. 上传每条对应画面，或使用原文资料卡。全部准备完毕后点击“素材准备完毕，加入自动队列”。
6. 保持Docker、电脑和助手运行；助手自动配音、导入并发起视频合成。完成后在页面预览和下载。必须完整看一遍，检查字幕、画面对应关系和事实。

创建视频任务后旁白和来源保存为独立快照。要修改旁白请新建视频任务，以免旧配音与新文字错配。原有策划不会被修改。更换素材或录音会退出自动队列，准备好后重新加入。

## 录音、字幕和静音预览

- 系统语音：按每个字幕语音块的实际PCM时长编排，不需要语音识别模型；块间语气与停顿需人工听取检查。
- 本人录音：支持WAV、MP3、M4A、OGG、FLAC。字幕按文字长度分配音频时长，没有做识别对齐，结果会提示需要校正。请确保录音内容与对应旁白一致。
- 静音预览：无需配音，可先检查版式，画面持续标注“静音预览”。不要将其当成配音成片。
- 默认每期最多10条、总长10分钟、单次上传60MB、每任务上传总量600MB。配音包解压后同样有限制。配置位于 `config/video.yaml`。

系统没有自动清理用户任务文件。视频和素材保存在原项目 `data/video_jobs`，需要预留空间并自行备份。

## 专用skill

工程包含 `.agents/skills/radar-video-bulletin/SKILL.md`。支持读取项目skills的Codex可根据它调用本地API创建任务、排队、检查并下载结果。Skill是流程说明，Windows助手才是持续执行配音与排队的程序；不使用Codex也能在页面运行整套流程。

这版使用FFmpeg固定模板，没有安装Remotion，也不需要Node或视频生成大模型。未来需要复杂动画时可以更换渲染器，现有选题和策划仍保留。

## 已知验证边界

本轮在Linux上完成真实FFmpeg编码、浏览器操作和PowerShell助手的“已上传录音”队列协议验证。Windows系统语音脚本已做语法检查，但没有在用户的Windows声音包上实际发声。

Docker Compose配置验证通过；云端镜像完整构建尝试因磁盘不足停止，因此不能声称镜像已成功启动。请在Windows按上述启动脚本完成实际构建与健康检查。如果构建报错，请保留最早出现的错误段，勿删除data或n8n卷。

代码回退前先停止服务并备份当前数据；旧P3/P3.1不识别版本6，应恢复相匹配的旧代码与升级前数据库。恢复旧数据库会丢失之后的新增记录，请先导出需要保留的内容。
