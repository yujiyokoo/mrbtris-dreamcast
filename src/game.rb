class GameState
  attr_accessor :x, :y

  attr_reader :board, :shape, :shape_orientation

  def initialize(width, height, x, y)
    @width, @height = width, height
    @x, @y = x, y
    @last_x, @last_y = 0, 0
    @board = copy_board(empty_board)
    @next_shape = random_shape
    @shape = random_shape
    @shape_orientation, @last_shape_orientation = 0, 0
    @score = 0
  end

  LEFT_AND_RIGHT_BLOCKS =
    [:grey, false, false, false, false, false, false, false, false, false, false, :grey]

  # note that board starts from -1 to allow easy comparison when block gets to the left all
  def empty_board
    horizontal_wall =
      [:grey, :grey, :grey, :grey, :grey, :grey, :grey, :grey, :grey, :grey, :grey, :grey]

    [ horizontal_wall ] +
    [ LEFT_AND_RIGHT_BLOCKS ] * 20 +
    [ horizontal_wall ] +
    [[], []] # extra 2 rows for when it gets to the bottom
  end

  def copy_board(original)
    new_board = []

    empty_board.each { |row|
      new_row = []
      row.each { |col|
        new_row.push col
      }
      new_board.push new_row
    }

    new_board
  end

  def clear_board
    to_delete = []
    (1..20).each {|idx|
      if @board[idx].reduce {|a,b| a&&b}
        to_delete << idx
      end
    }
    to_delete.each { |i|
      @board.delete_at(i)
      @board.insert(1, LEFT_AND_RIGHT_BLOCKS)
    }
    scores = [0, 1, 2, 3, 8]
    @score += scores[to_delete.size]
  end

  def square_shape
    [
      [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ],
      [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ],
      [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ],
      [ [false, :yellow, :yellow], [false, :yellow, :yellow], [], [] ],
    ]
  end

  def i_shape
    [
      [ [], [:cyan, :cyan, :cyan, :cyan], [], [] ],
      [ [false, false, :cyan], [false, false, :cyan], [false, false, :cyan], [false, false, :cyan] ],
      [ [], [], [:cyan, :cyan, :cyan, :cyan], [] ],
      [ [false, :cyan], [false, :cyan], [false, :cyan], [false, :cyan] ]
    ]
  end

  def l_shape
    [
      [ [false, false, :orange], [:orange, :orange, :orange], [], [] ],
      [ [false, :orange, false], [false, :orange, false], [false, :orange, :orange], [] ],
      [ [false, false, false], [:orange, :orange, :orange], [:orange, false, false], [] ],
      [ [:orange, :orange, false], [false, :orange, false], [false, :orange, false], [] ]
    ]
  end

  def j_shape
    [
      [ [:blue, false, false], [:blue, :blue, :blue], [], [] ],
      [ [false, :blue, :blue], [false, :blue, false], [false, :blue, false], [] ],
      [ [false, false, false], [:blue, :blue, :blue], [false, false, :blue], [] ],
      [ [false, :blue, false], [false, :blue, false], [:blue, :blue, false], [] ]
    ]
  end

  def s_shape
    [
      [ [false, :green, :green], [:green, :green, false], [], [] ],
      [ [false, :green, false], [false, :green, :green], [false, false, :green], [] ],
      [ [false, false, false], [false, :green, :green], [:green, :green, false], [] ],
      [ [:green, false, false], [:green, :green, false], [false, :green, false], [] ]
    ]
  end

  def z_shape
    [
      [ [:red, :red, false], [false, :red, :red], [], [] ],
      [ [false, false, :red], [false, :red, :red], [false, :red, false], [] ],
      [ [false, false, false], [:red, :red, false], [false, :red, :red], [] ],
      [ [false, :red, false], [:red, :red, false], [:red, false, false], [] ]
    ]
  end

  def t_shape
    [
      [ [false, :purple, false], [:purple, :purple, :purple], [], [] ],
      [ [false, :purple, false], [false, :purple, :purple], [false, :purple, false], [] ],
      [ [false, false, false], [:purple, :purple, :purple], [false, :purple, false], [] ],
      [ [false, :purple, false], [:purple, :purple, false], [false, :purple, false], [] ]
    ]
  end

  def random_shape
    candidates = [square_shape, i_shape, l_shape, j_shape, s_shape, z_shape, t_shape]

    candidates[rand(candidates.size)]
  end

  def render_if_moved
    if moved? || rotated?
      erase_last_pos
      @shape[@shape_orientation].each_with_index { |row, rownum|
        row.each_with_index { |cell, colnum|
          Screen.draw_colour_square(@x+colnum, @y+rownum, cell, false) if cell
        }
      }
    end
  end

  def save_to_board
    @shape[@shape_orientation].each_with_index { |row, rownum|
      row.each_with_index { |cell, colnum|
        @board[@y+rownum][@x+colnum] = cell if cell
      }
    }
  end

  def next_orientation(orientation)
    (orientation + 1) % 4
  end

  def previous_orientation(orientation)
    (orientation + 3) % 4
  end

  def clockwise
    @shape_orientation = next_orientation(@shape_orientation) if can_rotate_cw?
  end

  def anticlockwise
    @shape_orientation = previous_orientation(@shape_orientation) if can_rotate_anticw?
  end

  def zero_if_negative(x)
    if x < 0
      0
    else
      x
    end
  end

  def board_section_for(x, y, horizontal_shift, vertical_shift)
      left = @x + horizontal_shift
      right = @x + horizontal_shift + 3
      top = @y + vertical_shift

      left_or_zero = zero_if_negative(left)

      outside_area = if left < 0
        [false] * (0-left)
      else
        []
      end

      [
        outside_area + Array(@board[top][left_or_zero..right]),
        outside_area + Array(@board[top+1][left_or_zero..right]),
        outside_area + Array(@board[top+2][left_or_zero..right]),
        outside_area + Array(@board[top+3][left_or_zero..right])
      ]
  end

  def can_rotate_cw?
    board_section = board_section_for(@x, @y, 0, 0)
    next_shape = @shape[next_orientation(@shape_orientation)]
    !collides?(board_section, next_shape)
  end

  def can_rotate_anticw?
    board_section = board_section_for(@x, @y, 0, 0)
    previous_shape = @shape[previous_orientation(@shape_orientation)]
    !collides?(board_section, previous_shape)
  end

  def move_left
    @x -= 1 if can_go_left?
  end

  def can_go_left?
    board_section = board_section_for(@x, @y, -1, 0)
    !collides?(board_section, @shape[@shape_orientation])
  end

  def collides?(board_section, block)
    board_section
      .zip(block)
      .map{|a,b| a.zip(b)}
      .flatten(1)
      .map {|a, b| a&&b}
      .reduce {|a,b| a||b}
  end

  def move_right
    @x += 1 if can_go_right?
  end

  def can_go_right?
    board_section = board_section_for(@x, @y, 1, 0)
    !collides?(board_section, @shape[@shape_orientation])
  end

  def move_down
    @y += 1 if can_drop?
  end

  def move_down!
    @y += 1
  end

  def can_drop?
    board_section = board_section_for(@x, @y, 0, 1)
    !collides?(board_section, @shape[@shape_orientation])
  end

  def save_current_position
    # TODO: remember all squares instead?
    @last_x = @x
    @last_y = @y
    @last_shape_orientation = @shape_orientation
  end

  def moved_horizontal?
    @last_x != @x
  end

  def moved_vertical?
    @last_y != @y
  end

  def rotated?
    @last_shape_orientation != @shape_orientation
  end

  def moved?
    @last_x != @x || @last_y != @y
  end

  def erase_last_pos
    @shape[@last_shape_orientation].each_with_index { |row, rownum|
      row.each_with_index { |cell, colnum|
        Screen.draw_black_square(@last_x+colnum, @last_y+rownum) if cell
      }
    }
  end

  def next_block(x, y)
    @x, @y = x, y
    @last_x, @last_y = 0, 0
    @shape = @next_shape
    @next_shape = random_shape
    @shape_orientation = 0
  end

  def normalise(shape)
    shape.map { |row| row + [false] * (4 - row.size) }
  end

  def render_next_block
    normalised_next_shape = normalise(@next_shape[0])
    normalised_next_shape.each_with_index { |row, rownum|
      row.each_with_index { |cell, colnum|
        if cell
          Screen.draw_colour_square(colnum + 14, rownum + 2, cell, true)
        else
          Screen.draw_square(colnum + 14, rownum + 2, 0, 0, 0, true)
        end
      }
    }
  end

  def render_score
    Dc2d::render_score(@score)
  end
