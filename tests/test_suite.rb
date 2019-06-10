class FakeDc2d
  attr_accessor :drawn_squares
  def initialize
    @drawn_squares = []
  end

  def draw20x20_640(x, y, r, g, b)
    @drawn_squares.push [x, y, r, g, b]
  end
end

class FakeScreen
  attr_reader :coloured_squares, :black_squares

  def initialize(dc2d)
    @dc2d = dc2d
    @coloured_squares = []
    @black_squares = []
  end

  def draw_black_square(x, y, ignore_border)
    @black_squares.push [x, y]
  end

  def draw_colour_square(x, y, colour, ignore_boder)
    @coloured_squares.push [x, y, colour]
  end
end

class ExtendedBoardState < BoardState
  attr_accessor :board, :score, :shape, :shape_orientation, :last_shape_orientation, :screen, :last_x, :last_y
end

def setup_state_with_single_t
  state = ExtendedBoardState.new(0, 1, FakeScreen.new(FakeDc2d.new))
  state.shape = BlockShapes::T
  state.shape_orientation += 1
  state
end

class BoardStateTests < MTest::Unit::TestCase
  def test_trivial
    BoardState.new(4, 1, Screen.new(FakeDc2d.new))
    assert(true, 'BoardState initialises without crashing')
  end

  def test_initialisation
    state = BoardState.new(2, 3, Screen.new(FakeDc2d.new))
    assert(state.x == 2, 'sets x')
    assert(state.y == 3, 'sets y')
  end

  def render_board(board)
    board.map { |row|
      row.map { |cell|
        if cell
          "1"
        else
          "0"
        end
      }.join("")
    }
  end

  def test_empty_board
    expected_empty =
      ["111111111111"] +
      ["100000000001"] * 20 +
      ["111111111111"]

    board = BoardState::EMPTY_BOARD
    assert(render_board(board) == expected_empty, 'Empty board returns empty board')
  end

  def test_new_empty_board_makes_new_instance
    state = BoardState.new(5, 5, Screen.new(FakeDc2d.new))
    board = state.new_empty_board
    assert(state.new_empty_board.object_id != board.object_id, 'new empty board object id is different')
  end

  def board_with_4_full_rows
    [ExtendedBoardState::HORIZONTAL_WALL] +
    [ExtendedBoardState::LEFT_AND_RIGHT_BLOCKS]*16 +
    [ExtendedBoardState::HORIZONTAL_WALL]*5 + [[], []]
  end

  def test_clear_full_rows_removes_full_rows
    state = ExtendedBoardState.new(1, 2, Screen.new(FakeDc2d.new))
    state.board = board_with_4_full_rows

    full_row_count = state.full_row_idxs.size
    assert(full_row_count == 4, 'board has 4 full rows')

    state.clear_full_rows

    full_row_count = state.full_row_idxs.size
    assert(full_row_count == 0, 'no full row should be left')
  end

  def test_clear_full_rows_keeps_row_height
    state = ExtendedBoardState.new(1, 2, Screen.new(FakeDc2d.new))
    state.board = board_with_4_full_rows

    assert(state.board.size == 24, 'board length is 24')
    state.clear_full_rows
    assert(state.board.size == 24, 'board length is 24 after clear full rows')
  end

  def test_clear_full_rows_adds_score
    state = ExtendedBoardState.new(1, 2, Screen.new(FakeDc2d.new))
    state.board = board_with_4_full_rows

    assert(state.score == 0, 'initial score is 0')
    state.clear_full_rows
    assert(state.score == 8, 'score after clearing 4 rows is 8')
  end

  def test_render_if_moved_renders_falling_block_if_moved
    fake_screen = FakeScreen.new FakeDc2d.new
    state = BoardState.new(1, 2, fake_screen)
    state.render_if_moved
    assert(fake_screen.coloured_squares.size == 4, 'calls draw_colour_square n times where n = block size if moved')
  end

  def test_render_if_moved_renders_falling_block_if_rotated
    fake_screen = FakeScreen.new FakeDc2d.new
    state = ExtendedBoardState.new(0, 0, fake_screen)
    state.shape_orientation = 1
    state.last_shape_orientation = 0
    state.render_if_moved
    assert(fake_screen.coloured_squares.size == 4, 'calls draw_colour_square n times where n = block size if rotated')
  end

  def test_render_if_moved_does_not_render_if_not_moved_or_rotated
    fake_screen = FakeScreen.new FakeDc2d.new
    state = BoardState.new(0, 0, fake_screen)
    state.render_if_moved
    assert(fake_screen.coloured_squares.size == 0, 'calls draw_colour_square 0 times if not moved or rotated')
  end


  def setup_state_with_single_square
    state = ExtendedBoardState.new(1, 1, Screen.new(FakeDc2d.new))
    state.shape = BlockShapes::SQ
    state.save_to_board
    state
  end

  def test_save_to_board_adds_falling_block_to_board
    state = setup_state_with_single_square

    expected_board =
      ["111111111111"] +
      ["101100000001"] +
      ["101100000001"] +
      ["100000000001"] * 18 +
      ["111111111111"]

    assert(render_board(state.board) == expected_board, 'transfers block shape to board')
  end

  # this assumes 'save to board' works
  def test_board_section_for_cuts_a_section_off_board
    state = setup_state_with_single_square

    expected_section =
      ["1011"] +
      ["1011"] +
      ["1000"] +
      ["1000"]
    assert(render_board(state.board_section_for(0, 1, 0, 0)) == expected_section, 'section takes 4x4 from coordinate')
  end

  def test_board_section_gives_blank_for_negative
    state = setup_state_with_single_square

    expected_section =
      ["0000"] +
      ["0111"] +
      ["0101"] +
      ["0101"]
    assert(render_board(state.board_section_for(0, 0, -1, -1)) == expected_section, 'section does error for negative')
  end

  def test_board_section_gives_blank_cells_for_negative_x
    state = setup_state_with_single_square

    expected_section =
      ["0000"] +
      ["0000"] +
      ["0000"] +
      ["0000"]
    assert(render_board(state.board_section_for(0, 0, -5, 0)) == expected_section, 'section gives blank for negative x')
  end

  def test_board_section_gives_blank_cells_for_negative_y
    state = setup_state_with_single_square
    expected_section =
      ["0000"] +
      ["0000"] +
      ["0000"] +
      ["0000"]
    assert(render_board(state.board_section_for(0, 0, 0, -5)) == expected_section, 'section gives blank for negative y')
  end

  def test_board_gives_blank_for_x_above_11
    state = setup_state_with_single_square
    expected_section =
      ["1100"] +
      ["0100"] +
      ["0100"] +
      ["0100"]
    assert(render_board(state.board_section_for(0, 0, 10, 0)) == expected_section, 'section gives blank for above 11')
  end

  def test_board_gives_blank_for_y_above_21
    state = setup_state_with_single_square
    expected_section =
      ["1000"] +
      ["1111"] +
      ["0000"] +
      ["0000"]
    assert(render_board(state.board_section_for(0, 0, 0, 20)) == expected_section, 'section gives blank for above 21')
  end

  def test_can_rotate_cw_is_false_if_wall_blocks
    state = setup_state_with_single_t
    assert(state.can_rotate_cw? == false)
  end

  def test_can_rotate_cw_is_true_if_not_blocked
    state = setup_state_with_single_t
    state.x += 1
    assert(state.can_rotate_cw?)
  end

  def test_can_rotate_anticw_is_false_if_floor
    state = setup_state_with_single_t
    state.shape_orientation -= 1 # upside down T
    state.x += 2
    state.y += 18
    assert(state.can_rotate_anticw? == false)
  end

  def test_can_rotate_cw_is_true_if_not_blocked
    state = setup_state_with_single_t
    state.x += 1
    assert(state.can_rotate_anticw?)
  end

  def test_can_go_left_is_false_if_blocked_by_wall
    state = setup_state_with_single_t
    state.shape_orientation -= 1
    assert(!state.can_go_left?)
  end

  def test_can_go_left_is_false_if_blocked_by_block
    state = setup_state_with_single_t
    state.save_to_board
    state.shape = BlockShapes::SQ
    state.x = 2
    state.y = 1
    assert(!state.can_go_left?)
  end

  def test_can_go_left_is_true_if_not_blocked
    state = setup_state_with_single_t
    state.x = 2
    state.y = 1
    assert(state.can_go_left?)
  end

  def test_can_go_right_is_false_if_blocked_by_wall
    state = setup_state_with_single_t
    state.x = 8
    state.y = 1
    assert(!state.can_go_right?, 'can_drop? is false if blocked by wall')
  end

  def test_can_go_right_is_false_if_blocked_by_block
    state = setup_state_with_single_t
    state.x = 8
    state.y = 1
    state.save_to_board
    state.shape = BlockShapes::SQ
    state.x = 6
    state.y = 1
    assert(!state.can_go_right?, 'can_drop? is false if blocked by another block')
  end

  def test_can_go_right_is_true_if_not_blocked
    state = setup_state_with_single_t
    assert(state.can_go_right?, 'can_go_right? is true if not blocked')
  end

  def test_can_drop_is_false_if_blocked_by_floor
    state = setup_state_with_single_t
    state.y += 17
    assert(!state.can_drop?, 'can_drop? is false if blocked by floor')
  end

  def test_can_drop_is_false_if_blocked_by_block
    state = setup_state_with_single_t
    state.y = 18
    state.save_to_board
    state.shape = BlockShapes::SQ
    state.x = 0
    state.y = 16
    assert(!state.can_drop?, 'can_drop? is false if blocked by another block')
  end

  def test_erase_last_pos_draws_black_squares
    state = setup_state_with_single_t
    state.last_shape_orientation = 0
    state.erase_last_pos

    assert(state.screen.black_squares == [[1, 0], [0, 1], [1, 1], [2, 1]])
  end

  # test next_block
  def test_next_block_sets_positions
    state = setup_state_with_single_t
    state.next_block(2,4)
    assert(state.x == 2, 'next_block sets x to given value')
    assert(state.y == 4, 'next_block sets y to given value')
    assert(state.last_x == 0, 'next_block sets last_x to 0')
    assert(state.last_y == 0, 'next_block sets last_y to 0')
    assert(state.shape_orientation == 0, 'next_block sets shape_orientation to 0')
  end

  def test_make_4x4_makes_3x3_shape_4x4
    state = setup_state_with_single_t
    sq_4x4 = [
      [false, :yellow, :yellow, false],
      [false, :yellow, :yellow, false],
      [false, false, false, false],
      [false, false, false, false]
    ]
    assert(state.make_4x4(BlockShapes::SQ[0]) == sq_4x4, 'make_4x4 makes shapes 4x4')
  end

  # test render_next_block
  def test_render_next_block_renders_coloured_squares
    state = setup_state_with_single_t
    state.render_next_block
    assert(state.screen.coloured_squares.size == 4, 'render_next_block draws 4 coloured squares')
  end

  def test_render_next_block_renders_black_squares
    state = setup_state_with_single_t
    state.render_next_block
    assert(state.screen.black_squares.size == 12, 'render_next_block draws 12 black squares')
  end
