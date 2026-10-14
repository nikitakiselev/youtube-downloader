#!/usr/bin/env bash
# Скачивает видео с YouTube с оригинальной звуковой дорожкой и русскими субтитрами.
#
#   ./download.sh URL           — MKV со встроенной (отключаемой) русской дорожкой субтитров
#   ./download.sh -b URL        — MP4 с субтитрами, вшитыми прямо в картинку
#   ./download.sh -o DIR URL    — сохранить в каталог DIR (по умолчанию текущий)
set -euo pipefail

usage() {
  sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

BURN=0
OUT_DIR="."
while getopts "bo:h" opt; do
  case "$opt" in
    b) BURN=1 ;;
    o) OUT_DIR="$OPTARG" ;;
    h) usage 0 ;;
    *) usage 1 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage 1
URL="$1"

for bin in yt-dlp ffmpeg ffprobe; do
  command -v "$bin" >/dev/null || { echo "Не найден $bin — установите его." >&2; exit 1; }
done
mkdir -p "$OUT_DIR"

# Если у ролика несколько аудиодорожек (автодубляж YouTube), берём помеченную как original.
FORMAT='bv*+ba[format_note*=original]/bv*+ba/b'

# Ручные русские субтитры, а если их нет — автоперевод YouTube на русский.
SUB_OPTS=(--write-subs --write-auto-subs --sub-langs ru --convert-subs srt)

if [ "$BURN" -eq 0 ]; then
  file=$(yt-dlp -f "$FORMAT" "${SUB_OPTS[@]}" --embed-subs \
    --ppa "EmbedSubtitle:-disposition:s:0 default" \
    --merge-output-format mkv \
    -o "$OUT_DIR/%(title)s [%(id)s].%(ext)s" \
    --print after_move:filepath --no-simulate "$URL")
  if [ -z "$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$file")" ]; then
    echo "Внимание: русских субтитров для этого видео нет, файл сохранён без них: $file" >&2
    exit 2
  fi
  echo "Готово: $file"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

src=$(yt-dlp -f "$FORMAT" "${SUB_OPTS[@]}" \
  -o "$tmp/%(title)s [%(id)s].%(ext)s" \
  --print after_move:filepath --no-simulate "$URL")
sub="${src%.*}.ru.srt"
if [ ! -f "$sub" ]; then
  echo "Русских субтитров для этого видео нет." >&2
  exit 2
fi

# Фильтр subtitles плохо переносит спецсимволы в пути, поэтому даём ему простое имя.
cp "$sub" "$tmp/subs.srt"
name=$(basename "${src%.*}")
out="$(cd "$OUT_DIR" && pwd)/$name.mp4"
(cd "$tmp" && ffmpeg -hide_banner -loglevel error -stats -y -i "$src" \
  -vf "subtitles=subs.srt:force_style='FontSize=22,Outline=2'" \
  -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k -movflags +faststart "$out")
echo "Готово: $out"
