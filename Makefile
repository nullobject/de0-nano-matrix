.PHONY: mif program clean

build:
	quartus_sh --flow compile matrix

mif:
	quartus_cdb --update_mif matrix
	quartus_asm matrix

program:
	quartus_pgm -m jtag -c 1 -o "p;output_files/matrix.sof@1"

clean:
	rm -rf db incremental_db output_files