end

class ScreenTests < MTest::Unit::TestCase
  def test_draw_square_ignores_negative_with_ignore_false
    fake_dc2d = FakeDc2d.new
    screen = Screen.new(fake_dc2d)
    screen.draw_square(-1, -1, 0, 0, 0, false)
    assert(fake_dc2d.drawn_squares.size == 0, 'negative coordinates are ignored')
  end

  def test_draw_square_draws_negative_with_ignore_true
    fake_dc2d = FakeDc2d.new
    screen = Screen.new(fake_dc2d)
    screen.draw_square(-1, -1, 0, 0, 0, true)
    assert(fake_dc2d.drawn_squares.size == 1, 'negative coordinates are ignored')
  end

  def test_draw_board_draws_full_board
    fake_dc2d = FakeDc2d.new
    screen = Screen.new(fake_dc2d)
    state = setup_state_with_single_t
    screen.draw_board(state.board)
    # full board is 12 * 22
    assert(fake_dc2d.drawn_squares.size == 12 * 22, 'negative coordinates are ignored')
  end
end

class BlockShapesTests < MTest::Unit::TestCase
  def test_square_shape
    assert(BlockShapes::SQ[0] == [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ])
  end

  def test_cannot_modify_shapes
    square = BlockShapes::L[0]
    assert_raise(FrozenError) do
      square[0][0] = :unknown
    end
    assert_raise(FrozenError) do
      square[0] = []
    end
  end

  def test_color_to_rgb
    assert(BlockShapes.colour_to_rgb(:red) == [255, 0, 0], 'red to rgb gives 255,0,0')
  end
end

MTest::Unit.new.run
