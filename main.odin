package treasurechess

import "core:fmt"
import "core:c"
import rl "vendor:raylib"
import "core:strconv"
import "core:strings"


main :: proc() {
//	-- Raylib Init
	rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_RESIZABLE })
	rl.InitWindow(640, 480, "treasure chess")
	rl.InitAudioDevice()
	rl.SetTargetFPS(480)
	font = rl.LoadFont("pixelplay.png")
	init_uielems()
//	-- Draw loop
	for !rl.WindowShouldClose() {
		//get window x y width height
		ui_elems[.WINDOW].dimensions = rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
		rl.BeginDrawing()
		rl.ClearBackground(current_palette.windowbg)
		change_opacity()
		check_aspect_ratio()
		draw_uies()
		rl.DrawFPS(0,0)
		rl.EndDrawing()
		}
}
draw_uies :: proc() {
	/*
	TODO
	Account for siblings in calculation
	Logic for rest of parameters
	Text alignment
	Fix struct types
	Pass strings through to render queue
	Padding

	*/
	for uie, i in ui_elems{
		#partial switch uie.type {
		case .WINDOW:
		case .BOX:
//			-- Calculate box xywh
			parent := ui_elems[uie.parent].dimensions
			rec := rl.Rectangle{}
			if uie.xfixed == 0 {
				rec.width = clamp(parent.width * uie.xratio, uie.xmin, uie.xmax)
			} else {
				rec.width = uie.xfixed
			}
			if uie.yfixed == 0 {
				rec.height = clamp(parent.height * uie.yratio, uie.ymin, uie.ymax)
			} else {
				rec.height = uie.yfixed
			}
			switch uie.xalign {
			case .LEFT:
				rec.x = parent.x
			case .CENTER:
				rec.x = parent.x + (parent.width - parent.width * uie.xratio)/2
			case .RIGHT:
				rec.x = parent.x + (parent.width - parent.width * uie.xratio)	
			}
			switch uie.yalign {
			case .TOP:
				rec.y = parent.y
			case .CENTER:
				rec.y = parent.y + (parent.height - parent.height * uie.yratio)/2
			case .BOTTOM:
				rec.y = parent.y + (parent.height - parent.height * uie.yratio)
			}
//			-- Calculate text xywh
			ctext := strings.unsafe_string_to_cstring(uie.text)
			text_size := rl.MeasureTextEx(font, ctext, uie.font_size, 1)
			text_size.y = default_font_size * 0.8 //y size from MeasureTextEx is wrong (maybe?)
			txt: rl.Vector2
			switch uie.ytxtalign {
			case .TOP:
				txt.y = rec.y 
			case .CENTER:
				txt.y = rec.y + (rec.height - (text_size.y))/2
			case .BOTTOM:
				txt.y = rec.y + (rec.height - (text_size.y))
			}
			switch uie.xtxtalign {
			case .TOP:
				txt.x = rec.x 
			case .CENTER:
				txt.x = rec.x + (rec.width - (text_size.x))/2
			case .BOTTOM:
				txt.x = rec.x + (rec.width - (text_size.x))
			}
//			-- Draw
			rl.DrawRectangleRec(rec, current_palette.bg)
			rl.DrawTextEx(font, ctext, {txt.x, txt.y}, uie.font_size, 1, current_palette.text_color)
			rl.DrawRectangleLinesEx(rec, 1.0, current_palette.border)
			ui_elems[i].dimensions = rec
		}
	}
}

init_uie_siblings :: proc() {
	siblings_of_parents = make([][dynamic]Elements, len(Elements))
	for ui, i in ui_elems{
		append(&siblings_of_parents[ui.parent], Elements(i))
	}
	for ui, i in ui_elems {
		ui_elems[i].siblings = siblings_of_parents[ui.parent]
	}
}

