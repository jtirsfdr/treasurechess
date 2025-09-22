package treasurechess

import rl "vendor:raylib"
import "core:fmt"
import "core:c"

BOARD_X :: 0
BOARD_Y :: 0
BOARD_SCALE :: 0.9
RES_X :: 640
RES_Y :: 480
TITLE :: "Treasure Chess"
MAX_FPS :: 480
FONT :: "pixelplay.png"
DEFAULT_TINT :: 255

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

main :: proc() 
{
	piece_set := "wikipieces"
	
	rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_RESIZABLE })
	rl.InitWindow(RES_X, RES_Y, TITLE)
	rl.InitAudioDevice()
	rl.SetTargetFPS(MAX_FPS)
	font = rl.LoadFont(FONT)
	init_pieces(piece_set)
//	-- Draw loop
	for !rl.WindowShouldClose() 
	{
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		draw_chessboard(BOARD_X, BOARD_Y, BOARD_SCALE)
		rl.DrawTexture(black_knight_texture, 0, 0, DEFAULT_TINT)
		rl.DrawFPS(0,0)
		rl.EndDrawing()
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

draw_chessboard :: proc(x, y: i32, scale: f32) 
{
	board_size: i32
	squarecolor: rl.Color
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
	square_size := board_size/8
	for rank in 0..<8 
	{
		for file in 0..<8 
		{
			//if rank + file is even, square is black
			if (rank + file) % 2 > 0 { 
				squarecolor = rl.BLACK
			} 
			else 
			{
				squarecolor = rl.LIGHTGRAY
			}
			rl.DrawRectangle(
				x + square_size * i32(file),
				y + square_size * i32(rank),
				square_size, square_size,
				squarecolor)
		}
	}
}

