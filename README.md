# mrbtris: Sample game for Sega Dreamcast written in Ruby

**mrbtris** is a simple game for the **Sega Dreamcast** which is written in **Ruby** as an proof-of-concept of using the [mruby](https://mruby.org/) implementation on the Sega Dreamcast. This project was written by @yujiyokoo.

This project is built on the top of [KallistiOS](https://en.wikipedia.org/wiki/KallistiOS) (KOS), which is the low-level library used to interact with the Sega Dreamcast hardware. Usually, programs written for the Sega Dreamcast are in **C/C++**, this project aims to demonstrate the use of Ruby source code targeting the Sega Dreamcast.

This project aims to provide a simple example of how to use **KallistiOS** (KOS) API and **mruby** together.

## Demonstration

Below you may find a video of this game running on the real hardware.
[![#mrbtris running on Sega Dreamcast](https://i.imgur.com/sU9gnJR.png)](https://vimeo.com/335686570)

## TODO

* Make an `mrbgem` for the Dreamcast specific things
* Create unit tests
* Use more Sega Dreamcast features

## Building

**mrbtris** uses [KallistiOS](http://gamedev.allusion.net/softprj/kos/) (KOS) and [mruby](https://mruby.org/) as dependencies. For building this program you have two options: 

* Using a working KallistiOS setup;
* Use the provided Docker image below.

### Using your working KallistiOS environment

If you have a working [KallistiOS](http://gamedev.allusion.net/softprj/kos/) environment, you will have to install the `rake` and `bison` packages (e.g. using `apt`, `brew` or `pacman`). If you are using [DreamSDK](https://dreamsdk.org), you will have to install the [RubyInstaller](https://rubyinstaller.org/) package separately, in that case, `rake` should be available in the `PATH` environment variable.

Install  `mruby`:

	cd /opt
	git clone https://github.com/mruby/mruby.git
	cd /opt/mruby
	cp examples/targets/build_config_dreamcast_shelf.rb build_config.rb
	make

These commands will produces all the necessary files for using **mruby** on Sega Dreamcast. After that, just navigate to the `mrbtris` directory then enter `make`. This will produces the `mrbtris.elf` binary file.

**Note:** You may consult [this page](https://dreamcast.wiki/Using_Ruby_for_Sega_Dreamcast_development) for reference.

### Using Docker image

The Docker image is named [mruby-kos-dc](https://hub.docker.com/r/yujiyokoo/mruby-kos-dc) which is built from [docker-mruby-kos-dc](https://gitlab.com/yujiyokoo/docker-mruby-kos-dc). The instruction to input are:

	git clone https://gitlab.com/yujiyokoo/mrbtris-dreamcast.git
	cd mrbtris-dreamcast
	docker pull yujiyokoo/mruby-kos-dc
	docker run -i -t -v $(pwd):/mnt yujiyokoo/mruby-kos-dc bash -c 'cd /mnt && . /opt/toolchains/dc/kos/environ.sh && make'

This should produce an `elf` binary called `mrbtris.elf`.

## Running

### Dreamcast emulator: Lxdream

To check that it at least runs, you can use Dreamcast emulators. In my experience, **lxdream** can boot `elf` and seems to work well enough to check it runs, but text display doesn't seems to render properly. You could still check that it boots up even without text. To do that, run `lxdream -e mrbtris.elf` or `lxdream mrbtris.elf`, depending on your lxdream version, from your Terminal.

Unfortunately, running on the real hardware has been the only way for me to test text display and actual performance, but it may be different in your environment.

### Making a bootable image

If you want to try this software in your real Dreamcast and/or in an another emulator (like [Demul, Redream, Reicast](https://dreamcast.wiki/Dreamcast_emulators)...), you may create a **Padus DiscJuggler** (`cdi`) image. For example, if you are using [DreamSDK](https://dreamsdk.org), you may do the following:

	make dist
	elf2bin mrbtris.elf
	scramble mrbtris.bin cd_root/1ST_READ.BIN
	makedisc mrbtris.cdi cd_root

This will produces the `mrbtris.cdi` image file that you may burn onto a CD-R or use in a Dreamcast emulator. Alternatively, you may use [BootDreams](https://dcemulation.org/index.php?title=BootDreams) (on Windows) or similar tools. If you are on non-Windows systems, you may check the [img4dc source code](https://github.com/Kazade/img4dc).

### Using dcload/dc-tool (part of KallistiOS)

If you have a [Coders Cable](https://dreamcast.wiki/Coder%27s_cable) or a [Broadband Adapter](https://dreamcast.wiki/Broadband_adapter) (BBA) / [LAN Adapter](https://dreamcast.wiki/LAN_adapter), you could also the `dcload` program (part of **KallistiOS**) to load it directly on the Sega Dreamcast. It should load as a normal Sega Dreamcast program.

