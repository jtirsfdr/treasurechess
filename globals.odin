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

ROOK_DIRECTION :: enum {
	N,
	E,
	S,
	W,
}
BISHOP_DIRECTION :: enum {
	NE,
	SE,
	SW,
	NW,
}

FenPhase :: enum 
{
	PLACEMENT,
	ACTIVE_COLOR,
	CASTLE,
	EN_PASSANT,
	HALF_MOVES,
	FULL_MOVES,
}
Piece :: enum i8
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

Turn :: enum i8
{
	WHITE = 1,
	BLACK = -1,
}

SelectedPieceLabel :: enum i8
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
gray_dot_texture: rl.Texture

board_size: i32
square_size: i32	
white_checked := false
black_checked := false
scale := 1 //dpi scaling
selected_piece: [SelectedPieceLabel]i8
board_state: [8][8]i8
sim_board_state: [8][8]i8
legal_moves: [8][8]bool
en_passant: [8][8]bool
turn: Turn
font: rl.Font
white_king_piece: [SelectedPieceLabel]i8
black_king_piece: [SelectedPieceLabel]i8
debug_x: i32
debug_y: i32
line_break: i32

ColorPalettes :: enum {
	DARK,
	LIGHT,
}
