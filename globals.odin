package treasurechess

import rl "vendor:raylib"

Type :: enum {
	CONTAINER,
	BOX
}

Elements :: enum {
	TITLEBOX
}
ColorPalettes :: enum {
	DARK
}
Uie :: struct {
	type: int,
	id: int, //may not be necessary
	parent: int,
	text_align: int,
	mask: int,
	alpha: int, //also may not be necessary / hard to implement :(
	font_size: int,
	innerpadding: int,
	outerpadding: int,
	xratio: f32,
	xalign: int,
	xorder: int,
	yratio: f32,
	yalign: int,
	yorder: int,
	resizable: int,
	dimensions: rl.Rectangle,
	text: string,
}
Palette :: struct {
	windowbg: rl.Color,
	bg: rl.Color,
	border: rl.Color,
	text_color: rl.Color,
}

winx: i32
winy: i32
winxcstr: cstring
winycstr: cstring
font_size := f32(33)
font: rl.Font
ui_elems: [len(Elements)]Uie
palettes: [len(ColorPalettes)]Palette
current_palette: Palette
windowrec: rl.Rectangle
init_uielems :: proc() {
	palettes[ColorPalettes.DARK] = {
		windowbg = rl.Color{50, 50, 50, 255},
		bg = rl.Color{100, 100, 100, 255},
		border = rl.Color{180, 180, 180, 255},
		text_color = rl.Color{255, 255, 255, 255},
	}
	ui_elems[Elements.TITLEBOX] = {
		type = int(Type.BOX),
		xratio = 0.9,
		yratio = 0.10,
	}
	current_palette = palettes[ColorPalettes.DARK]
}
 
