class TestSuite < MTest::Unit::TestCase
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

    board = GameState.new(0, 0).empty_board
    assert(render_board(board) == expected_empty, 'empty_board makes empty board')
  end
end

class BlockShapesTests < MTest::Unit::TestCase
  def test_square_shape
    assert(BlockShapes::SQ[0] == [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ])
  end

  def test_cannot_modify_shapes
    square = BlockShapes::SQ[0]
    assert_raise(FrozenError) do
      square[0][0] = :cyan
    end
    assert_raise(FrozenError) do
      square[0] = []
    end
  end
end

MTest::Unit.new.run
