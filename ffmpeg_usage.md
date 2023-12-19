## FFmpeg使用示例

------



Windows bat:

```bash
@echo off
::ffmpeg使用示例

set FFPATH=F:\Program_Files\FormatFactory
set Path=%FFPATH%;%Path%


::音频\视频直接混流
set IN_V=videoplayback.mp4
set IN_A=videoplayback.m4a
set OUT=output.mp4
ffmpeg.exe -i %IN_V% -i %IN_A% -c copy -map 0:v:0 -map 1:a:0 %OUT%


::不转码，直接切割视频
set IN_V=videoplayback.mp4
set OUT=output.mp4
set TS=00:00:00
set TE=00:04:00
::ffmpeg.exe -ss %TS% -i %IN_V% -c copy -t %TE% %OUT%
ffmpeg.exe -ss %TS% -to %TE% -i %IN_V% -vcodec copy -acodec copy %OUT% -y

::不转码，直接合并多个视频
echo file '1.mp4' > filelist.txt
echo file '2.mp4' >> filelist.txt
ffmpeg.exe -f concat -i filelist.txt -c copy combine.mp4
```



