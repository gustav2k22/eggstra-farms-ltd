#!/bin/bash

# Replace specific opacity values in product_details_screen.dart
FILE="/home/gustavo/Desktop/BTech/Mobile-App-Dev/Cursor&Windsurf/Windsurf/eggstra-farms-ltd/lib/features/products/product_details_screen.dart"

# Replace withOpacity(0.9) with withValues(alpha: 230)
sed -i 's/\.withOpacity(0\.9)/\.withValues(alpha: 230)/g' "$FILE"

# Replace withOpacity(0.1) with withValues(alpha: 26)
sed -i 's/\.withOpacity(0\.1)/\.withValues(alpha: 26)/g' "$FILE"

# Replace withOpacity(0.05) with withValues(alpha: 13)
sed -i 's/\.withOpacity(0\.05)/\.withValues(alpha: 13)/g' "$FILE"

# Replace withOpacity(0.4) with withValues(alpha: 102)
sed -i 's/\.withOpacity(0\.4)/\.withValues(alpha: 102)/g' "$FILE"

echo "Replacements completed!"
