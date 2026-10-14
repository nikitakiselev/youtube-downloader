# youtube-downloader

`download.sh` скачивает видео с YouTube в лучшем доступном качестве. Звук остаётся оригинальным, к видео добавляются русские субтитры.

## Установка

- [yt-dlp](https://github.com/yt-dlp/yt-dlp#installation)
- [ffmpeg](https://ffmpeg.org/download.html)
- [deno](https://deno.com/) — желательно, yt-dlp использует его для обхода JS-проверок YouTube

macOS: `brew install yt-dlp ffmpeg deno`

## Использование

```bash
# субтитры вшиты в картинку: видны в любом плеере и на телефоне (.mp4)
./download.sh "https://youtu.be/M6OAZGwPqHM"

# субтитры отдельной дорожкой, их можно выключить; работает быстрее, без перекодирования (.mkv)
./download.sh --soft "https://youtu.be/M6OAZGwPqHM"
```

Параметры: `-o ПАПКА` задаёт, куда сохранить файл. `-l en` выбирает другой язык субтитров. `-c cookies.txt` нужен, если YouTube пишет «Sign in to confirm you're not a bot».

Если у ролика нет русских субтитров от автора, берутся автоматические от YouTube (автоперевод).

### Без скрипта (Windows и т.п.)

Тот же результат с отдельной дорожкой субтитров одной командой:

```bash
yt-dlp -f "bv*+ba[format_note*=original]/bv*+ba/b" --merge-output-format mkv --write-subs --write-auto-subs --sub-langs ru --sub-format "srt/vtt/best" --convert-subs srt --embed-subs "https://youtu.be/M6OAZGwPqHM"
```
