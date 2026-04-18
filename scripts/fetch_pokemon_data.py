#!/usr/bin/env python3
"""
Fetches Pokemon data from PokéAPI CSV dumps (polite mode) and downloads sprites.

Usage: python3 fetch_pokemon_data.py [--limit N] [--workers N]
"""

import json
import csv
import io
import sys
import urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent / "PokeJournal" / "PokeJournal"
RESOURCES_DIR = PROJECT_DIR / "Resources"
ASSETS_DIR = PROJECT_DIR / "Assets.xcassets" / "Sprites"

# PokéAPI CSV dumps (single download instead of thousands of API calls)
CSV_BASE = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv"
SPRITE_BASE = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon"

HEADERS = {'User-Agent': 'PokéJournal/1.0'}

def fetch_text(url):
    """Fetch text from URL."""
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as response:
        return response.read().decode('utf-8')

def fetch_csv(url):
    """Fetch and parse CSV from URL."""
    text = fetch_text(url)
    return list(csv.DictReader(io.StringIO(text)))

def download_sprite(pokemon_id, sprites_dir):
    """Download sprite for Pokemon."""
    imageset_dir = sprites_dir / f"pokemon_{pokemon_id}.imageset"
    sprite_path = imageset_dir / f"{pokemon_id}.png"

    # Skip if already exists
    if sprite_path.exists():
        return True

    imageset_dir.mkdir(parents=True, exist_ok=True)

    try:
        url = f"{SPRITE_BASE}/other/official-artwork/{pokemon_id}.png"
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=30) as response:
            with open(sprite_path, 'wb') as f:
                f.write(response.read())

        # Create Contents.json
        contents = {
            "images": [{"filename": f"{pokemon_id}.png", "idiom": "universal", "scale": "1x"}],
            "info": {"author": "xcode", "version": 1}
        }
        with open(imageset_dir / "Contents.json", 'w') as f:
            json.dump(contents, f, indent=2)
        return True
    except Exception as e:
        return False

