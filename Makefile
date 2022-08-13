TARGET = mrbtris.bin

OBJS = src/mrbtris.o src/main.o src/game.o romdisk.o

# order here is important!
MRB_SOURCES=src/block_shapes.rb src/game.rb src/start_game.rb

MRB_BYTECODE = src/game.c

KOS_ROMDISK_DIR = romdisk

MRB_ROOT = /opt/mruby

CFLAGS = -I$(MRB_ROOT)/include/ -L$(MRB_ROOT)/build/dreamcast/lib/

all: rm-elf $(TARGET)

include $(KOS_BASE)/Makefile.rules

clean:
	-rm -f $(TARGET) $(OBJS) romdisk.* $(MRB_BYTECODE)

rm-elf:
	-rm -f $(TARGET) romdisk.*

$(TARGET): mrbtris.elf
	sh-elf-objcopy -R .stack -O binary mrbtris.elf mrbtris.bin

mrbtris.elf: $(OBJS) $(MRB_BYTECODE)
	kos-cc $(CFLAGS) -o $(TARGET) $(OBJS) -lmruby -lm

$(MRB_BYTECODE): src/start_game.rb src/game.rb
	$(MRB_ROOT)/bin/mrbc -g -Bgame -o src/game.c $(MRB_SOURCES)

run: $(TARGET)
	$(KOS_LOADER) $(TARGET)

dist:
	rm -f $(OBJS) romdisk.o romdisk.img
	$(KOS_STRIP) $(TARGET)
