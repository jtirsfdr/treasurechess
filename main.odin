package treasurechess

import rl "vendor:raylib"
import "core:fmt"
import "core:c"
import "core:strings"
import "core:unicode/utf8"
import "core:strconv"


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
		debug_x = 800
		debug_y = 0
		line_break = 30 //px

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		draw_chessboard(BOARD_X, BOARD_Y, BOARD_SCALE)
		draw_pieces_from_board_state()
		get_legal_moves()
		update_state()
		rl.DrawFPS(0,0)
		rl.EndDrawing()
	}
}


update_state :: proc()
{
	mouse_x := rl.GetMouseX()
	mouse_y := rl.GetMouseY()
	mouse_file := clamp(mouse_x / square_size, 0, 7)
	mouse_rank := clamp(abs((mouse_y / square_size) - 7), 0, 7)
	current_piece := &board_state[mouse_rank][mouse_file] 
	draw_debug("mouse rank: ", to_string(mouse_rank))
	draw_debug("mouse_file: ", to_string(mouse_file))
	draw_debug("selected piece:")
	draw_debug(to_string(selected_piece))
	draw_debug("current piece: ", to_string(current_piece^))

	if selected_piece[.PIECE] != i8(Piece.NONE)
	{
		draw_legal_moves_hint()
	}

	if rl.IsMouseButtonReleased(.LEFT) == true
	{ //Check if move is legal
		#partial switch Piece(selected_piece[.PIECE])
		{
		case .NONE:
			break
		case:
			old_rank := selected_piece[.RANK]
			old_file := selected_piece[.FILE]
			new_rank := i8(mouse_rank)
			new_file := i8(mouse_file)
			piece := &selected_piece[.PIECE]

			if legal_moves[new_rank][new_file] == true 
			{
				board_state[new_rank][new_file] = piece^
			}
			else
			{
				board_state[old_rank][old_file] = piece^
			}
			piece^ = i8(Piece.NONE)
		}
	}
	else if rl.IsMouseButtonPressed(.LEFT) == true 
	{ //Select a piece (to grab, holding only for now)
		if mouse_rank <= 7 && mouse_file <= 7
		{
			#partial switch Piece(current_piece^)
			{
			case .NONE:
				break
			case:
				selected_piece[.PIECE] = i8(current_piece^)
				selected_piece[.RANK] = i8(mouse_rank)
				selected_piece[.FILE] = i8(mouse_file)
				current_piece^ = i8(Piece.NONE)
			}
		}
	}
	else if rl.IsMouseButtonDown(.LEFT) == true
	{ //Hold a piece
		#partial switch Piece(selected_piece[.PIECE])
		{
		case .NONE:
			break	
		case:
			texture := get_texture(selected_piece[.PIECE])
			position := rl.Vector2 {
				f32(mouse_x - (50 * i32(scale))), //FIX MAGIC NUM
				f32(mouse_y - (50 * i32(scale))) }
			draw_piece(texture, position)
		}
	}

}

