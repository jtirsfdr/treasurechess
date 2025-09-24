package treasurechess

import rl "vendor:raylib"
import "core:fmt"
import "core:c"
import "core:strings"
import "core:unicode/utf8"
import "core:strconv"

BOARD_X :: 0
BOARD_Y :: 0
BOARD_SCALE :: 0.9
RES_X :: 640
RES_Y :: 480
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
grabbed_piece: int
board_state: [8][8]Piece

debug_x: i32
debug_y: i32
line_break: i32

//board_properties: []Properties (move, castle, etc)
main :: proc() 
{
	piece_set := "wikipieces"
	rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_RESIZABLE })
	rl.InitWindow(RES_X, RES_Y, TITLE)
	rl.InitAudioDevice()
	rl.SetTargetFPS(MAX_FPS)
	font = rl.LoadFont(FONT)
	init_piece_textures(piece_set)
	fen := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
	init_board_state_from_fen(fen)
//	-- Draw loop
	for !rl.WindowShouldClose() 
	{
		//Reset debug string positions
		debug_x = 1250
		debug_y = 0
		line_break = 30

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		draw_chessboard(BOARD_X, BOARD_Y, BOARD_SCALE)
		draw_pieces_board_state()
		update_mouse()
		rl.DrawFPS(0,0)
		rl.EndDrawing()
	}
}


update_mouse :: proc()
{
	// Get piece selection + mouse status
	mouse_x := rl.GetMouseX()
	mouse_y := rl.GetMouseY()
	mouse_file := mouse_x / square_size
	mouse_rank := abs((mouse_y / square_size) - 7)
	mouse_file_cstring := int_to_cstring(int(mouse_file))
	mouse_rank_cstring := int_to_cstring(int(mouse_rank))
	defer delete(mouse_file_cstring)
	defer delete(mouse_rank_cstring)
	rl.DrawText(mouse_rank_cstring, 1250, 800, i32(FONT_SIZE * scale), rl.BLACK)
	rl.DrawText(mouse_file_cstring, 1250, 830, i32(FONT_SIZE * scale), rl.BLACK)
	if rl.IsMouseButtonDown(.LEFT) == true
	{
		//check if grabbed
		//yes : continue
		//no : check if valid drop
			//yes : drop
			//no : return to original spot
	}
	if rl.IsMouseButtonDown(.LEFT) == true 
	{
		if mouse_rank <= 7 && mouse_file <= 7
		{
			current_piece_string := fmt.tprint(board_state[mouse_rank][mouse_file])
			current_piece_cstring := strings.unsafe_string_to_cstring(current_piece_string)
			rl.DrawText(current_piece_cstring, 1250, 890, i32(FONT_SIZE * scale), rl.BLACK)
			rl.DrawText("yipee", 1250, 860, i32(FONT_SIZE * scale), rl.BLACK)
		}
		//check if piece
		//yes : grab
		//no : ignore
	}
}
insert_piece_into_board_state :: proc(piece: rune, rank: int, file: int, from_fen: bool)
{
	//can't assign to procedure parameters
	local_rank := rank 	
	if from_fen == true
	{ //FEN goes from h-a
		local_rank = abs(rank - 7)
	}
	switch piece
	{
	case 'r':
		board_state[local_rank][file] = .BLACK_ROOK
	case 'n':
		board_state[local_rank][file] = .BLACK_KNIGHT
	case 'b':
		board_state[local_rank][file] = .BLACK_BISHOP
	case 'k':
		board_state[local_rank][file] = .BLACK_KING
	case 'q':
		board_state[local_rank][file] = .BLACK_QUEEN
	case 'p':
		board_state[local_rank][file] = .BLACK_PAWN
	case 'R':
		board_state[local_rank][file] = .WHITE_ROOK
	case 'N':
		board_state[local_rank][file] = .WHITE_KNIGHT
	case 'B':
		board_state[local_rank][file] = .WHITE_BISHOP
	case 'K':
		board_state[local_rank][file] = .WHITE_KING
	case 'Q':
		board_state[local_rank][file] = .WHITE_QUEEN
	case 'P':
		board_state[local_rank][file] = .WHITE_PAWN
	}
}

