from pathlib import Path
import tempfile
import subprocess
import unittest
import wave
from radar_reference_upload import normalize_reference, ReferenceAudioError
from patch_upload import patch_text, MARKER

class ReferenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory();cls.root=Path(cls.temp.name)
        cls.wav=cls.root/'tone.wav';cls.m4a=cls.root/'voice.m4a';cls.mp4=cls.root/'voice.mp4';cls.video=cls.root/'silent-video.mp4'
        def run(args):subprocess.run(['ffmpeg','-v','error',*args],check=True,capture_output=True)
        run(['-f','lavfi','-i','sine=frequency=440:duration=1','-ar','44100','-ac','2',str(cls.wav)])
        run(['-i',str(cls.wav),'-c:a','aac',str(cls.m4a)])
        run(['-f','lavfi','-i','color=black:s=16x16:d=1','-i',str(cls.m4a),'-c:v','libx264','-c:a','copy','-shortest',str(cls.mp4)])
        run(['-f','lavfi','-i','color=black:s=16x16:d=1','-c:v','libx264',str(cls.video)])
    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()
    def convert(self,p):
        output,seconds=normalize_reference(str(p),str(self.root/'converted'))
        with wave.open(output,'rb') as w:self.assertEqual((w.getnchannels(),w.getframerate(),w.getsampwidth()),(1,24000,2))
        self.assertGreater(seconds,.8);self.assertLess(seconds,1.2);return output
    def test_wav(self):self.convert(self.wav)
    def test_m4a(self):self.convert(self.m4a)
    def test_video_with_audio(self):self.convert(self.mp4)
    def test_unknown_extension_and_shell_characters(self):
        p=self.root/"voice';&$.data";p.write_bytes(self.m4a.read_bytes());self.convert(p)
    def test_no_audio_track(self):
        before=set((self.root/'converted').glob('*'))
        with self.assertRaises(ReferenceAudioError):normalize_reference(str(self.video),str(self.root/'converted'))
        self.assertEqual(before,set((self.root/'converted').glob('*')))
    def test_invalid_file(self):
        p=self.root/'broken.wav';p.write_text('not audio')
        with self.assertRaises(ReferenceAudioError):normalize_reference(str(p),str(self.root/'converted'))
    def test_duration_limited(self):
        p=self.root/'long.wav';subprocess.run(['ffmpeg','-v','error','-f','lavfi','-i','sine=frequency=440:duration=22',str(p)],check=True,capture_output=True)
        _,seconds=normalize_reference(str(p),str(self.root/'converted'));self.assertLessEqual(seconds,20)
    def test_input_unchanged(self):
        before=self.m4a.read_bytes();a=self.convert(self.m4a);b=self.convert(self.m4a);self.assertNotEqual(a,b);self.assertEqual(before,self.m4a.read_bytes())

class PatchTests(unittest.TestCase):
    def test_known_source_patch_and_idempotency(self):
        original=Path('/workspace/indextts-fast-source/source/webui.py').read_text()
        updated=patch_text(original)
        self.assertIn(MARKER,updated);self.assertIn('file_types=None',updated);self.assertIn('compatible_reference.upload(',updated)
        self.assertEqual(patch_text(updated),updated)
    def test_unknown_source_rejected(self):
        with self.assertRaises(ValueError):patch_text('print(123)')

if __name__=='__main__':unittest.main(verbosity=2)
