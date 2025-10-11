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
		update_state()
		rl.DrawFPS(0,0)
		rl.EndDrawing()
	}
}


update_state :: proc()
{
	// BUGS
	// !! SELECTING A PIECE ALLOWS DISCOVERED CHECKS EVEN IF PIECE DIDN'T MOVE YET
	// !! RESTRICT MOVES WHEN IN CHECK
	// !! DISABLE CHECK WHEN NOT IN CHECK
	// TODO
	// !! SETUP CHECKMATE
	// !! SETUP PGN HISTORY
	// !! SETUP PUZZLES
	// !! SETUP ONLINE
	// !! SETUP GAME ANALYSIS
	// !! SETUP NICE GUI

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
	draw_debug("turn: ", to_string(turn))
	draw_debug("white check: ", to_string(white_checked))
	draw_debug("black check: ", to_string(black_checked))
	
	draw_checks()

	if selected_piece[.PIECE] != i8(Piece.NONE)
	{
		draw_legal_moves_hint()
	}

	if rl.IsMouseButtonReleased(.LEFT) == true
	{ 
		check_if_requested_move_legal(mouse_rank, mouse_file)
	}

	if rl.IsMouseButtonPressed(.LEFT) == true 
	{
		check_if_selection_legal(mouse_rank, mouse_file)
		set_legal_moves()
	}

	if rl.IsMouseButtonDown(.LEFT) == true
	{ 
		hold_piece(mouse_x, mouse_y)		
	}
}

draw_checks :: proc()
{
	check_red := rl.Color { 255, 0, 0, 120 }
	if white_checked == true
	{
		rank := i32(white_king_piece[.RANK])
		file := i32(white_king_piece[.FILE])
		rl.DrawRectangle(square_size * file,
			square_size * abs(rank-7),
			square_size, square_size,
			check_red)
	}
	if black_checked == true
	{
		rank := i32(black_king_piece[.RANK])
		file := i32(black_king_piece[.FILE])
		rl.DrawRectangle(square_size * file,
			square_size * abs(rank-7),
			square_size, square_size,
			check_red)
	}


}

hold_piece :: proc(mouse_x: i32, mouse_y: i32)
{
	#partial switch Piece(selected_piece[.PIECE])
	{
	case .NONE:
	case:
		texture := get_texture(selected_piece[.PIECE])
		position := rl.Vector2 {
			f32(mouse_x - (50 * i32(scale))), //FIX MAGIC NUM
			f32(mouse_y - (50 * i32(scale))) }
		draw_piece(texture, position)
	}
}

check_if_requested_move_legal :: proc(mouse_rank: i32, mouse_file: i32)
{
	piece := &selected_piece[.PIECE]
	old_rank := selected_piece[.RANK]
	old_file := selected_piece[.FILE]
	new_rank := i8(mouse_rank)
	new_file := i8(mouse_file)

	if legal_moves[new_rank][new_file] == true 
	{

		// Take opponent's piece if en passant
		if piece^ == i8(Piece.WHITE_PAWN) || piece^ == i8(Piece.BLACK_PAWN)
		{
			if legal_moves[new_rank][new_file] == en_passant[new_rank][new_file]
			{
				board_state[new_rank + (1 * i8(-turn))][new_file] = i8(Piece.NONE)
			}
		}
		

		//Reset en passant
		for rank in 0..<8
		{
			for file in 0..<8
			{
				en_passant[rank][file] = false
			}
		}

		if Piece(piece^) == .WHITE_PAWN || Piece(piece^) == .BLACK_PAWN
		{

			// Set en passant if pawn moved two squares
			if new_rank == old_rank + (2 * i8(turn))
			{
				en_passant[old_rank + (1 * i8(turn))][old_file] = true
			}

			//Promotion !! (ALLOW DIFFERENT PIECES)
			if new_rank == 0 
			{
				piece^ = i8(Piece.BLACK_QUEEN)
			}
			if new_rank == 7
			{
				piece^ = i8(Piece.WHITE_QUEEN)
			}

		}

		//Move piece to desired square
		board_state[new_rank][new_file] = piece^


		//Swap turns
		if turn == .WHITE 
		{
			turn = .BLACK
		}
		else
		{
			turn = .WHITE
		}

		search_for_checks()
	}
	else
	{	//Move piece to original square
		board_state[old_rank][old_file] = piece^
	}
	piece^ = i8(Piece.NONE)

}

