#!/bin/bash
# Downloads Pokemon sprites and creates asset catalog structure

SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$SCRIPT_DIR/../PokéJournal/PokéJournal"
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets/Sprites"
JSON_FILE="$PROJECT_DIR/Resources/pokemon.json"

# Create sprites directory
mkdir -p "$ASSETS_DIR"

# Create Contents.json for the folder
cat > "$ASSETS_DIR/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "Downloading sprites from pokemon.json..."

# Parse JSON and download each sprite
# Using python for reliable JSON parsing
python3 << PYEOF
import json
import urllib.request
import os

assets_dir = "$ASSETS_DIR"
json_file = "$JSON_FILE"

with open(json_file, 'r') as f:
    pokemon_list = json.load(f)

for pokemon in pokemon_list:
    pid = pokemon['id']
    name = pokemon['name_en'].lower()

    # Official artwork
    official_url = pokemon.get('sprite_url', '')
    # Pixel sprite
    pixel_url = pokemon.get('sprite_pixel_url', '')

    if official_url:
        # Create imageset directory
        imageset_dir = os.path.join(assets_dir, f"pokemon_{pid}.imageset")
        os.makedirs(imageset_dir, exist_ok=True)

        # Download official sprite
        try:
            print(f"Downloading {name} (#{pid})...")
            urllib.request.urlretrieve(official_url, os.path.join(imageset_dir, f"{pid}.png"))

            # Create Contents.json
            contents = {
                "images": [
                    {
                        "filename": f"{pid}.png",
                        "idiom": "universal",
                        "scale": "1x"
                    }
                ],
                "info": {
                    "author": "xcode",
                    "version": 1
                }
            }

            with open(os.path.join(imageset_dir, "Contents.json"), 'w') as cf:
                json.dump(contents, cf, indent=2)

        except Exception as e:
            print(f"Error downloading {name}: {e}")

print("Done!")
PYEOF

echo ""
echo "Sprites downloaded to: $ASSETS_DIR"
echo "Now update PokemonSpriteView.swift to load from assets."
