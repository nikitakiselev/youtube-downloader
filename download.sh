#!/usr/bin/env bash
# Скачивает видео с YouTube с оригинальной озвучкой и русскими субтитрами.
#
# Использование:
#   ./download.sh [--soft] [-o ПАПКА] [-l ЯЗЫК] URL
#
#   по умолчанию  субтитры вшиваются в картинку (видны в любом плеере), результат .mp4
#   --soft        субтитры добавляются отдельной дорожкой (без перекодирования), результат .mkv
#   -o ПАПКА      куда сохранить результат (по умолчанию текущая папка)
#   -l ЯЗЫК       язык субтитров (по умолчанию ru)
#   -c ФАЙЛ       cookies.txt, если YouTube просит подтвердить, что вы не бот
#   -q ВЫСОТА     максимальное качество по вертикали (по умолчанию 1080)
#
# Дополнительные аргументы для yt-dlp можно передать через переменную YTDLP_ARGS,
# пресет x264 для вшивания субтитров — через X264_PRESET (по умолчанию medium).
#
# Нужны: yt-dlp, ffmpeg (с libass) и, желательно, deno (для JS-проверок YouTube).
set -euo pipefail

mode=burn
outdir=.
lang=ru
height=1080
cookies=()
read -r -a extra <<< "${YTDLP_ARGS:-}"

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --soft) mode=soft; shift ;;
    -o) outdir=$2; shift 2 ;;
    -l) lang=$2; shift 2 ;;
    -c) cookies=(--cookies "$2"); shift 2 ;;
    -q) height=$2; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Неизвестный параметр: $1" >&2; usage 1 ;;
    *) url=$1; shift ;;
  esac
done
[[ -n "${url:-}" ]] || usage 1

for bin in yt-dlp ffmpeg; do
  command -v "$bin" >/dev/null || { echo "Не найден $bin — установите его." >&2; exit 1; }
done

mkdir -p "$outdir"
outdir=$(cd "$outdir" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Видео + оригинальная аудиодорожка (у видео с несколькими озвучками
# оригинальная помечена "original"), субтитры: ручные, а если их нет —
# автоматические (в т.ч. автоперевод YouTube).
h="[height<=$height]"
yt-dlp ${cookies[@]+"${cookies[@]}"} ${extra[@]+"${extra[@]}"} \
  -f "bv*$h+ba[format_note*=original]/bv*$h+ba/b$h/b" \
  --merge-output-format mkv \
  --write-subs --write-auto-subs \
  --sub-langs "$lang" --sub-format "srt/vtt/best" --convert-subs srt \
  -o "%(title)s [%(id)s].%(ext)s" -P "$work" \
  "$url"

video=$(find "$work" -maxdepth 1 -type f \( -name '*.mkv' -o -name '*.mp4' -o -name '*.webm' \) | head -n1)
subs=$(find "$work" -maxdepth 1 -type f -name "*.$lang.srt" | head -n1)

[[ -n "$video" ]] || { echo "Видео не скачалось." >&2; exit 1; }
[[ -n "$subs" ]] || { echo "У этого видео нет субтитров на языке '$lang'." >&2; exit 1; }

name=$(basename "${video%.*}")
# Фильтру subtitles неудобно передавать пути со спецсимволами — используем простое имя.
cp "$subs" "$work/subs.srt"

if [[ $mode == burn ]]; then
  out="$outdir/$name.$lang.mp4"
  (cd "$work" && ffmpeg -hide_banner -y -i "$video" \
    -map 0:v:0 -map 0:a:0 \
    -vf "subtitles=subs.srt" \
    -c:v libx264 -preset "${X264_PRESET:-medium}" -crf 20 -pix_fmt yuv420p \
    -c:a aac -b:a 192k -movflags +faststart \
    "$out")
else
  out="$outdir/$name.$lang.mkv"
  ffmpeg -hide_banner -y -i "$video" -i "$work/subs.srt" \
    -map 0:v:0 -map 0:a:0 -map 1:0 -c copy \
    -metadata:s:s:0 language="$lang" -disposition:s:0 default \
    "$out"
fi

echo
echo "Готово: $out"
