.PHONY: build rom program clean


rom/blink.bin: rom/blink.asm
	z80asm rom/blink.asm -o rom/blink.bin

rom/blink.mif: rom/blink.bin
	srec_cat rom/blink.bin -binary -o rom/blink.mif -mif -output_block_size=16

build: rom/blink.mif
	quartus_sh --flow compile matrix

rom: rom/blink.mif
	quartus_cdb --update_mif matrix
	quartus_asm matrix

program:
	quartus_pgm -m jtag -c 1 -o "p;output_files/matrix.sof@1"

clean:
	rm -rf db incremental_db output_files
