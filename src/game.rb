class BoardState
  attr_accessor :x, :y, :last_frame_block_state

  attr_reader :board, :shape, :shape_orientation, :next_shape, :score

  def initialize(x, y, screen)
    @x, @y = x, y
    @screen = screen
    @last_x, @last_y = 0, 0
    @board = new_empty_board
    update_board_bitmap
    @next_shape = BlockShapes.random_shape
    sp = BlockShapes.random_shape
    @shape_name = sp[0]
    @shape = sp[1]
    @shape_orientation, @last_shape_orientation = 0, 0
    @last_frame_block_state = { x: 0, y: 0, orientation: 0 }
    @score = 0
    build_shape_bitmaps
  end

  LEFT_AND_RIGHT_BLOCKS = ([:grey] + [false] * 10 + [:grey]).freeze
  HORIZONTAL_WALL = ([:grey]*12).freeze
  BELOW_BOTTOM = ([false] * 12).freeze

  EMPTY_BOARD =
    (
      [ HORIZONTAL_WALL ] +
      [ LEFT_AND_RIGHT_BLOCKS ] * 20 +
      [ HORIZONTAL_WALL ] +
      [ BELOW_BOTTOM, BELOW_BOTTOM ] # 2 lines below bottom border for easier processing
    ).freeze

  def new_empty_board
    new_board = Array.new

    EMPTY_BOARD.each { |row|
      new_board.push row.compact # compact simply copies if no nil present
    }

    new_board
  end

  def update_board_bitmap
    @board_bitmap = @board.map { |row|
      ((row[0] ? 1 : 0) << 11) |
      ((row[1] ? 1 : 0) << 10) |
      ((row[2] ? 1 : 0) << 9) |
      ((row[3] ? 1 : 0) << 8) |
      ((row[4] ? 1 : 0) << 7) |
      ((row[5] ? 1 : 0) << 6) |
      ((row[6] ? 1 : 0) << 5) |
      ((row[7] ? 1 : 0) << 4) |
      ((row[8] ? 1 : 0) << 3) |
      ((row[9] ? 1 : 0) << 2) |
      ((row[10] ? 1 : 0) << 1) |
      (row[11] ? 1 : 0)
    }
  end

  def update_last_frame_block_state
    @last_frame_block_state = { x: @x, y: @y, orientation: @shape_orientation }
  end

  def full_row_idxs
    idxs = []
    (1..20).each {|idx|
      if @board[idx].reduce {|a,b| a&&b}
        idxs << idx
      end
    }
    idxs
  end

  def clear_full_rows
    fr_idxs = full_row_idxs
    fr_idxs.each { |i|
      @board.delete_at(i)
      @board.insert(1, LEFT_AND_RIGHT_BLOCKS.compact) # compact simply copies if no nil present
    }
    scores = [0, 1, 2, 3, 8]
    @score += scores[fr_idxs.size]
    fr_idxs.size
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
    if x < 0 ; 0 ; else ; x ; end
  end

  def board_section_for(x, y, horizontal_shift, vertical_shift)
    left = x + horizontal_shift
    top = y + vertical_shift
    four_ones = "1111".to_i(2)
    rows = @board_bitmap[top..top+3].map { |row|
      # board is 12 x 22
      # maks (four_ones) is 1111, shifting 8 gets them to 0-3 from left
      shift = 8 - left
      (row & (four_ones << shift)) >> shift
    }

    (rows[0] << 12) | (rows[1] << 8) | (rows[2] << 4) | rows[3]
  end

  def old_board_section_for(left, y, horizontal_shift, vertical_shift)
    original_left = x + horizontal_shift
    adjusted_left = zero_if_negative(original_left)
    right = original_left + 3
    top = (y + vertical_shift)

    left_outside_area = if original_left < 0
      [false] * [(0-original_left), 4].min
    else
      []
    end

    right_outside_area = if right > 11
      [false] * [(right-11), 4].min
    else
      []
    end

    board_section = [
      (row(top, adjusted_left, right, left_outside_area, right_outside_area)),
      (row(top+1, adjusted_left, right, left_outside_area, right_outside_area)),
      (row(top+2, adjusted_left, right, left_outside_area, right_outside_area)),
      (row(top+3, adjusted_left, right, left_outside_area, right_outside_area))
    ]

    ((board_section[0][0] ? 1 : 0 )<< 15) |
      ((board_section[0][1] ? 1 : 0 )<< 14) |
      ((board_section[0][2] ? 1 : 0 )<< 13) |
      ((board_section[0][3] ? 1 : 0 )<< 12) |
      ((board_section[1][0] ? 1 : 0 )<< 11) |
      ((board_section[1][1] ? 1 : 0 )<< 10) |
      ((board_section[1][2] ? 1 : 0 )<< 9) |
      ((board_section[1][3] ? 1 : 0 )<< 8) |
      ((board_section[2][0] ? 1 : 0 )<< 7) |
      ((board_section[2][1] ? 1 : 0 )<< 6) |
      ((board_section[2][2] ? 1 : 0 )<< 5) |
      ((board_section[2][3] ? 1 : 0 )<< 4) |
      ((board_section[3][0] ? 1 : 0 )<< 3) |
      ((board_section[3][1] ? 1 : 0 )<< 2) |
      ((board_section[3][2] ? 1 : 0 )<< 1) |
      (board_section[3][3] ? 1 : 0 )
  end

  private
  def build_shape_bitmaps
    @shape_bitmaps = {}
    all_shapes = BlockShapes::all_shapes
    all_shapes.each { |curr_shape|
      @shape_bitmaps[curr_shape[0]] = curr_shape[1].map { |curr_shape_orientation|
        ((curr_shape_orientation[0][0] ? 1 : 0 )<< 15) |
        ((curr_shape_orientation[0][1] ? 1 : 0 )<< 14) |
        ((curr_shape_orientation[0][2] ? 1 : 0 )<< 13) |
        ((curr_shape_orientation[0][3] ? 1 : 0 )<< 12) |
        ((curr_shape_orientation[1][0] ? 1 : 0 )<< 11) |
        ((curr_shape_orientation[1][1] ? 1 : 0 )<< 10) |
        ((curr_shape_orientation[1][2] ? 1 : 0 )<< 9) |
        ((curr_shape_orientation[1][3] ? 1 : 0 )<< 8) |
        ((curr_shape_orientation[2][0] ? 1 : 0 )<< 7) |
        ((curr_shape_orientation[2][1] ? 1 : 0 )<< 6) |
        ((curr_shape_orientation[2][2] ? 1 : 0 )<< 5) |
        ((curr_shape_orientation[2][3] ? 1 : 0 )<< 4) |
        ((curr_shape_orientation[3][0] ? 1 : 0 )<< 3) |
        ((curr_shape_orientation[3][1] ? 1 : 0 )<< 2) |
        ((curr_shape_orientation[3][2] ? 1 : 0 )<< 1) |
        (curr_shape_orientation[3][3] ? 1 : 0 )
      }
    }
    puts "---------------------------------------------------------"
    p @shape_bitmaps
    puts "---------------------------------------------------------"
  end

  def row(row_idx, l, r, left_outside_area, right_outside_area)
    if row_idx < 0 || row_idx >= @board.size || r < 0 || l > 11
      [false, false, false, false]
    else
      left_outside_area + Array(@board[row_idx][l..r]) + right_outside_area
    end
  end

  public
  def can_rotate_cw?
    board_section = board_section_for(@x, @y, 0, 0)
    next_shape = @shape_bitmaps[@shape_name][next_orientation(@shape_orientation)]
    !collides?(board_section, next_shape)
  end

  def can_rotate_anticw?
    board_section = board_section_for(@x, @y, 0, 0)
    previous_shape = @shape_bitmaps[@shape_name][previous_orientation(@shape_orientation)]
    !collides?(board_section, previous_shape)
  end

  def move_left(dc2d)
    @x -= 1 if can_go_left?(dc2d)
  end

  def can_go_left?(dc2d)
    cgl_start = dc2d::get_current_ms
    board_section = board_section_for(@x, @y, -1, 0)
    #$profile << "--- after bord_section_for: #{dc2d::get_current_ms - cgl_start}\n"
    collides = !collides?(board_section, @shape_bitmaps[@shape_name][@shape_orientation], dc2d)
    #$profile << "--- after collides check buttons: #{dc2d::get_current_ms - cgl_start}\n"
    collides
  end

  def collides?(board_section, block_bitmap, dc2d = nil)
    col_start = dc2d::get_current_ms(dc2d) unless dc2d.nil?

    (board_section & block_bitmap) != 0
  end

  def move_right
    @x += 1 if can_go_right?
  end

  def can_go_right?
    board_section = board_section_for(@x, @y, 1, 0)
    !collides?(board_section, @shape_bitmaps[@shape_name][@shape_orientation])
  end

  def move_down
    @y += 1 if can_drop?
  end

  def move_down!
    @y += 1
  end

  def can_drop?
    board_section = board_section_for(@x, @y, 0, 1)
    !collides?(board_section, @shape_bitmaps[@shape_name][@shape_orientation])
  end

  def save_current_position
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

  # TODO: should be on Screen?
  # XXX: 0 to 10 ms per run
  def render_if_moved(dc2d)
    curr = dc2d::get_current_ms
    if moved? || rotated?
      erase_last_pos
      @shape[@shape_orientation].each_with_index { |row, rownum|
        row.each_with_index { |cell, colnum|
          @screen.draw_colour_square(@x+colnum, @y+rownum, cell, false) if cell
        }
      }
      update_last_frame_block_state
    end
    $profile << "* render took: #{dc2d::get_current_ms - curr}\n"
  end

  def erase_last_pos
    # p @last_frame_block_state
    @shape[@last_frame_block_state[:orientation]].each_with_index { |row, rownum|
      row.each_with_index { |cell, colnum|
        @screen.draw_black_square(@last_frame_block_state[:x]+colnum, @last_frame_block_state[:y]+rownum, false) if cell && cell != @shape[@shape_orientation]
      }
    }
  end

  def whiten_curr_pos
     @shape[@shape_orientation].each_with_index { |row, rownum|
      row.each_with_index { |_cell, colnum|
        @screen.draw_colour_square(@x+colnum, @y+rownum, :white, false) if _cell
      }
    }
  end

  def next_block(x, y)
    @x, @y = x, y
    @last_x, @last_y = 0, 0
    @shape_name = @next_shape[0]
    @shape = @next_shape[1]
    @next_shape = BlockShapes.random_shape
    @shape_orientation = 0
    @last_frame_block_state = { x: @x, y: @y, orientation: 0 }
  end
