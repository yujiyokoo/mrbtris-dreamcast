class TestSuite < MTest::Unit::TestCase
  def test_trivial
    GameState.new(3, 3, 4, 1)
    assert(true, 'GameState initialises without crashing')
  end
end

MTest::Unit.new.run
