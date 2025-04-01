
TOP  := asyncfifo
FILE := 
INC  := 

INC  += -I ../../macros

FILE += tb_$(TOP).sv 
FILE += ../../e203_cbb/gnrl_dff/gnrl_dfflr.v
FILE += ../../e203_cbb/gnrl_dff/gnrl_dffr.v
FILE += ../../e203_cbb/gnrl_dff/gnrl_xchecker.sv
FILE += ../../common_cells/binary_to_gray.v
FILE += ../../common_cells/$(TOP).v


.PHONY: clean 
run: clean
	@iverilog -g2005-sv -gsupported-assertions -o $(TOP)  $(INC) $(FILE)
	@vvp -n $(TOP) 
	@gtkwave $(TOP).vcd

clean:
	@del $(TOP) $(TOP).vcd 