end

class Screen
  LEFT_SPACE_PX=260
  TOP_SPACE_PX=20

  attr_reader :dc2d

  def initialize(dc2d)
    @dc2d = dc2d
  end

  def render_score(board_state)
    @dc2d::render_score(board_state.score)
  end

  def render_upcoming_block_pane(board_state)
    normalised_next_shape = make_4x4(board_state.next_shape[1][0])
    normalised_next_shape.each_with_index { |row, rownum|
      row.each_with_index { |cell, colnum|
        if cell
          draw_colour_square(colnum + 14, rownum + 2, cell, true)
        else
          draw_black_square(colnum + 14, rownum + 2, true)
        end
      }
    }
  end

  def make_4x4(shape)
    shape.map { |row| row + [false] * (4 - row.size) }
  end

  def draw_square(x, y, r, g, b, ignore_boundary)
    if (x > 0 && x < 11 && y > 0 && y < 21) || ignore_boundary
      @dc2d::draw20x20_640(x*20+LEFT_SPACE_PX, y*20+TOP_SPACE_PX, r, g, b)
    end
  end

  def draw_colour_square(x, y, colour, ignore_boundary)
    draw_square(x, y, *(BlockShapes.colour_to_rgb colour), ignore_boundary)
  end

  def draw_black_square(x, y, ignore_boundary)
    draw_square(x, y, 0, 0, 0, ignore_boundary)
  end

  def draw_board(board)
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

