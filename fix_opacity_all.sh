#!/bin/bash

# Directory containing all the Flutter files to fix
DIR="/home/gustavo/Desktop/BTech/Mobile-App-Dev/Cursor&Windsurf/Windsurf/eggstra-farms-ltd/lib/features"

# Function to convert opacity value to alpha integer (0.0-1.0 to 0-255)
convert_opacity_to_alpha() {
    local opacity=$1
    local alpha=$(echo "$opacity * 255" | bc)
    echo ${alpha%.*} # Remove decimal part
}

# Common opacity values and their alpha equivalents
# 0.1 -> 26
# 0.2 -> 51
# 0.3 -> 77
# 0.4 -> 102
# 0.5 -> 128
# 0.6 -> 153
# 0.7 -> 179
# 0.8 -> 204
# 0.9 -> 230
# 0.05 -> 13

echo "Starting to fix deprecated withOpacity calls..."

# Fix opacity values one by one for better control and accuracy
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.1)/\.withValues(alpha: 26)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.2)/\.withValues(alpha: 51)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.3)/\.withValues(alpha: 77)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.4)/\.withValues(alpha: 102)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.5)/\.withValues(alpha: 128)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.6)/\.withValues(alpha: 153)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.7)/\.withValues(alpha: 179)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.8)/\.withValues(alpha: 204)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.9)/\.withValues(alpha: 230)/g' {} \;
find "$DIR" -name "*.dart" -type f -exec sed -i 's/\.withOpacity(0\.05)/\.withValues(alpha: 13)/g' {} \;

echo "Fix completed! Checking for any remaining withOpacity calls..."

# Check if any withOpacity calls remain
remaining=$(grep -r "withOpacity" "$DIR" | wc -l)

echo "Remaining withOpacity calls: $remaining"
if [ "$remaining" -gt 0 ]; then
  echo "Some withOpacity calls may need manual intervention."
  grep -r "withOpacity" "$DIR"
else
  echo "All withOpacity calls have been successfully replaced!"
fi