def main():
    limit = None
    workers = 5  # Polite default

    args = sys.argv[1:]
    for i, arg in enumerate(args):
        if arg == "--limit" and i + 1 < len(args):
            limit = int(args[i + 1])
        elif arg == "--workers" and i + 1 < len(args):
            workers = int(args[i + 1])

    print("Fetching Pokemon data from CSV dumps (API-friendly)...")

    # Fetch CSV data (3 requests total instead of 2000+)
    print("  Loading pokemon.csv...")
    pokemon_csv = fetch_csv(f"{CSV_BASE}/pokemon.csv")

    print("  Loading pokemon_species_names.csv...")
    names_csv = fetch_csv(f"{CSV_BASE}/pokemon_species_names.csv")

    print("  Loading pokemon_types.csv...")
    types_csv = fetch_csv(f"{CSV_BASE}/pokemon_types.csv")

    print("  Loading types.csv...")
    type_names_csv = fetch_csv(f"{CSV_BASE}/types.csv")

    print("  Loading pokemon_species.csv...")
    species_csv = fetch_csv(f"{CSV_BASE}/pokemon_species.csv")

    # Build lookup tables
    # German names (language_id 6 = German)
    german_names = {
        row['pokemon_species_id']: row['name']
        for row in names_csv
        if row['local_language_id'] == '6'
    }

    # English names (language_id 9 = English)
    english_names = {
        row['pokemon_species_id']: row['name']
        for row in names_csv
        if row['local_language_id'] == '9'
    }

    # Evolution chain ID per species
    evolution_chains = {
        row['id']: int(row['evolution_chain_id'])
        for row in species_csv
        if row.get('evolution_chain_id')
    }

    # Type ID to name mapping
    type_id_to_name = {row['id']: row['identifier'] for row in type_names_csv}

    # Pokemon types (keyed by pokemon_id, which covers both base and form rows)
    pokemon_types = {}
    for row in types_csv:
        pid = row['pokemon_id']
        type_name = type_id_to_name.get(row['type_id'], 'unknown')
        if pid not in pokemon_types:
            pokemon_types[pid] = []
        pokemon_types[pid].append(type_name)

    # Regional form extraction: identifier suffix → canonical region label.
    # Longer suffixes first so "-galar-standard" wins over "-galar".
    REGIONAL_SUFFIXES = [
        ("-paldea-combat-breed", "paldea"),
        ("-galar-standard", "galar"),
        ("-alola", "alola"),
        ("-galar", "galar"),
        ("-hisui", "hisui"),
        ("-paldea", "paldea"),
    ]

    def extract_regional_form(identifier):
        """Return (base_identifier, region) if this is a regional form, else None.

        Filters out totem/cap/gmax/etc. variants that happen to contain a region
        suffix (e.g. raticate-alola-totem). Base identifier is whatever remains
        after the region suffix is stripped; if it still contains qualifier
        segments (totem, gmax, ...), the form is skipped.
        """
        for suffix, region in REGIONAL_SUFFIXES:
            if identifier.endswith(suffix):
                base = identifier[: -len(suffix)]
                if not base:
                    return None
                if any(seg in base for seg in ("totem", "gmax", "cap", "starter")):
                    return None
                return base, region
        return None

    # Collect regional variants: species_id -> {region: {"types": [...], "sprite_id": int}}
    species_variants = {}
    variant_form_ids = []
    for row in pokemon_csv:
        pid = row['id']
        species_id = row['species_id']
        if int(pid) <= 10000:
            continue

        form = extract_regional_form(row['identifier'])
        if form is None:
            continue

        _, region = form
        variants = species_variants.setdefault(species_id, {})
        # First match wins; prevents e.g. "galar-standard" being overwritten
        # by a later "galar-zen" row (which wouldn't match anyway, but belt-and-braces).
        if region in variants:
            continue
        variants[region] = {
            "types": pokemon_types.get(pid, []),
            "sprite_id": int(pid),
        }
        variant_form_ids.append(int(pid))

    # Build Pokemon list (base forms only; variants are nested per base entry)
    pokemon_data = []
    for row in pokemon_csv:
        pid = row['id']
        species_id = row['species_id']

        if int(pid) > 10000:
            continue

        entry = {
            "id": int(pid),
            "name_de": german_names.get(species_id, row['identifier'].title()),
            "name_en": english_names.get(species_id, row['identifier'].title()),
            "types": pokemon_types.get(pid, []),
            "sprite_url": f"{SPRITE_BASE}/other/official-artwork/{pid}.png",
            "sprite_pixel_url": f"{SPRITE_BASE}/{pid}.png",
            "evolution_chain_id": evolution_chains.get(species_id)
        }
        if species_id in species_variants:
            entry["variants"] = species_variants[species_id]
        pokemon_data.append(entry)

    # Sort and limit
    pokemon_data.sort(key=lambda x: x['id'])
    if limit:
        pokemon_data = pokemon_data[:limit]

    print(f"\nFound {len(pokemon_data)} Pokemon")

    # Create directories
    RESOURCES_DIR.mkdir(parents=True, exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    with open(ASSETS_DIR / "Contents.json", 'w') as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

    # Collect all sprite IDs: base forms + regional variants
    sprite_ids = [p['id'] for p in pokemon_data]
    sprite_ids.extend(variant_form_ids)

    # Download sprites (from GitHub, not API)
    print(f"\nDownloading sprites ({workers} parallel)...")
    completed = 0
    failed = 0

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(download_sprite, sid, ASSETS_DIR): sid
            for sid in sprite_ids
        }

        for future in as_completed(futures):
            completed += 1
            if not future.result():
                failed += 1
            print(f"\r  Progress: {completed}/{len(pokemon_data)} ({failed} failed)", end="", flush=True)

    # Save JSON
    json_path = RESOURCES_DIR / "pokemon.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(pokemon_data, f, ensure_ascii=False, indent=2)

    print(f"\n\nDone!")
    print(f"  Data: {json_path}")
    print(f"  Sprites: {ASSETS_DIR}")
    print(f"  Total: {len(pokemon_data)} Pokemon")
    if failed:
        print(f"  Failed sprites: {failed} (some newer Pokemon may not have artwork)")

if __name__ == "__main__":
    main()