class GameState
  FPS = 60
  BUFSIZE = 100

  attr_accessor :frame, :tick, :curr_wait, :ticks_since_wait_change, :button_state_unchanged_for, :board_state, :button_states, :curr_button_index

  def initialize(dc2d, screen, board_state_class)
    @screen = screen
    @board_state_class = board_state_class

    @cont = {}
    @cont[:start], @cont[:d_left], @cont[:d_right], @cont[:d_up],
      @cont[:d_down], @cont[:a], @cont[:b] = dc2d::get_button_masks

    reset
  end

  def reset
    @frame = 0
    @tick = 0
    @curr_wait = 10
    @ticks_since_wait_change = 0
    @board_state = @board_state_class.new(4, 1, @screen)
    @unchanged_buttons = {left: 0, right: 0, up: 0, down: 0, a: 0, b: 0}
    @held_buttons = {start: 0, d_left: 0, d_right: 0, d_up: 0, d_down: 0, a: 0, b: 0}
    @controller_buf_last_index = 0 # we read from last index + 1 when getting input
    @button_states = [0] * BUFSIZE
    @curr_button_index = 0
  end

  def last_frame_block_state=(block_state)
    @board_state.last_frame_block_state = block_state
  end

  def increment_frame
    @frame = (@frame + 1) % FPS
  end

  def update_button_states(dc2d)
    while next_state = dc2d.get_next_button_state(@curr_button_index) do
      @button_states[@curr_button_index] = next_state
      @curr_button_index = (@curr_button_index + 1) % BUFSIZE
    end
    @curr_button_index = (@curr_button_index - 1) % BUFSIZE # wind back as we've gone past.
  end

  def discard_button_buffer(dc2d)
    @curr_button_index = dc2d::get_current_button_index
  end

  def exit_input?(frame_idxs)
    frame_idxs.any? { |idx| @cont[:start] & @button_states[idx] != 0 }
  end

  def update_board_for_indices(frame_idxs, dc2d)
    ubfi_start = dc2d::get_current_ms
    btn_pressed = {}
    $profile << "update_for_indices, start: #{ubfi_start}, "

    input_summary = frame_idxs.reduce { |acc, v| @button_states[v] & acc }

    [:d_left, :d_right, :d_up, :d_down, :a, :b].each { |key|
      if input_summary & @cont[key] != 0
        @held_buttons[key] += 1
      else
        @held_buttons[key] = 0
        if (@cont[key] & @button_states[frame_idxs[-1]]) != 0
          btn_pressed[key] = true
        end
      end
    }
    $profile << ", h-check: #{ dc2d::get_current_ms - ubfi_start}, w/ #{frame_idxs.size} frames"

    unless @board_state.moved_horizontal? # XXX: is this necesarry?
      left_input = btn_pressed[:d_left] || @held_buttons[:d_left] > 10
      right_input = btn_pressed[:d_right] || @held_buttons[:d_right] > 10
      @board_state.move_left(dc2d) if left_input
      @board_state.move_right if right_input
    end
    $profile << ", after horz: #{ dc2d::get_current_ms - ubfi_start}"

    unless @board_state.rotated?
      @board_state.clockwise if btn_pressed[:a] || @held_buttons[:a] > 10
      @board_state.anticlockwise if btn_pressed[:b] || @held_buttons[:b] > 10
    end
    $profile << ", after rot: #{ dc2d::get_current_ms - ubfi_start}"

    unless @board_state.moved_vertical?
      @board_state.move_down if btn_pressed[:d_down] || @held_buttons[:d_down] > 10
    end
    $profile << ", after vert: #{ dc2d::get_current_ms - ubfi_start}\n"
  end
