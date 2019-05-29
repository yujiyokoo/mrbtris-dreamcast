TARGET = mrbtris.elf

OBJS = src/mrbtris.o src/main.o src/game.o romdisk.o

# order here is important!
MRB_SOURCES=src/block_shapes.rb src/game.rb src/start_game.rb

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
	/vagrant/src/mruby-host/bin/mrbc -g -Bgame -o src/game.c $(MRB_SOURCES)

run: $(TARGET)
	$(KOS_LOADER) $(TARGET)

dist:
	rm -f $(OBJS) romdisk.o romdisk.img
	$(KOS_STRIP) $(TARGET)