end

module Screen
  LEFT_SPACE_PX=260
  TOP_SPACE_PX=20

  def self.draw_square(x, y, r, g, b, ignore_boundary)
    if (x > 0 && x < 11 && y > 0 && y < 21) || ignore_boundary
      Dc2d::draw20x20_640(x*20+LEFT_SPACE_PX, y*20+TOP_SPACE_PX, r, g, b)
    end
  end

  def self.name_to_rgb(colour)
    case colour
    when :grey
      [192, 192, 192]
    when :cyan
      [0, 192, 192]
    when :yellow
      [192, 192, 0]
    when :purple
      [128, 0, 128]
    when :green
      [0, 128, 0]
    when :red
      [255, 0, 0]
    when :blue
      [0, 0, 255]
    when :orange
      [255, 165, 0]
    else
      [0, 0, 0]
    end
  end

  def self.draw_colour_square(x, y, colour, ignore_boundary)
    draw_square(x, y, *(name_to_rgb colour), ignore_boundary)
  end

  def self.draw_black_square(x, y, ignore_boundary = false)
    draw_square(x, y, 0, 0, 0, ignore_boundary)
  end

  def self.draw_board(board)
    board.each_with_index { |row, y|
      row.each_with_index { |cell, x|
        if cell
          draw_colour_square(x, y, cell, true)
        else
          draw_black_square(x, y, true)
        end
      }
    }
  end
