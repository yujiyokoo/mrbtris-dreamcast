begin
  puts 'Starting the game.'
  GC.disable
  MainGame.new(Screen, Dc2d).main_loop
rescue => ex
  # Note backtrace is only available when you pass -g to mrbc
  p ex.backtrace
  p ex.inspect
  raise ex
end