insert_piece_into_board_state :: proc(piece: rune, rank: int, file: int, from_fen: bool)
{
	local_rank := rank 	
	if from_fen == true
	{ //FEN goes from h-a
		local_rank = abs(rank - 7)
	}
	switch piece
	{
	case 'r':
		board_state[local_rank][file] = i8(Piece.BLACK_ROOK)
	case 'n':
		board_state[local_rank][file] = i8(Piece.BLACK_KNIGHT)
	case 'b':
		board_state[local_rank][file] = i8(Piece.BLACK_BISHOP)
	case 'k':
		board_state[local_rank][file] = i8(Piece.BLACK_KING)
	case 'q':
		board_state[local_rank][file] = i8(Piece.BLACK_QUEEN)
	case 'p':
		board_state[local_rank][file] = i8(Piece.BLACK_PAWN)
	case 'R':
		board_state[local_rank][file] = i8(Piece.WHITE_ROOK)
	case 'N':
		board_state[local_rank][file] = i8(Piece.WHITE_KNIGHT)
	case 'B':
		board_state[local_rank][file] = i8(Piece.WHITE_BISHOP)
	case 'K':
		board_state[local_rank][file] = i8(Piece.WHITE_KING)
	case 'Q':
		board_state[local_rank][file] = i8(Piece.WHITE_QUEEN)
	case 'P':
		board_state[local_rank][file] = i8(Piece.WHITE_PAWN)
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
				insert_piece_into_board_state(
					character, rank, file, true)
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
				draw_debug("white to move")
			case 'b':
				draw_debug("black to move")
			case ' ':
				//do some better error handling here
				phase = .CASTLE
			}
		case .CASTLE:
			switch character
			{
			case 'K':
				draw_debug("WHITE SHORT CASTLE")	
			case 'Q':
				draw_debug("WHITE LONG CASTLE")
			case 'k':
				draw_debug("BLACK SHORT CASTLE")
			case 'q':
				draw_debug("BLACK LONG CASTLE")
			case ' ':
				//do some better error handling here
				phase = .EN_PASSANT
			}
		case .EN_PASSANT:
			switch character
			{
			case '-':
				draw_debug("NO EN PASSANT AVAILABLE")
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

get_legal_moves :: proc()
{
	rank := selected_piece[.RANK]
	file := selected_piece[.FILE]
	piece := Piece(selected_piece[.PIECE])
	// Reset
	for rank in 0..<8
	{
		for file in 0..<8
		{
			legal_moves[rank][file] = false
		}
	}

	#partial switch piece
	{
	case .WHITE_PAWN, .BLACK_PAWN: 
		dir: i8
		starting_rank: i8
		if piece == .WHITE_PAWN
		{
			dir = 1
			starting_rank = 1
		}
		else 
		{
			dir = -1
			starting_rank = 6
		}

		if rank == starting_rank
		{
			legal_moves[rank + (1 * dir)][file] = true
			legal_moves[rank + (2 * dir)][file] = true	
		}
		else
		{
			legal_moves[rank + (1 * dir)][file] = true
		}

	case .BLACK_ROOK, .WHITE_ROOK, .BLACK_BISHOP, .WHITE_BISHOP, .WHITE_QUEEN, .BLACK_QUEEN, .WHITE_KING, .BLACK_KING, .BLACK_KNIGHT, .WHITE_KNIGHT:
		for direction in 0..<8
		{
			hit_invalid_square := false
			index := i8(0)
			for hit_invalid_square == false 
			{

				index = index + 1
				new_rank := rank
				new_file := file

				#partial switch piece {
				case .BLACK_ROOK, .WHITE_ROOK:
					switch direction
					{
					case 0:
						new_rank = rank + index
					case 1:
						new_file = file + index
					case 2:
						new_rank = rank - index
					case 3:
						new_file = file - index
					case 4:
						return
					}

				case .BLACK_BISHOP, .WHITE_BISHOP:
					switch direction
					{
					case 0:
						new_rank = rank + index
						new_file = file + index
					case 1:
						new_rank = rank - index
						new_file = file + index
					case 2:
						new_rank = rank + index
						new_file = file - index
					case 3:
						new_rank = rank - index
						new_file = file - index
					case 4:
						return
					}

				case .WHITE_QUEEN, .BLACK_QUEEN, .WHITE_KING, .BLACK_KING:
					switch direction
					{
					case 0:
						new_rank = rank + index
					case 1:
						new_rank = rank + index
						new_file = file + index
					case 2:
						new_file = file + index
					case 3:
						new_rank = rank - index
						new_file = file + index
					case 4:
						new_rank = rank - index
					case 5:
						new_rank = rank - index
						new_file = file - index
					case 6:
						new_file = file - index
					case 7:
						new_rank = rank + index
						new_file = file - index
					}
				case .WHITE_KNIGHT, .BLACK_KNIGHT:
					switch direction
					{
					case 0:
						new_rank = rank + 2
						new_file = file + 1
					case 1:
						new_rank = rank + 1
						new_file = file + 2
					case 2:
						new_rank = rank - 1
						new_file = file + 2
					case 3:
						new_rank = rank - 2
						new_file = file + 1
					case 4:
						new_rank = rank - 2
						new_file = file - 1
					case 5:
						new_rank = rank - 1
						new_file = file - 2
					case 6:
						new_rank = rank + 1
						new_file = file - 2
					case 7:
						new_rank = rank + 2
						new_file = file - 1
					}
				}

				if new_rank >= 0  &&
					new_rank <= 7 &&
					new_file >= 0 &&
					new_file <= 7 &&
					board_state[new_rank][new_file] == i8(Piece.NONE) 
				{
 					#partial switch piece
					{
					case .WHITE_KING, .BLACK_KING, .WHITE_KNIGHT, .BLACK_KNIGHT:
						//only check once per direction
						legal_moves[new_rank][new_file] = true
						hit_invalid_square = true 
					case:
						legal_moves[new_rank][new_file] = true

					}
				} 
				else 
				{
					hit_invalid_square = true
				}

			}
		}
	}
}


get_texture :: proc(piece: i8) -> rl.Texture 
{
	blank_texture: rl.Texture
 	#partial switch Piece(piece)
	{
	case .NONE:
		return blank_texture
	case .BLACK_PAWN:
		return black_pawn_texture
	case .BLACK_ROOK:
		return black_rook_texture
	case .BLACK_KNIGHT:
		return black_knight_texture
	case .BLACK_BISHOP:
		return black_bishop_texture
	case .BLACK_QUEEN:
		return black_queen_texture
	case .BLACK_KING:
		return black_king_texture
	case .WHITE_PAWN:
		return white_pawn_texture
	case .WHITE_ROOK:
		return white_rook_texture
	case .WHITE_KNIGHT:
		return white_knight_texture
	case .WHITE_BISHOP:
		return white_bishop_texture
	case .WHITE_QUEEN:
		return white_queen_texture
	case .WHITE_KING:
		return white_king_texture
	}
	return blank_texture //should never be called
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
	gray_dot_image := rl.LoadImage("./assets/pieces/gray_dot.png")

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
	gray_dot_texture = rl.LoadTextureFromImage(gray_dot_image)
}

to_string :: proc(v: any) -> string
{
	str := fmt.tprint(v)
	return str
}

draw_debug :: proc(str: ..string)
{
	joined_str := strings.join(str, "")
	joined_cstr := strings.clone_to_cstring(joined_str)
	rl.DrawText(joined_cstr, debug_x, debug_y, i32(FONT_SIZE * scale), rl.BLACK)
	debug_y = debug_y + line_break
}

draw_piece :: proc(texture: rl.Texture2D, position: rl.Vector2)
{
	rotation := 0.0
	rl.DrawTextureEx(texture,
			position,
			f32(rotation),
			f32(scale),
			DEFAULT_TINT)
}

draw_pieces_from_board_state :: proc() 
{
	piece_size := 100 //px (TODO: DONT HARDCODE)
	for rank in 0..<8 
	{
		for file in 0..<8
		{
		// centers the piece independent of scale (0x0 is normally topleft corner)
		x := (i32(file) * square_size) + (square_size / 2) - i32(f64(piece_size) * f64(scale)) / 2
		y := (i32(abs(rank-7)) * square_size) + (square_size / 2) - i32(f64(piece_size) * f64(scale)) / 2
		position := rl.Vector2 { f32(x), f32(y) }
		texture := get_texture(board_state[rank][file])
		draw_piece(texture, position)
		}
	}
}
draw_legal_moves_hint :: proc()
{
	rotation := f32(0.0)
	for rank in 0..<8
	{
		for file in 0..<8
		{
			if legal_moves[rank][file] == true
			{
				//magic num is to center gray dot (replace eventually)
				x := square_size * i32(file) - 60
				y := board_size - (square_size * i32(rank) + 140)
				position := rl.Vector2 { f32(x), f32(y) }

				rl.DrawTextureEx(
					gray_dot_texture,
					position,
					rotation,
					f32(scale),
					DEFAULT_TINT)
			}
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