end

module MainGame
  FPS = 50

  def self.main_loop
    running = false

    Dc2d::clear_score(@score)

    while true do
      Screen.draw_board(([].push [:grey] * 12) * 22)
      while !running do
        rand(1) # hopefully this would give us a "more random" start point
        button_state = Dc2d::get_button_state
        if button_state
          running = true if Dc2d::start_btn?(button_state)
        end
      end

      frame = 0
      tick = 0
      curr_wait = 10
      ticks_since_wait_change = 0
      last_button_state = 0
      button_state_unchanged_for = 0

      moving_block = GameState.new(3, 3, 4, 1)
      Screen.draw_board(moving_block.board)
      moving_block.render_next_block
      moving_block.render_score

      while running do
        # for the moment, let's assume this gives us 50hz...
        Dc2d::waitvbl
        frame = (frame + 1) % FPS

        # even if update doesn't happen, input should be recorded every frame

        button_state = Dc2d::get_button_state

        if last_button_state == button_state
          button_state_unchanged_for += 1
        else
          button_state_unchanged_for = 0
        end

        if button_state
          unless (moving_block.moved_horizontal? || moving_block.rotated?)
            moving_block.move_left if Dc2d::dpad_left?(button_state) && (button_state_unchanged_for == 0 || button_state_unchanged_for > 9)
            moving_block.move_right if Dc2d::dpad_right?(button_state) && (button_state_unchanged_for == 0 || button_state_unchanged_for > 9)
            moving_block.clockwise if Dc2d::btn_a?(button_state) && (button_state_unchanged_for == 0 || button_state_unchanged_for > 9)
            moving_block.anticlockwise if Dc2d::btn_b?(button_state) && (button_state_unchanged_for == 0 || button_state_unchanged_for > 9)
          end

          unless moving_block.moved_vertical?
            moving_block.move_down if Dc2d::dpad_down?(button_state)
          end
        end

        last_button_state = button_state

        next unless (frame % 5) == 0

        moving_block.render_if_moved

        moving_block.save_current_position

        tick = (tick + 1) % curr_wait
        next unless tick == 0

        ticks_since_wait_change += 1
        if ticks_since_wait_change >= 50
          curr_wait -= 1 unless curr_wait == 1
          ticks_since_wait_change = 0
        end

        if moving_block.can_drop?
          moving_block.move_down
        else
          moving_block.save_to_board
          moving_block.clear_board
          Screen.draw_board(moving_block.board)

          moving_block.next_block(4, 0)
          running = false unless moving_block.can_drop?
          moving_block.move_down!

          moving_block.render_next_block
          moving_block.render_score
        end
      end
    end
  end
end
