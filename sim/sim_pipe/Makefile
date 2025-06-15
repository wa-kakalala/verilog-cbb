test_dut ?= fwdpipe

create:
	vlib work
	vmap work work 
compile:
	vlog -work work +define+TEST_DUT=$(test_dut) -l compile_$(test_dut).log -f filelist.f 
run:
	vsim -work work +nowarnTSCALE -lib work -novopt -do run.do -c -l sim_$(test_dut).log tb_pipe 

clean:
	del /s *.log *.ini *.wlf transcript
	rmdir /s /q work

regress:
	vlog -work work +define+TEST_DUT=fwdpipe -l compile_fwdpipe.log -f filelist.f 
	vsim -work work +nowarnTSCALE -lib work -novopt -do run.do -c -l sim_fwdpipe.log tb_pipe 

	vlog -work work +define+TEST_DUT=bwdpipe -l compile_bwdpipe.log -f filelist.f 
	vsim -work work +nowarnTSCALE -lib work -novopt -do run.do -c -l sim_bwdpipe.log tb_pipe 

	vlog -work work +define+TEST_DUT=bwdfwdpipe -l compile_bwdfwdpipe.log -f filelist.f 
	vsim -work work +nowarnTSCALE -lib work -novopt -do run.do -c -l sim_bwdfwdpipe.log tb_pipe 

	

# add wave tb_pipe/*
# view structure
# view signals
# view wave
