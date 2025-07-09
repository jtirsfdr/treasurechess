package treasurechess

import rl "vendor:raylib"

Type :: enum {
	WINDOW,
	CONTAINER,
	BOX,
}

Elements :: enum {
	WINDOW,
	TITLEBOX
}
ColorPalettes :: enum {
	DARK
}
Uie :: struct {
	type: Type,
	id: f32, //may not be necessary
	parent: Elements,
	text_align: f32,
	mask: f32,
	font_size: f32,
	innerpadding: f32,
	outerpadding: f32,
	xfixed: f32, //0 = not fixed
	xmax: f32,
	xmin: f32,
	xratio: f32,
	xalign: f32,
	xorder: f32,
	ymax: f32,
	ymin: f32,
	yratio: f32,
	yalign: f32,
	yorder: f32,
	yfixed: f32,
	resizable: bool,
	visible: bool,
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
default_font_size := f32(33)
font: rl.Font
ui_elems: [len(Elements)]Uie
palettes: [len(ColorPalettes)]Palette
current_palette: Palette
mousepos: rl.Vector2
active: Elements //last clicked uie
init_uielems :: proc() {
	palettes[ColorPalettes.DARK] = {
		windowbg = rl.Color{50, 50, 50, 255},
		bg = rl.Color{100, 100, 100, 255},
		border = rl.Color{180, 180, 180, 255},
		text_color = rl.Color{255, 255, 255, 255},
	}
	ui_elems[Elements.WINDOW] = {
		type = Type.WINDOW,
//		dimensions: rl.Rectangle{0, 0, rl.GetScreenWidth(), rl.GetScreenHeight()},
	}
	ui_elems[Elements.TITLEBOX] = {
		type = Type.BOX,
		parent = Elements.WINDOW,
		xratio = 0.9,
		xalign = 1,
		yratio = 0.05,
		text = "Treasure Chess",
		font_size = default_font_size,
	}
	current_palette = palettes[ColorPalettes.DARK]
}
 