update_uie_siblings :: proc() {
	for i in 0..<len(siblings_of_parents) {
		clear(&siblings_of_parents[i])
	}
	for ui, i in ui_elems{
		append(&siblings_of_parents[ui.parent], Elements(i))
		}
	for ui, i in ui_elems {
		ui_elems[i].siblings = siblings_of_parents[ui.parent]
	}
}

change_opacity :: proc() {
	if rl.IsCursorOnScreen(){
		rl.SetWindowOpacity(1.0)
	} else {
		rl.SetWindowOpacity(0.9)
	}
}

check_aspect_ratio :: proc() {
	if rl.IsWindowResized() {
		winx = rl.GetScreenWidth()
		winy = rl.GetScreenHeight()
		winxcstr = itocstr(winx)
		winycstr = itocstr(winy)
	}
	if f32(winx) > f32(winy)/1.1 {
		rl.DrawText("hor", winx-50, winy-50, 16, rl.WHITE)
	} else {
		rl.DrawText("ver", winx-50, winy-50, 16, rl.WHITE)
	}
	rl.DrawTextEx(font, winxcstr, {100, 100}, default_font_size, 1, rl.WHITE)
}

draw_text :: proc() {
	//allow for printf input on drawtext functions + autofont
}

@(fini)
debug :: proc() {
	fmt.println("---")
	for ui, i in ui_elems{
		fmt.println(ui_elems[i])
		fmt.println("---")
	}
	fmt.println(ui_elems[.WINDOW].dimensions)
	fmt.println(ui_elems[.WINDOW].xmax)

}
/*
IMPLEMENT
Color Palettes

PSEUDO
get mouse pos + click
if mouse_down:
	if mouse_pressed:
		get uie at mousepos & mask
			active()
			held()
	else:
		get active uie
			held()
else:
	get active uie
		if !null:
			released()
			normal() (?)
	get all uies @ mousepos
	get lowest mask uie
		hovered()
for i in uie:
	draw(uie)
-=-=-

id x y w h state (normal, hovered, held, active)

Uie :: struct {
	id: int,
	parent: int,
	text_align: int,
	mask: int,
	alpha: int,
	font_size: int,
	innerpadding: int,
	outerpadding: int,
	xratio: int = 0,
	xalign: int,
	xorder: int,
	yratio: int,
	yalign: int,
	yorder: int,
	resizable: int,
	bg: Color,
	border: Color,
	text_color: Color,
	text: string,
	normal: proc(...) -> ...
	hovered: proc(..) -> ...
	held: proc
	active: proc
}

flags
{
type (for categorizing normal, hovered, held, and active procedures during draw calls)
id (to identify parents, 0 = discard, 1=window)
parent 
text (printf format)
text_align (012 left center right)
mask (0 = on top)
alpha (0-256, 0 = skip draw)
resizable (1 = three diagonal marks on bottom right)
bg (color)
border (color)
text (color)
font 
font_size 
innerpadding
outerpadding
xratio
xalign
xorder
yratio (0 = fill amongst siblings, percentage of parent container space taken up)
yalign (012 left center right)
yorder (order to place element relative to siblings 0 = topmost + ignore, 1 = topmost)
state function pointers (what to execute when normal, hovered, held, and active)
}

Functionality
Hover
Click
Type
Resize
Expand outside window (impossible with unpatched raylib :))

EXAMPLE
horizontal
title container
100% h (0)
10% v (1)
body container
100% h (0)
90% v (2)
- sidebar
30% h (1)
100% v (0)
- content
70% h (2)
100% v (0)
-- chess board container
70% h (1)
fill v (0)
expandable
--- chess board
100% h (0)
fill v (1)
--- input 
80% h (0)
10% v (2)
-- engine stats
30% h (2)
fill v (0)
expandable

0 = ignore draw order
1..9 = draw order
*/
itocstr :: proc (i: i32) -> cstring {
	buf: [32]byte
	istr := strconv.itoa(buf[:], int(i))
	return strings.clone_to_cstring(istr)
}
