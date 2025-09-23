package treasurechess

import rl "vendor:raylib"
import "core:fmt"
import "core:c"
import "core:strings"
import "core:unicode/utf8"

BOARD_X :: 0
BOARD_Y :: 0
BOARD_SCALE :: 0.9
RES_X :: 640
RES_Y :: 480
TITLE :: "Treasure Chess"
MAX_FPS :: 480
FONT :: "pixelplay.png"
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
Piece :: enum 
{
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

square_size: i32	

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
//	-- Draw loop
	for !rl.WindowShouldClose() 
	{
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		draw_chessboard(BOARD_X, BOARD_Y, BOARD_SCALE)
		draw_pieces_fen(fen)
		rl.DrawFPS(0,0)
		rl.EndDrawing()
	}
}
draw_piece :: proc(piece: rune, rank: int, file: int)
{
	piece_size := 100
	scale := 2.0
	x := (i32(file) * square_size) + (square_size / 2) - i32(piece_size * int(scale)) / 2
	y := (i32(rank) * square_size) + (square_size / 2) - i32(piece_size * int(scale)) / 2
	position := rl.Vector2 { f32(x), f32(y) }
	rotation := 0.0
		

	rl.DrawTextureEx(
		white_knight_texture,
		position,
		f32(rotation),
		f32(scale),
		DEFAULT_TINT)

	rl.DrawTexture(
		black_rook_texture,
		(i32(file) * square_size) + (square_size / 2) - 50, // icons are 100x100 
		(i32(rank) * square_size) + (square_size / 2) - 50,
		DEFAULT_TINT)

}
draw_pieces_fen :: proc(fen: string)
{
	rank, file := 0, 0
	phase: FenPhase
	character: []rune
	for character in fen {
		switch phase
		{
		case .PLACEMENT:
			switch character 
			{
			case 'r', 'n', 'b', 'q', 'k', 'p', 
			     'R', 'N', 'B', 'Q', 'K', 'P':
				draw_piece(character, rank, file)
			}
		case .ACTIVE_COLOR:
		case .CASTLE:
		case .EN_PASSANT:
		case .HALF_MOVES:
		case .FULL_MOVES:
		}
		file = file + 1
		if character == '/' 
		{
			rank = rank + 1
			file = 0
		}
	}
/*
   	if current file > h / 8 INVALID FEN
	switch through each character
	if piece, place piece on square, TOP
	if number, skip x squares
	if /, skip to next rank, reset file
	if invalid character, INVALID FEN
	if space after 7th /
	specify team to move
	specify castles
	specify en passant
	specify half moves / moves
	
   */
	rl.DrawTexture(black_knight_texture, 0, 0, DEFAULT_TINT)
}



draw_chessboard :: proc(x, y: i32, scale: f32) 
{
	board_size: i32
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
