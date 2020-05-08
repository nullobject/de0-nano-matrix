.PHONY: build rom program clean

# Don't delete intermediate bin files.
.PRECIOUS: %.bin

%.bin: %.asm
	z80asm -I rom -o $@ $<

%.mif: %.bin
	srec_cat $< -binary -o $@ -mif -output_block_size=16

build: rom/blink.mif
	quartus_sh --flow compile matrix

program:
	quartus_pgm -m jtag -c 1 -o "p;output_files/matrix.sof@1"

clean:
	rm -rf db incremental_db output_files rom/*.bin

blink: rom/blink.mif
	cp $< rom/prog_rom.mif
	quartus_cdb --update_mif matrix
	quartus_asm matrix

leds: rom/leds.mif
	cp $< rom/prog_rom.mif
	quartus_cdb --update_mif matrix
	quartus_asm matrix

tiles: rom/tiles.mif rom/tiles.hex
	cp $< rom/prog_rom.mif
	quartus_cdb --update_mif matrix
	quartus_asm matrix
