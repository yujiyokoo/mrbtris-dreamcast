#!/bin/sh

/vagrant/src/mruby-host/bin/mrbc -g -Btest_suite -o tests/test_suite.c src/game.rb src/block_shapes.rb tests/test_suite.rb

gcc -I/vagrant/src/mruby-host/include/ -L/vagrant/src/mruby-host/build/host/lib/ -o test_bin tests/test_suite.c tests/main.c -lmruby -lmruby_core -lm

./test_bin
