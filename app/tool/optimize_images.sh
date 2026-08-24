#!/usr/bin/env bash
set -euo pipefail

# Mobile cards render at roughly 120 logical pixels. A 400px source remains
# crisp at 3x density without paying for oversized decodes or package bytes.
MAX_SIZE=400
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIRS=(
  "$APP_DIR/assets/images/food"
  "$APP_DIR/assets/images/drinks"
  "$APP_DIR/assets/images/home"
)

if ! command -v cwebp >/dev/null 2>&1; then
  echo "cwebp is required (brew install webp)."
  exit 1
fi

saved_bytes=0

for image_dir in "${DIRS[@]}"; do
  [ -d "$image_dir" ] || continue
  while IFS= read -r -d '' source_file; do
    output_file="${source_file%.*}.webp"

    if command -v sips >/dev/null 2>&1; then
      width="$(sips -g pixelWidth "$source_file" 2>/dev/null | awk '/pixelWidth:/ {print $2}')"
      height="$(sips -g pixelHeight "$source_file" 2>/dev/null | awk '/pixelHeight:/ {print $2}')"
      if [ -n "$width" ] && [ -n "$height" ] &&
         { [ "$width" -gt "$MAX_SIZE" ] || [ "$height" -gt "$MAX_SIZE" ]; }; then
        sips -Z "$MAX_SIZE" "$source_file" >/dev/null
      fi
    fi

    before_bytes="$(wc -c < "$source_file" | tr -d ' ')"
    # Lossless preserves transparent cutouts pixel-for-pixel. Existing JPEGs
    # are deliberately excluded to avoid a second lossy generation.
    cwebp -quiet -lossless -z 6 -metadata none "$source_file" -o "$output_file"
    after_bytes="$(wc -c < "$output_file" | tr -d ' ')"

    if [ "$after_bytes" -lt "$before_bytes" ]; then
      saved_bytes=$((saved_bytes + before_bytes - after_bytes))
      rm "$source_file"
      echo "optimized $(basename "$source_file") -> $(basename "$output_file")"
    else
      rm "$output_file"
    fi
  done < <(find "$image_dir" -type f -name '*.png' -print0)
done

echo "saved $((saved_bytes / 1024)) KB"
