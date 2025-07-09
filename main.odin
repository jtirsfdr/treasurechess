package treasurechess

import "core:fmt"
import "core:c"
import rl "vendor:raylib"
import "core:strconv"
import "core:strings"


main :: proc() {
	init_uielems()
//	-- Raylib Init
	rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_RESIZABLE })
	rl.InitWindow(640, 480, "treasure chess")
	rl.InitAudioDevice()
	rl.SetTargetFPS(480)
	font = rl.LoadFont("pixelplay.png")
	winx = rl.GetScreenWidth()
	winy = rl.GetScreenHeight()
	rl.SetWindowOpacity(0.9)
	winxcstr = itocstr(winx)
	winycstr = itocstr(winy)
	mousepos : rl.Vector2
	mousecell : rl.Vector2
//	presses := 0
	active := 0
// 	rl.Rectangle = {x, y, w, h}
//	-- Draw loop
	for !rl.WindowShouldClose() {
		windowrec = {0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
		rl.BeginDrawing()
		rl.ClearBackground(current_palette.windowbg)
		if rl.IsCursorOnScreen(){
			rl.SetWindowOpacity(1.0)
		} else {
			rl.SetWindowOpacity(0.9)
		}
		check_aspect_ratio()
		draw_uies()
		rl.EndDrawing()
		
//		-- Temp input diagnosing
		/*
		pbuf: [32]byte
		pnum := strconv.itoa(pbuf[:], presses)
		s := []string{"Presses ", pnum}
		pressstr := strings.concatenate(s[:])
		rl.DrawTextEx(font, strings.unsafe_string_to_cstring(pressstr), {100, 400}, font_size, 1, rl.WHITE)
		mousepos = rl.GetMousePosition()
		if rl.IsMouseButtonDown(.LEFT) {
			if rl.IsMouseButtonPressed(.LEFT) {
				rl.DrawTextEx(font, "MousePressed", {100, 200}, font_size, 1, rl.WHITE)
				presses += 1
			}
			rl.DrawTextEx(font, "MouseDown", {100, 300}, font_size, 1, rl.WHITE)
		}
		*/

//		free_all(context.temp_allocator)
	}
}
@(fini)
debug :: proc() {
	/*
	for i in ui_elems {
		fmt.print(i.type)
	}
	*/
}
draw_uies :: proc() {
	for i in ui_elems{
		if i.parent == 0 {
			rec := rl.Rectangle{
				0, 0, windowrec.width * i.xratio, windowrec.height * i.yratio
			}
			rl.DrawRectangleRec(rec, current_palette.bg)
			rl.DrawRectangleLinesEx(rec, 1.0, current_palette.border)
		}
	}
}
DrawTextF :: proc() {
	//allow for printf input on drawtext functions + autofont
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
	rl.DrawTextEx(font, winxcstr, {100, 100}, font_size, 1, rl.WHITE)
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
