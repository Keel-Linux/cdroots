#!/usr/bin/env bats
# The Keel boot menu (cdroot gfxboot-keel): the packed bootlogo archive
# holds the files of src/gfxboot-keel-bootlogo, its splash is the Keel
# image and not the TurnKey image, and no file of the cdroot shows TurnKey.

bats_require_minimum_version 1.5.0

setup() {
	repo=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
	archive=$repo/gfxboot-keel/isolinux/bootlogo
	src=$repo/src/gfxboot-keel-bootlogo
	unpacked=$BATS_TEST_TMPDIR/bootlogo
	mkdir -p "$unpacked"
	(cd "$unpacked" && cpio -id --quiet --no-absolute-filenames < "$archive")
}

@test "the bootlogo archive holds the six files of the theme at its top level" {
	run cpio -t --quiet < "$archive"
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | sort | tr '\n' ' ')" = "16x16.fnt en.tr gfxboot.cfg init lang splash.pcx " ]
}

@test "each file of the archive is the same as its source in src/gfxboot-keel-bootlogo" {
	cmp "$unpacked/splash.pcx" "$src/splash.pcx"
	cmp "$unpacked/en.tr" "$src/en.tr"
	cmp "$unpacked/gfxboot.cfg" "$src/gfxboot.cfg"
	cmp "$unpacked/lang" "$src/lang"
	cmp "$unpacked/16x16.fnt" "$src/16x16.fnt"
	# gfxboot --pack-archive stores the theme code, the cpio archive
	# src/gfxboot-keel-bootlogo/bootlogo, as "init" with the code unpacked
	cpio -i --quiet --to-stdout init < "$src/bootlogo" > "$BATS_TEST_TMPDIR/init"
	cmp "$unpacked/init" "$BATS_TEST_TMPDIR/init"
}

@test "the splash is a 640x480 8-bit PCX image, the format of the theme" {
	run file -b "$unpacked/splash.pcx"
	[ "$status" -eq 0 ]
	[[ "$output" == "PCX "* ]]
	[[ "$output" == *"[0, 0] - [639, 479]"* ]]
	[[ "$output" == *"8-bit colour"* ]]
}

@test "the splash is not the TurnKey splash" {
	run cmp -s "$unpacked/splash.pcx" "$repo/src/gfxboot-turnkey-bootlogo/splash.pcx"
	[ "$status" -eq 1 ]
}

@test "no file of the Keel cdroot or of its sources shows TurnKey" {
	run grep -rIil turnkey "$repo/gfxboot-keel" "$src" "$repo/src/keel-splash" "$unpacked"
	[ "$status" -eq 1 ]
	# the binary files too: the theme code and the translations
	run grep -c -a -i turnkey "$unpacked/init" "$unpacked/en.tr"
	[ "$status" -eq 1 ]
}

@test "the boot menu has the three entries and the gfxboot theme" {
	grep -qx 'ui gfxboot bootlogo' "$repo/gfxboot-keel/isolinux/isolinux.cfg"
	run grep -c '^  menu label ' "$repo/gfxboot-keel/isolinux/menu.cfg"
	[ "$output" = 3 ]
}
