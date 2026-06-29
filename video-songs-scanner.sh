#!/data/data/com.termux/files/usr/bin/bash
# pre-requisites 
# 1 pkg install bash ffmpeg bc
# 2 bash

# to remove hidden character: sed -i 's/\r$//' video-songs-scanner.sh
# to move finally : bash video-songs-scanner.sh --move

# =====================================================
# Movie Scanner & Mover
# =====================================================

# Directory to scan
SCAN_DIR="/storage/4394-8998"

# Directory to exclude from scanning
# Directories to exclude
EXCLUDE_DIRS=(
    "/storage/4394-8998/video songs"
    "/storage/4394-8998/Android"
	"/storage/emulated/0/Android/media/com.whatsapp/WhatsApp"
	"/storage/emulated/0/Movies/Instagram"
	"/storage/emulated/0/Android"
    "/storage/4394-8998/Movies"
    "/storage/4394-8998/Movies/Movies Todo"
)

# Directory where found movies will be moved
DEST_DIR="/storage/4394-8998/video songs"

# Set to true to only print what would be moved.
# Change to false when you're happy with the results.
DRY_RUN=true

# Movie detection parameters
MIN_MINUTES=2
MAX_MINUTES=5
MIN_SIZE_MB=2

# Output log
OUTPUT="$HOME/movies_found.txt"

# =====================================================

# Override with first argument if provided

if [ "$1" = "--move" ]; then
    DRY_RUN=false
fi

# =====================================================

mkdir -p "$DEST_DIR"
> "$OUTPUT"

echo "Scanning: $SCAN_DIR"
echo "Excluding: $EXCLUDE_DIR"
echo "Destination: $DEST_DIR"
echo

find_cmd=(find "$SCAN_DIR")

for dir in "${EXCLUDE_DIRS[@]}"; do
    find_cmd+=( -path "$dir" -prune -o )
done

find_cmd+=(
    -type f
    \( \
        -iname "*.mp4" -o \
        -iname "*.mkv" -o \
        -iname "*.avi" -o \
        -iname "*.mov" -o \
        -iname "*.m4v" -o \
        -iname "*.webm" \
    \)
    -print
)

"${find_cmd[@]}" | while IFS= read -r file
do
    base=$(basename "$file")

    # Skip filenames that look like TV episodes
    if echo "$base" | grep -Eiq 'S[0-9]{1,2}E[0-9]{1,2}|Episode|EP[0-9]{1,2}'; then
        continue
    fi

    # File size in MB
    size_mb=$(( $(stat -c%s "$file") / 1024 / 1024 ))

    if [ "$size_mb" -lt "$MIN_SIZE_MB" ]; then
        continue
    fi

    # Video duration (seconds)
    duration=$(ffprobe \
        -v error \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 \
        "$file" 2>/dev/null)

    [ -z "$duration" ] && continue

    minutes=$(printf "%.0f" "$(echo "$duration / 60" | bc -l)")

    if [ "$minutes" -lt "$MIN_MINUTES" ] || [ "$minutes" -gt "$MAX_MINUTES" ]; then
        continue
    fi

    printf "%2dh %02dm | %4d MB | %s\n" \
        $((minutes/60)) \
        $((minutes%60)) \
        "$size_mb" \
        "$file" | tee -a "$OUTPUT"

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would move to: $DEST_DIR"
    else
        mv -n "$file" "$DEST_DIR/"
    fi

    echo
done

echo "----------------------------------------"

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN completed."
    echo "No files were moved."
    echo
    echo "If everything looks correct, edit the script and change:"
    echo "DRY_RUN=true"
    echo "to"
    echo "DRY_RUN=false"
else
    echo "Movie moving completed."
fi

echo
echo "Log saved to:"
echo "$OUTPUT"