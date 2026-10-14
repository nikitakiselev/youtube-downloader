# youtube-downloader

`download.sh` скачивает видео с YouTube с **оригинальной озвучкой** и **русскими субтитрами**.

- Звук: если у ролика есть автодубляж, берётся дорожка с пометкой *original*.
- Субтитры: ручные русские, а если их нет — автоперевод YouTube на русский.

## Установка

Нужны `yt-dlp`, `ffmpeg` и [Deno](https://deno.com) (yt-dlp использует его для YouTube).

```bash
# macOS
brew install yt-dlp ffmpeg deno
# Linux
pip install -U yt-dlp && sudo apt install ffmpeg && curl -fsSL https://deno.land/install.sh | sh
```

## Использование

```bash
# MKV с русской дорожкой субтитров (включена по умолчанию, отключается в плеере)
./download.sh "https://youtu.be/M6OAZGwPqHM"

# MP4 с субтитрами, вшитыми в картинку — видны в любом плеере, на телефоне и ТВ
./download.sh -b "https://youtu.be/M6OAZGwPqHM"

# Сохранить в другой каталог
./download.sh -o ~/Videos "https://youtu.be/M6OAZGwPqHM"
```

### Windows (без скрипта)

```powershell
yt-dlp -f "bv*+ba[format_note*=original]/bv*+ba/b" --write-subs --write-auto-subs --sub-langs ru --convert-subs srt --embed-subs --merge-output-format mkv "https://youtu.be/M6OAZGwPqHM"
```
