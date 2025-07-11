package treasurechess

import rl "vendor:raylib"

Type :: enum {
	WINDOW,
	CONTAINER,
	BOX,
}

Align :: enum {
	LEFT,
	CENTER,
	RIGHT,
}

Elements :: enum {
	WINDOW,
	TITLE_BOX,
	TITLE_MENU,
	BODY,
}

ColorPalettes :: enum {
	DARK
}
Uie :: struct {
	id: Elements,
	type: Type,
	parent: Elements,
	siblings: [dynamic]Elements,
	text_align: f32,
	mask: f32,
	font_size: f32,
	innerpadding: f32,
	outerpadding: f32,
	xfixed: f32, //0 = not fixed
	xmax: f32,
	xmin: f32,
	xratio: f32,
	xalign: Align,
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
ui_elems: [Elements]Uie
palettes: [ColorPalettes]Palette
current_palette: Palette
mousepos: rl.Vector2
active_uie: Elements 
siblings_of_parents: [][dynamic]Elements
init_uielems :: proc() {
	palettes[.DARK] = {
		windowbg = rl.Color{50, 50, 50, 255},
		bg = rl.Color{100, 100, 100, 255},
		border = rl.Color{180, 180, 180, 255},
		text_color = rl.Color{255, 255, 255, 255},
	}
	ui_elems[.WINDOW] = {
		type = .WINDOW,
		dimensions = rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
	}
	ui_elems[.TITLE_BOX] = {
		type = .BOX,
		parent = .WINDOW,
		xratio = 0.9,
		xalign = .CENTER,
		yratio = 0.05,
		text = "Treasure Chess",
		font_size = default_font_size,
	}
	ui_elems[.TITLE_MENU] = {
		type = .BOX,
		parent = .TITLE_BOX,
	}
	for ui, i in ui_elems {
		//for printfs
		ui_elems[i].id = Elements(i)
	}
	init_uie_siblings()
	current_palette = palettes[.DARK]
}
 
