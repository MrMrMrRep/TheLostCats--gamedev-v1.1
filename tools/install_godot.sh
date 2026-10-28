#!/bin/bash
# Installs the official Godot 4.7.2 Linux editor (checksum-verified) and links
# it as `godot` and `Summer` in ~/.local/bin. Summer Engine 0.7.3 is built on
# Godot 4.7.2 but has no Linux build (see .summer/AGENTS.md).
#   tools/install_godot.sh              editor only
#   tools/install_godot.sh --templates  also the Web export templates
# Used by .claude/hooks/session-start.sh (cloud sessions) and .github/workflows.
set -euo pipefail

VERSION=4.7.2
RELEASE="$VERSION-stable"
URL="https://github.com/godotengine/godot-builds/releases/download/$RELEASE"
# From $URL/SHA512-SUMS.txt
EDITOR_SHA512=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65
TEMPLATES_SHA512=ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079

BIN_DIR="$HOME/.local/bin"
EDITOR_DIR="$HOME/.local/share/godot/$RELEASE"
EDITOR="$EDITOR_DIR/Godot_v${RELEASE}_linux.x86_64"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/$VERSION.stable"

fetch() { # file sha512 dest_dir
  curl -fsSL --retry 4 -o "$3/$1" "$URL/$1"
  echo "$2  $3/$1" | sha512sum --check --status
}

if [ ! -x "$EDITOR" ]; then
  tmp="$(mktemp -d)"
  fetch "Godot_v${RELEASE}_linux.x86_64.zip" "$EDITOR_SHA512" "$tmp"
  mkdir -p "$EDITOR_DIR"
  unzip -q -o "$tmp/Godot_v${RELEASE}_linux.x86_64.zip" -d "$EDITOR_DIR"
  rm -rf "$tmp"
fi
mkdir -p "$BIN_DIR"
ln -sf "$EDITOR" "$BIN_DIR/godot"
ln -sf "$EDITOR" "$BIN_DIR/Summer"

if [ "${1:-}" = "--templates" ] && [ ! -f "$TEMPLATES_DIR/web_nothreads_release.zip" ]; then
  tmp="$(mktemp -d)"
  fetch "Godot_v${RELEASE}_export_templates.tpz" "$TEMPLATES_SHA512" "$tmp"
  # Only the Web templates; the full archive holds every platform.
  unzip -q -o "$tmp/Godot_v${RELEASE}_export_templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$tmp"
  mkdir -p "$TEMPLATES_DIR"
  mv "$tmp"/templates/* "$TEMPLATES_DIR/"
  rm -rf "$tmp"
fi

echo "Godot $("$EDITOR" --version) at $BIN_DIR/godot"
