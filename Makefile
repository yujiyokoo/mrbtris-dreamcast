TARGET = mrbtris.elf

OBJS = src/mrbtris.o src/main.o src/game.o romdisk.o

MRB_BYTECODE = src/game.c

KOS_ROMDISK_DIR = romdisk

CFLAGS = -I/vagrant/src/mruby-sh4/include/ -L/vagrant/src/mruby-sh4/build/host/lib/

all: rm-elf $(TARGET)

include $(KOS_BASE)/Makefile.rules

clean:
	-rm -f $(TARGET) $(OBJS) romdisk.* $(MRB_BYTECODE)

rm-elf:
	-rm -f $(TARGET) romdisk.*

$(TARGET): $(OBJS) $(MRB_BYTECODE)
	kos-cc $(CFLAGS) -o $(TARGET) $(OBJS) -lmruby -lmruby_core -lm

$(MRB_BYTECODE): src/start_game.rb src/game.rb
	/vagrant/src/mruby-host/bin/mrbc -g -Bgame -o src/game.c src/game.rb src/start_game.rb 

test: test_bin
	./test_bin

test_bin: $(OBJS) $(MRB_BYTECODE) $(TEST_BYTECODE)
	gcc $(CFLAGS) -o test_bin  $(OBJS) $(TEST_BYTECODE)

$(TEST_BYTECODE): src/test_suite.rb
	/vagrant/src/mruby-host/bin/mrbc -g -Btest_suite src/test_suite.rb

run: $(TARGET)
	$(KOS_LOADER) $(TARGET)

dist:
	rm -f $(OBJS) romdisk.o romdisk.img
	$(KOS_STRIP) $(TARGET)
