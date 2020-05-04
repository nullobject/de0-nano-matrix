.PHONY: build rom program clean


output_files/blink.bin: src/blink.asm
	mkdir -p output_files
	z80asm src/blink.asm -o output_files/blink.bin

rom/blink.mif: output_files/blink.bin
	mkdir -p rom
	srec_cat output_files/blink.bin -binary -o rom/blink.mif -mif -output_block_size=16

build: rom/blink.mif
	quartus_sh --flow compile matrix

rom: rom/blink.mif
	quartus_cdb --update_mif matrix
	quartus_asm matrix

program:
	quartus_pgm -m jtag -c 1 -o "p;output_files/matrix.sof@1"

clean:
	rm -rf db incremental_db output_files
