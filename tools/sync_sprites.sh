#!/bin/sh
# Copies the finished band sprites from the asset repo into the game, as
# described in the-lost-cats--assets/sprites/INTEGRATION.md §1.
# Re-run whenever sprites/CHANGELOG.md in the asset repo gets a new version.
#   sh tools/sync_sprites.sh [member ...]     (default: all finished members)
set -e
SRC="${LOST_CATS_ASSETS:-$(cd "$(dirname "$0")/../.." && pwd)/the-lost-cats--assets}/sprites"
DST="$(cd "$(dirname "$0")/.." && pwd)"
MEMBERS="${*:-keys_joep bass_jay}"

[ -d "$SRC" ] || { echo "asset repo not found: $SRC (set LOST_CATS_ASSETS)"; exit 1; }
for m in $MEMBERS; do
	mkdir -p "$DST/assets/sprites/characters/$m"
	for f in "${m}_sheet.png" "${m}_frames.tres" "$m.json"; do
		cp "$SRC/$m/export/$f" "$DST/assets/sprites/characters/$m/$f"
	done
	echo "synced $m"
done
mkdir -p "$DST/assets/sprites/fx"
cp "$SRC"/_shared/fx/*.png "$DST/assets/sprites/fx/"
mkdir -p "$DST/assets/sprites/vehicles"
cp "$SRC"/_shared/vehicles/bike_parked_*.png "$DST/assets/sprites/vehicles/"
cp "$SRC/_godot/jtc_bike.gd" "$DST/scripts/world/jtc_bike.gd"
cp "$SRC/_godot/jtc_sprite_data.gd" "$DST/scripts/characters/jtc_sprite_data.gd"
echo "synced fx + jtc_sprite_data.gd ($(head -2 "$SRC/CHANGELOG.md" | tail -1))"
