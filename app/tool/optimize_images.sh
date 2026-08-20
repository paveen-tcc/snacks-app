#!/usr/bin/env bash
set -e

# Target max resolution for mobile cards (retina @3x = ~360px, so 400px is crisp)
MAX_SIZE=400

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DIRS=(
  "$APP_DIR/assets/images/food"
  "$APP_DIR/assets/images/drinks"
)

echo "🖼️  Optimizing food & drinks assets in Flutter app..."
echo "Target maximum dimension: ${MAX_SIZE}px"
echo "----------------------------------------------------"

TOTAL_BEFORE=0
TOTAL_AFTER=0

for DIR in "${DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    echo "📁 Scanning directory: $(basename "$DIR")"
    for IMG in "$DIR"/*.png "$DIR"/*.jpg "$DIR"/*.jpeg; do
      [ -f "$IMG" ] || continue
      
      FILENAME="$(basename "$IMG")"
      SIZE_KB=$(du -k "$IMG" | cut -f1)
      
      # Get current dimensions using sips (macOS)
      if command -v sips >/dev/null 2>&1; then
        WIDTH=$(sips -g pixelWidth "$IMG" 2>/dev/null | awk '/pixelWidth:/ {print $2}')
        HEIGHT=$(sips -g pixelHeight "$IMG" 2>/dev/null | awk '/pixelHeight:/ {print $2}')
        
        if [ -n "$WIDTH" ] && [ -n "$HEIGHT" ]; then
          if [ "$WIDTH" -gt "$MAX_SIZE" ] || [ "$HEIGHT" -gt "$MAX_SIZE" ]; then
            BEFORE_BYTES=$(wc -c < "$IMG" | tr -d ' ')
            TOTAL_BEFORE=$((TOTAL_BEFORE + BEFORE_BYTES))
            
            # Resize image to fit within MAX_SIZExMAX_SIZE preserving aspect ratio and alpha channel
            sips -Z "$MAX_SIZE" "$IMG" >/dev/null 2>&1
            
            AFTER_BYTES=$(wc -c < "$IMG" | tr -d ' ')
            TOTAL_AFTER=$((TOTAL_AFTER + AFTER_BYTES))
            
            BEFORE_KB=$((BEFORE_BYTES / 1024))
            AFTER_KB=$((AFTER_BYTES / 1024))
            SAVED_PCT=$(( (BEFORE_BYTES - AFTER_BYTES) * 100 / BEFORE_BYTES ))
            
            echo "  ✓ $FILENAME: ${WIDTH}x${HEIGHT} (${BEFORE_KB} KB) -> ${MAX_SIZE}px (${AFTER_KB} KB) [-${SAVED_PCT}%]"
          else
            echo "  - $FILENAME: already optimal (${WIDTH}x${HEIGHT}, ${SIZE_KB} KB)"
          fi
        fi
      fi
    done
  fi
done

echo "----------------------------------------------------"
if [ "$TOTAL_BEFORE" -gt 0 ]; then
  SAVED_TOTAL=$((TOTAL_BEFORE - TOTAL_AFTER))
  PCT=$(( SAVED_TOTAL * 100 / TOTAL_BEFORE ))
  BEFORE_MB=$(( TOTAL_BEFORE / 1048576 ))
  AFTER_MB=$(( TOTAL_AFTER / 1048576 ))
  SAVED_MB=$(( SAVED_TOTAL / 1048576 ))
  echo "🎉 Optimization complete!"
  echo "Total before: ~${BEFORE_MB} MB"
  echo "Total after:  ~${AFTER_MB} MB"
  echo "Saved:        ~${SAVED_MB} MB (${PCT}% reduction)"
else
  echo "✨ All images are already optimal!"
fi
