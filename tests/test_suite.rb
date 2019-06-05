class GameStateTests < MTest::Unit::TestCase
  def test_trivial
    GameState.new(4, 1)
    assert(true, 'GameState initialises without crashing')
  end

  def test_initialisation
    state = GameState.new(2, 3)
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
      ["111111111111"] +
      [ "", "" ]

    board = GameState::EMPTY_BOARD
    assert(render_board(board) == expected_empty, 'Empty board returns empty board')
  end

  def test_new_empty_board_makes_new_instance
    state = GameState.new(5,5)
    board = state.new_empty_board
    assert(state.new_empty_board.object_id != board.object_id, 'new empty board object id is different')
  end

  class ExtendedGameState < GameState ; attr_accessor :board, :score ; end

  def board_with_4_full_rows
    [ExtendedGameState::HORIZONTAL_WALL] +
    [ExtendedGameState::LEFT_AND_RIGHT_BLOCKS]*16 +
    [ExtendedGameState::HORIZONTAL_WALL]*5 + [[], []]
  end

  def test_clear_full_rows_removes_full_rows
    state = ExtendedGameState.new(1,2)
    state.board = board_with_4_full_rows

    full_row_count = state.full_row_idxs.size
    assert(full_row_count == 4, 'board has 4 full rows')

    state.clear_full_rows

    full_row_count = state.full_row_idxs.size
    assert(full_row_count == 0, 'no full row should be left')
  end

  def test_clear_full_rows_keeps_row_height
    state = ExtendedGameState.new(1,2)
    state.board = board_with_4_full_rows

    assert(state.board.size == 24, 'board length is 24')
    state.clear_full_rows
    assert(state.board.size == 24, 'board length is 24 after clear full rows')
  end

  def test_clear_full_rows_adds_score
    state = ExtendedGameState.new(1,2)
    state.board = board_with_4_full_rows

    assert(state.score == 0, 'initial score is 0')
    state.clear_full_rows
    assert(state.score == 8, 'score after clearing 4 rows is 8')
  end

  def test_render_if_moved_renders_falling_block_if_moved
  end

  def test_render_if_moved_renders_falling_block_if_rotated
  end

  def test_save_to_board_adds_falling_block_to_board
  end

  # TODO: move previosu and next orientation & clock & anti clock to block shapes

  def test_board_section_for_cuts_a_section_off_board
  end

  # TODO: make a movement class and put can_rotate_cw, can_rotate_anticw?
  # TODO: movement class to have move_left, can_go_to_left, collides?

  # TODO: moved_horizontal? _vertical? rotated? moved? to blockshaps class?

  # TODO: next_block section as a sepatrate board?
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
