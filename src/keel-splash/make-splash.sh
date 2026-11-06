#!/bin/sh
# Make splash.pcx, the background of the Keel boot menu, from the Keel mark.
#
# usage: src/keel-splash/make-splash.sh [OUTPUT]
#
# OUTPUT is src/gfxboot-keel-bootlogo/splash.pcx when not given.
#
# The image has the dimensions and the format of the earlier splash.pcx that
# the theme expects: 640x480, PCX, 8-bit colour with a palette, black
# background. The mark and the "KEEL LINUX" wordmark are in the band that
# the earlier logo used (y 50 to 170), above the menu (y 220 and below).
#
# Needs: rsvg-convert (librsvg2-bin), convert (imagemagick) and the
# DejaVu Sans Bold font (fonts-dejavu-core).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/../gfxboot-keel-bootlogo/splash.pcx}
font=${KEEL_SPLASH_FONT:-DejaVu-Sans-Bold}

# The height in pixels of the mark and its top edge.
mark_height=86
mark_top=52
# The top edge of the wordmark.
text_top=146

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# keel-mark-dark.svg is the variant for a dark background: white wings and
# blade, blue waterline.
rsvg-convert -w 848 -h 848 "$here/keel-mark-dark.svg" -o "$tmp/mark-big.png"
convert "$tmp/mark-big.png" -trim +repage -resize "x$mark_height" "$tmp/mark.png"

convert -size 640x480 xc:black \
	"$tmp/mark.png" -gravity north -geometry "+0+$mark_top" -composite \
	-font "$font" -pointsize 20 -kerning 6 -fill white \
	-gravity north -annotate "+0+$text_top" "KEEL LINUX" \
	-alpha off -colors 256 -type Palette -compress RLE "PCX:$out"
