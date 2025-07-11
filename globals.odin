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
	TOP = LEFT, //not necessary
	BOTTOM = RIGHT,
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
	xtxtalign: Align,
	ytxtalign: Align,
	mask: f32, //does nothing
	font_size: f32,
	innerpadding: f32, //does nothing
	outerpadding: f32, //does nothing
	xfixed: f32, 
	xmax: f32,
	xmin: f32,
	xratio: f32, 
	xalign: Align,
	xorder: f32, //does nothing
	yfixed: f32,
	ymax: f32,
	ymin: f32,
	yratio: f32,
	yalign: Align,
	yorder: f32, //does nothing
	resizable: bool, //does nothing
	visible: bool, //does nothing
	draggable: bool, //does nothing
	clickable: bool, //does nothing
	dimensions: rl.Rectangle,
	text: string,
}
Palette :: struct {
	windowbg: rl.Color,
	bg: rl.Color,
	bg_selected: rl.Color,
	border: rl.Color,
	text_color: rl.Color,
}

winx: i32
winy: i32
winxcstr: cstring
winycstr: cstring
default_font_size := f32(17*2)
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
		bg_selected = rl.Color{80, 80, 80, 255},
		border = rl.Color{180, 180, 180, 255},
		text_color = rl.Color{255, 255, 255, 255},
	}
	ui_elems[.WINDOW] = {
		type = .WINDOW,
	}
	ui_elems[.TITLE_BOX] = {
		type = .BOX,
		parent = .WINDOW,
		xratio = 0.1,
		xalign = .CENTER,
		yalign = .TOP,
		ytxtalign = .CENTER,
		xtxtalign = .CENTER,
		clickable = true,
		yratio = 0.03,
		text = "Treasure Chess",
	}
	ui_elems[.TITLE_MENU] = {
		type = .BOX,
		parent = .TITLE_BOX,
	}
	for uie, i in ui_elems {
		//configuring defaults
		if uie.ymax == 0 {
			ui_elems[i].ymax = 65000
		}
		if uie.xmax == 0 {
			ui_elems[i].xmax = 65000
		}
		if uie.font_size == 0 {
			ui_elems[i].font_size = default_font_size
		}
		ui_elems[i].id = Elements(i)
	}
	init_uie_siblings()
	current_palette = palettes[.DARK]
}
 
