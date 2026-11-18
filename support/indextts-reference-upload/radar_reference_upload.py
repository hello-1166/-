"""Local reference normalization for IndexTTS's generic-file upload fallback."""
from pathlib import Path
import shutil
import subprocess
import uuid
import wave


class ReferenceAudioError(ValueError):
    pass


def normalize_reference(source: str, output_dir: str = 'prompts') -> tuple[str, float]:
    if not source:
        raise ReferenceAudioError('请先选择一段录音或视频。')
    original = Path(source).resolve()
    if not original.is_file():
        raise ReferenceAudioError('文件不存在，请重新上传。')
    if original.stat().st_size > 500 * 1024 * 1024:
        raise ReferenceAudioError('文件超过500MB，请先截取一小段录音或视频。')
    executable = shutil.which('ffmpeg')
    if not executable:
        try:
            import imageio_ffmpeg
            executable = imageio_ffmpeg.get_ffmpeg_exe()
        except (ImportError, RuntimeError, OSError):
            executable = None
    if not executable:
        raise ReferenceAudioError('未找到FFmpeg。请安装FFmpeg后，重新打开PowerShell并启动页面。')
    folder = Path(output_dir).resolve()
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / ('reference-' + uuid.uuid4().hex + '.wav')
    command = [executable, '-nostdin', '-hide_banner', '-loglevel', 'error',
               '-i', str(original), '-map', '0:a:0', '-t', '20', '-vn',
               '-ac', '1', '-ar', '24000', '-c:a', 'pcm_s16le', str(target)]
    try:
        subprocess.run(command, check=True, capture_output=True, timeout=90)
        with wave.open(str(target), 'rb') as audio:
            duration = audio.getnframes() / audio.getframerate()
            if audio.getnchannels() != 1 or audio.getframerate() != 24000 or audio.getsampwidth() != 2 or duration <= 0:
                raise ReferenceAudioError('转换后的录音无效，请换一段录音重试。')
        return str(target), duration
    except subprocess.TimeoutExpired:
        target.unlink(missing_ok=True)
        raise ReferenceAudioError('音频转换超时，请先截取较短的文件再上传。') from None
    except subprocess.CalledProcessError:
        target.unlink(missing_ok=True)
        raise ReferenceAudioError('文件中没有可读取的音轨，或文件损坏。请选择原始录音或视频。') from None
    except (wave.Error, EOFError):
        target.unlink(missing_ok=True)
        raise ReferenceAudioError('转换后的音频无法读取，请换一段录音。') from None
