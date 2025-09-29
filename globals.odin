package treasurechess

import rl "vendor:raylib"

BOARD_X :: 0
BOARD_Y :: 0
BOARD_SCALE :: 0.9
RES_X :: 1280
RES_Y :: 720
TITLE :: "Treasure Chess"
MAX_FPS :: 480
FONT :: "pixelplay.png"
FONT_SIZE :: 22
DEFAULT_TINT :: 255

FenPhase :: enum 
{
	PLACEMENT,
	ACTIVE_COLOR,
	CASTLE,
	EN_PASSANT,
	HALF_MOVES,
	FULL_MOVES,
}
Piece :: enum u8
{
	NONE,
	WHITE_ROOK,
	WHITE_KNIGHT,
	WHITE_BISHOP,
	WHITE_QUEEN,
	WHITE_KING,
	WHITE_PAWN,
	BLACK_ROOK,
	BLACK_KNIGHT,
	BLACK_BISHOP,
	BLACK_QUEEN,
	BLACK_KING,
	BLACK_PAWN,
}
SelectedPieceLabel :: enum u8
{
	PIECE,
	RANK,
	FILE,
}

white_pawn_texture: rl.Texture
white_knight_texture: rl.Texture
white_bishop_texture: rl.Texture
white_king_texture: rl.Texture
white_queen_texture: rl.Texture
white_rook_texture: rl.Texture
black_pawn_texture: rl.Texture
black_knight_texture: rl.Texture
black_bishop_texture: rl.Texture
black_king_texture: rl.Texture
black_queen_texture: rl.Texture
black_rook_texture: rl.Texture

board_size: i32
square_size: i32	
scale := 1.5 //dpi scaling
selected_piece: [SelectedPieceLabel]u8
board_state: [8][8]u8

debug_x: i32
debug_y: i32
line_break: i32


/* 
 OLD GUI GLOBALS -- KEPT JUST IN CASE
 */

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
	DARK,
	LIGHT,
}
Uie :: struct {
	id: Elements,
	type: Type,
	parent: Elements,
//      siblings: [dynamic]Elements, //Make a pointer
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
palette: [ColorPalettes]Palette
current_palette: Palette
mousepos: rl.Vector2
active_uie: Elements 
siblings_of_parents: [][dynamic]Elements
init_uielems :: proc() {
	palette[.DARK] = {
		windowbg = rl.Color{50, 50, 50, 255},
		bg = rl.Color{100, 100, 100, 255},
		bg_selected = rl.Color{80, 80, 80, 255},
		border = rl.Color{180, 180, 180, 255},
		text_color = rl.Color{255, 255, 255, 255},
	}
	palette[.LIGHT] = {
		windowbg = rl.Color{255, 255, 255, 255},
		bg = rl.Color{200, 200, 200, 255},
		bg_selected = rl.Color{80, 80, 80, 255},
		border = rl.Color{50, 50, 50, 255},
		text_color = rl.Color{0, 0, 0, 255},
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
	current_palette = palette[.LIGHT]
}
 
