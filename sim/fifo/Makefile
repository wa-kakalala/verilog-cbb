
.PHONY: syncfifo clean 
syncfifo: clean
	@iverilog -g2005-sv -o syncfifo -gsupported-assertions                         \
		-I ../../macros tb_syncfifo.sv            \
	    ../../common_cells/syncfifo.v             \
		../../e203_cbb/gnrl_dff/gnrl_xchecker.sv  \
		../../e203_cbb/gnrl_dff/gnrl_dfflr.v
	@vvp -n syncfifo
	@gtkwave syncfifo.vcd

clean:
	@del syncfifo syncfifo.vcd 