end

$profile = ''

class MainGame
  SOLID_BOARD_BEFORE_START = ([].push [:grey] * 12) * 22

  def initialize(screen, dc2d)
    @dc2d = dc2d
    @screen = screen.new(@dc2d)
    @game_state = GameState.new(@dc2d, @screen, BoardState)
  end

  def wait_for_start_button
    while true do
      rand(1) # hopefully this would give us a "more random" start point
      button_state = @dc2d::get_button_state

      break if button_state && @dc2d::start_btn?(button_state)
    end
  end

  def main_loop
    $profile = ''
    @dc2d::clear_score(@score)

    @screen.draw_board(SOLID_BOARD_BEFORE_START)

    @dc2d::init_controller_buffer()
    @dc2d::start_controller_reader()

    exiting = false

    while !exiting do # 'main loop'
      # wait_for_start_button
      running = true

      @game_state.reset

      @screen.draw_board(@game_state.board_state.board)
      @screen.render_upcoming_block_pane(@game_state.board_state)
      @screen.render_score(@game_state.board_state)

      prev0 = 0
      current0 = 0

      @game_state.discard_button_buffer(@dc2d)

      while running do
        $profile << "doing waitvbl: #{before_wait = @dc2d::get_current_ms}"
        @dc2d::waitvbl
        $profile << "...#{@dc2d::get_current_ms - before_wait}.\n"

        current0 = @dc2d::get_current_ms
        $profile << "elapsed: #{current0 - prev0}\n"
        prev0 = current0

        @game_state.increment_frame

        prev_button_index = @game_state.curr_button_index
        @game_state.update_button_states(@dc2d)

        frame_idxs = if prev_button_index > @game_state.curr_button_index
          (prev_button_index..(GameState::BUFSIZE-1)).to_a + (0..@game_state.curr_button_index).to_a
        else
          (prev_button_index..@game_state.curr_button_index).to_a
        end

        if @game_state.exit_input?(frame_idxs)
          exiting = true
          running = false
        end

        $profile << "before update_board_for...: #{@dc2d::get_current_ms - prev0}\n"

        @game_state.update_board_for_indices(frame_idxs, @dc2d)

        $profile << "before render...: #{@dc2d::get_current_ms - prev0}\n"
        @game_state.board_state.render_if_moved(@dc2d)

        $profile << "before looping back: #{@dc2d::get_current_ms - prev0}\n" unless (@game_state.frame % 3) == 0

        next unless (@game_state.frame % 3) == 0

        $profile << "  --- in frame_idx loop before saving state position: #{@dc2d::get_current_ms - prev0}\n"
        @game_state.board_state.save_current_position

        @game_state.tick = (@game_state.tick + 1) % @game_state.curr_wait
        next unless @game_state.tick == 0

        $profile << "  --- in frame_idx loop wait value check/change: #{@dc2d::get_current_ms - prev0}\n"

        @game_state.ticks_since_wait_change += 1
        if @game_state.ticks_since_wait_change >= 30
          @game_state.curr_wait -= 1 unless @game_state.curr_wait == 1
          @game_state.ticks_since_wait_change = 0
        end

        $profile << "  --- in frame_idx loop before checking can_drop: #{@dc2d::get_current_ms - prev0}\n"
        if @game_state.board_state.can_drop?
          @game_state.board_state.move_down!
        else
          @game_state.board_state.save_to_board
          @game_state.board_state.whiten_curr_pos
          @game_state.board_state.clear_full_rows
          @screen.draw_board(@game_state.board_state.board) # re-render whole board

          $profile << "  --- in frame_idx loop after draw_board: #{@dc2d::get_current_ms - prev0}\n"
          @game_state.board_state.next_block(4, 0)
          if !@game_state.board_state.can_drop?
            # Stacked to the top...
            running = false
            @game_state.board_state.move_down!
            @game_state.board_state.save_to_board
            @screen.draw_board(@game_state.board_state.board) # re-render whole board with finished state
            $profile << "  --- in frame_idx loop after next block drop: #{@dc2d::get_current_ms - prev0}\n"
          end
          @game_state.board_state.move_down!
          $profile << "  --- in frame_idx loop after move_down!: #{@dc2d::get_current_ms - prev0}\n"
          @screen.render_upcoming_block_pane(@game_state.board_state)
          @screen.render_score(@game_state.board_state)
          @game_state.board_state.update_board_bitmap
          @game_state.discard_button_buffer(@dc2d)
          $profile << "  --- in frame_idx loop after everything: #{@dc2d::get_current_ms - prev0}\n"
        end

        @game_state.board_state.render_if_moved(@dc2d)
      end
    end
    puts $profile
  end
end
