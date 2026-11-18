"""Patch only the known reference component and bind a generic-file fallback."""
from pathlib import Path
import ast
import datetime
import hashlib
import json
import sys

MARKER = '# RADAR_GENERIC_REFERENCE_UPLOAD_V1'


def patch_text(text: str) -> str:
    if MARKER in text:
        return text
    import_anchor = 'import gradio as gr\n'
    component_anchor = '''                save_preset_btn = gr.Button(
                    i18n("保存为预设"), interactive=False
                )'''
    event_anchor = '    prompt_audio.upload(update_prompt_audio,'
    for anchor in [import_anchor, component_anchor, event_anchor]:
        if text.count(anchor) != 1:
            raise ValueError('页面版本与此补丁不匹配，已停止修改。')
    imports = '''import gradio as gr
from radar_reference_upload import normalize_reference, ReferenceAudioError

# RADAR_GENERIC_REFERENCE_UPLOAD_V1

def _radar_load_reference(path):
    try:
        audio_path, seconds = normalize_reference(path)
    except ReferenceAudioError as error:
        raise gr.Error(str(error)) from None
    return audio_path, f"已加载 {seconds:.1f} 秒参考录音，可以生成语音。", gr.update(interactive=True), gr.update(interactive=True)
'''
    component = component_anchor + '''
                compatible_reference = gr.File(
                    label="兼容上传：录音或视频（自动转WAV，最多20秒）",
                    file_count="single",
                    file_types=None,
                    type="filepath",
                )
                compatible_status = gr.Markdown("原上传框报格式错误时，请使用这里选择文件。")'''
    event = '''    compatible_reference.upload(
        _radar_load_reference,
        inputs=[compatible_reference],
        outputs=[prompt_audio, compatible_status, gen_button, save_preset_btn],
    )

''' + event_anchor
    result = text.replace(import_anchor, imports).replace(component_anchor, component).replace(event_anchor, event)
    ast.parse(result)
    return result


def main():
    root = Path(sys.argv[1]).resolve()
    path = root / 'webui.py'
    original = path.read_text(encoding='utf-8-sig')
    updated = patch_text(original)
    helper = root / 'radar_reference_upload.py'
    if not helper.is_file():
        raise ValueError('缺少本地音频转换模块，已停止修改。')
    ast.parse(helper.read_text(encoding='utf-8-sig'))
    if original == updated:
        print('Upload fallback already installed.')
        return
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = root / ('webui.py.before-upload-fix-' + stamp + '.bak')
    backup.write_bytes(path.read_bytes())
    temporary = root / ('webui.py.upload-fix-' + stamp + '.tmp')
    temporary.write_text(updated, encoding='utf-8')
    temporary.replace(path)
    (root / 'RADAR_UPLOAD_FIX.json').write_text(json.dumps({'version':1,'backup':str(backup),'before_sha256':hashlib.sha256(original.encode()).hexdigest(),'after_sha256':hashlib.sha256(updated.encode()).hexdigest()},ensure_ascii=False,indent=2),encoding='utf-8')
    print('Reference upload fallback installed. Original WebUI backed up: ' + str(backup))


if __name__ == '__main__':
    main()