check_if_selection_legal :: proc(mouse_rank: i32, mouse_file: i32)
{
	current_piece := &board_state[mouse_rank][mouse_file] 

	if mouse_rank <= 7 && mouse_file <= 7
	{
		#partial switch Piece(current_piece^)
		{
		case .NONE:
			return

		case .WHITE_ROOK..=.WHITE_PAWN:
			if turn != .WHITE
			{
				return
			}

		case .BLACK_ROOK..=.BLACK_PAWN:

			if turn != .BLACK
			{
				return
			}
		}

		selected_piece[.PIECE] = i8(current_piece^)
		selected_piece[.RANK] = i8(mouse_rank)
		selected_piece[.FILE] = i8(mouse_file)
		current_piece^ = i8(Piece.NONE)
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
				turn = .WHITE
			case 'b':
				turn = .BLACK
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

search_for_checks :: proc()
{
	for r in 0..<8
	{
		for f in 0..<8
		{
			#partial switch Piece(board_state[r][f])
			{
			case .BLACK_ROOK..=.BLACK_PAWN:
				if turn == .WHITE
				{
					search_legal_moves_from_piece(i8(r), i8(f), Piece(board_state[r][f]))
					
				}

			case .WHITE_ROOK..=.WHITE_PAWN:
				if turn == .BLACK
				{
					search_legal_moves_from_piece(i8(r), i8(f), Piece(board_state[r][f]))
				}
			}
		}
	}
}

set_legal_moves :: proc()
{
	rank := selected_piece[.RANK]
	file := selected_piece[.FILE]
	piece := Piece(selected_piece[.PIECE])
	
	search_for_checks()	

	//See legal moves for desired piece
	search_legal_moves_from_piece(rank, file, piece)
	/* for all pieces
	   check if attacking king
	   if so
	   do check (only legal moves remove check)
	   otherwise
	   continue as normal
	   */
}

search_legal_moves_from_piece :: proc(rank, file: i8, piece: Piece)
{
	
	//Reset legal moves
	for rank in 0..<8
	{
		for file in 0..<8
		{
			legal_moves[rank][file] = false
		}
	}

	//Check moves for each piece
	#partial switch piece
	{
	case .WHITE_PAWN, .BLACK_PAWN: 
		starting_rank: i8
		dir: i8
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

		if file != 7
		{
			// Captures
			if board_state[rank + dir][file + 1] != i8(Piece.NONE) 
			{
				legal_moves[rank + dir][file + 1] = true
			}
			// En passant
			if en_passant[rank + dir][file + 1] == true 
			{
				legal_moves[rank + dir][file + 1] = true
			}

		}
		if file != 0
		{
			// Captures
			if board_state[rank + dir][file - 1] != i8(Piece.NONE)
			{
				legal_moves[rank + dir][file - 1] = true
			}
			// En passant
			if en_passant[rank + dir][file - 1] == true
			{
				legal_moves[rank + dir][file - 1] = true
			}
		}
		

		// Unobstructed movement
		if board_state[rank + dir][file] == i8(Piece.NONE)
		{
			legal_moves[rank + dir][file] = true
		}

		if rank == starting_rank
		{
			if board_state[rank + (2 * dir)][file] == i8(Piece.NONE) 
			{
				legal_moves[rank + (2 * dir)][file] = true	
			}
		}

	case .WHITE_ROOK..=.WHITE_KING, .BLACK_ROOK..=.BLACK_KING: // All pieces but pawns
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
				
				//Bounds checking
				if new_rank >= 0  &&
					new_rank <= 7 &&
					new_file >= 0 &&
					new_file <= 7 
				{
					search_square := Piece(board_state[new_rank][new_file])
					#partial switch search_square
					{
					case .NONE:
 						#partial switch piece
						{
						case .WHITE_KING, .BLACK_KING, .WHITE_KNIGHT, .BLACK_KNIGHT:
							//only check once per direction
							legal_moves[new_rank][new_file] = true
							hit_invalid_square = true 
						case:
							// Empty space
							legal_moves[new_rank][new_file] = true
						}
					case .WHITE_ROOK..=.WHITE_PAWN: 
						//Check if king is in check
 						#partial switch piece
						{
						case .BLACK_ROOK..=.BLACK_PAWN:
							if search_square == .WHITE_KING
							{
								white_king_piece[.RANK] = new_rank
								white_king_piece[.FILE] = new_file
								white_checked = true
							}
						}

						if turn == .WHITE
						{
							//Hit own piece
							hit_invalid_square = true
						}
						else
						{	//Hit enemy piece
							
							hit_invalid_square = true
							legal_moves[new_rank][new_file] = true
						}

					case .BLACK_ROOK..=.BLACK_PAWN: 
						//Check if king is in check
 						#partial switch piece
						{
						case .WHITE_ROOK..=.WHITE_PAWN:
							if search_square == .BLACK_KING
							{
								black_king_piece[.RANK] = new_rank
								black_king_piece[.FILE] = new_file
								black_checked = true
							}
						}

						if turn == .BLACK
						{	//Hit own piece
							hit_invalid_square = true
						}
						else
						{	//Hit enemy piece
							hit_invalid_square = true
							legal_moves[new_rank][new_file] = true
						}
					}
				}
				else
				{	// Hit a wall (OOB)
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
	white_pawn_image := rl.LoadImage(string_to_cstring(path, "white_pawn.png"))
	white_knight_image := rl.LoadImage(string_to_cstring(path, "white_knight.png"))
	white_bishop_image := rl.LoadImage(string_to_cstring(path, "white_bishop.png"))
	white_king_image := rl.LoadImage(string_to_cstring(path, "white_king.png"))
	white_queen_image := rl.LoadImage(string_to_cstring(path, "white_queen.png"))
	white_rook_image := rl.LoadImage(string_to_cstring(path, "white_rook.png"))
	black_pawn_image := rl.LoadImage(string_to_cstring(path, "black_pawn.png"))
	black_knight_image := rl.LoadImage(string_to_cstring(path, "black_knight.png"))
	black_bishop_image := rl.LoadImage(string_to_cstring(path, "black_bishop.png"))
	black_king_image := rl.LoadImage(string_to_cstring(path, "black_king.png"))
	black_queen_image := rl.LoadImage(string_to_cstring(path, "black_queen.png"))
	black_rook_image := rl.LoadImage(string_to_cstring(path, "black_rook.png"))
	gray_dot_image := rl.LoadImage(string_to_cstring(path, "gray_dot.png"))

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

	free_all(context.temp_allocator)
}

string_to_cstring :: proc(str: ..string) -> cstring
{
	joined_str := strings.join(str, "")
	cstr := strings.clone_to_cstring(joined_str)
	return cstr

}
to_string :: proc(v: any) -> string
{
	str := fmt.tprint(v)
	return str
}

draw_debug :: proc(str: ..string)
{
	joined_cstr := string_to_cstring(..str)
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
	piece_size := 100 //px !! (DONT HARDCODE)
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