init_board_state_from_fen :: proc(fen:string)
{
	rank, file := 0, 0
	phase: FenPhase
	character: []rune
	for character in fen 
	{
		switch phase
		{
		case .PLACEMENT:
			switch character 
			{
			case 'r', 'n', 'b', 'q', 'k', 'p', 
			     'R', 'N', 'B', 'Q', 'K', 'P':
				insert_piece_into_board_state(character, rank, file, true)
				file = file + 1
			case '/':
				rank = rank + 1
				file = 0
			case ' ':
				if rank >= 7 
				{
					phase = .ACTIVE_COLOR
				} else { 
					fmt.println("INVALID FEN (SPACE BEFORE ALL PIECES PLACED")
				}
			}
		case .ACTIVE_COLOR:
			switch character
			{
			case 'w':
				rl.DrawText("white to move", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case 'b':
				rl.DrawText("black to move", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case ' ':
				//do some better error handling here
				phase = .CASTLE
			}
		case .CASTLE:
			switch character
			{
			case 'K':
				rl.DrawText("WHITE SHORT CASTLE", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break

			case 'Q':
				rl.DrawText("WHITE LONG CASTLE", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case 'k':
				rl.DrawText("BLACK SHORT CASTLE", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case 'q':
				rl.DrawText("BLACK LONG CASTLE", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case ' ':
				//do some better error handling here
				phase = .EN_PASSANT
			}
		case .EN_PASSANT:
			switch character
			{
			case '-':
				rl.DrawText("NO EN PASSANT AVAILABLE", debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
				debug_y = debug_y + line_break
			case ' ':
				//ditto
				phase = .HALF_MOVES
			}
		case .HALF_MOVES:
			switch character
			{ //implement converting multiple runes into 1 number
			case ' ':
				phase = .FULL_MOVES
			}
		case .FULL_MOVES:
			//ditto
		}
		
	}

}

draw_pieces_board_state :: proc() 
{
	piece_size := 100 //px (TODO: DONT HARDCODE)
	piece_scale := 1.5
	texture: rl.Texture2D
	rotation := 0.0

	for rank in 0..<8 
	{
		for file in 0..<8
		{
		// centers the piece independent on scale (0x0 is normally topleft corner)
		x := (i32(file) * square_size) + (square_size / 2) - i32(f64(piece_size) * f64(piece_scale)) / 2
		y := (i32(abs(rank-7)) * square_size) + (square_size / 2) - i32(f64(piece_size) * f64(piece_scale)) / 2
		position := rl.Vector2 { f32(x), f32(y) }
			switch board_state[rank][file]
			{
			case .NONE:
				continue
			case .BLACK_PAWN:
				texture = black_pawn_texture
			case .BLACK_ROOK:
				texture = black_rook_texture
			case .BLACK_KNIGHT:
				texture = black_knight_texture
			case .BLACK_BISHOP:
				texture = black_bishop_texture
			case .BLACK_QUEEN:
				texture = black_queen_texture
			case .BLACK_KING:
				texture = black_king_texture
			case .WHITE_PAWN:
				texture = white_pawn_texture
			case .WHITE_ROOK:
				texture = white_rook_texture
			case .WHITE_KNIGHT:
				texture = white_knight_texture
			case .WHITE_BISHOP:
				texture = white_bishop_texture
			case .WHITE_QUEEN:
				texture = white_queen_texture
			case .WHITE_KING:
				texture = white_king_texture
			}
		rl.DrawTextureEx(
			texture,
			position,
			f32(rotation),
			f32(piece_scale),
			DEFAULT_TINT)
		}
	}
}

draw_chessboard :: proc(x, y: i32, scale: f32) 
{
	square_color: rl.Color
	white_square_color := rl.Color { 225, 225, 225, 255 }
	black_square_color := rl.Color { 128, 128, 128, 255 }
	board_width := i32(f32(rl.GetScreenWidth()) * scale)
	board_height := i32(f32(rl.GetScreenHeight()) * scale)

	if board_width < board_height 
	{
		board_size = board_width
	} else 
	{
		board_size = board_height
	}
	
	board_size = board_size - (board_size % 8) //make sure there's no gaps  
	square_size = board_size/8
	for rank in 0..<8 
	{
		for file in 0..<8 
		{
			//if rank + file is even, square is black
			if (rank + file) % 2 > 0 { 
				square_color = black_square_color
			} 
			else 
			{
				square_color = white_square_color
			}
			rl.DrawRectangle(
				x + square_size * i32(file),
				y + square_size * i32(rank),
				square_size, square_size,
				square_color)
		}
	}
}

init_piece_textures :: proc(piece_set: string) 
{
	path := "./assets/pieces/"
	//Use path + piece set to load (TODO)
	white_pawn_image := rl.LoadImage("./assets/pieces/white_pawn.png")
	white_knight_image := rl.LoadImage("./assets/pieces/white_knight.png")
	white_bishop_image := rl.LoadImage("./assets/pieces/white_bishop.png")
	white_king_image := rl.LoadImage("./assets/pieces/white_king.png")
	white_queen_image := rl.LoadImage("./assets/pieces/white_queen.png")
	white_rook_image := rl.LoadImage("./assets/pieces/white_rook.png")
	black_pawn_image := rl.LoadImage("./assets/pieces/black_pawn.png")
	black_knight_image := rl.LoadImage("./assets/pieces/black_knight.png")
	black_bishop_image := rl.LoadImage("./assets/pieces/black_bishop.png")
	black_king_image := rl.LoadImage("./assets/pieces/black_king.png")
	black_queen_image := rl.LoadImage("./assets/pieces/black_queen.png")
	black_rook_image := rl.LoadImage("./assets/pieces/black_rook.png")

	white_pawn_texture = rl.LoadTextureFromImage(white_pawn_image)
	white_knight_texture = rl.LoadTextureFromImage(white_knight_image)
	white_bishop_texture = rl.LoadTextureFromImage(white_bishop_image)
	white_king_texture = rl.LoadTextureFromImage(white_king_image)
	white_queen_texture = rl.LoadTextureFromImage(white_queen_image)
	white_rook_texture = rl.LoadTextureFromImage(white_rook_image)
	black_pawn_texture = rl.LoadTextureFromImage(black_pawn_image)
	black_knight_texture = rl.LoadTextureFromImage(black_knight_image)
	black_bishop_texture = rl.LoadTextureFromImage(black_bishop_image)
	black_king_texture = rl.LoadTextureFromImage(black_king_image)
	black_queen_texture = rl.LoadTextureFromImage(black_queen_image)
	black_rook_texture = rl.LoadTextureFromImage(black_rook_image)
}
int_to_cstring :: proc(i: int) -> cstring
{
	// allocates in heap (i think?)
	buffer: [8]byte
	int_string := strconv.itoa(buffer[:], i)
	return strings.clone_to_cstring(int_string)
}
