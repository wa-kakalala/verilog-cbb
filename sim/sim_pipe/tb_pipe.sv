/**************************************
@ filename    : tb_pipe.sv
@ author      : yyrwkk
@ create time : 2025/06/15 19:46:20
@ version     : v1.0.0
**************************************/
`timescale 1ns/1ns
import print_pkg::*;
module tb_pipe();
`define DATA_NUM 1000

parameter DWIDTH = 32;


logic              s_valid;
logic [DWIDTH-1:0] s_data ;
logic              s_ready;

logic              m_valid;
logic [DWIDTH-1:0] m_data ;
logic              m_ready;

logic clk  ;
logic rst_n;

initial begin 
    s_valid = 'b0;
    s_data  = 'b0;
    m_ready = 'b0;
    clk     = 'b0;
    rst_n   = 'b0; // reset
end

initial begin 
    forever begin 
        #5; 
        clk = ~clk;
    end
end

bit [DWIDTH-1:0] act_queue[$];
bit [DWIDTH-1:0] exp_queue[$];

function automatic void compare(bit [DWIDTH-1:0] act_queue[$],bit [DWIDTH-1:0] exp_queue[$]);
    bit dis_match = 0;
    if(act_queue.size() !=  exp_queue.size() ) begin 
        $display("size dismatch!");
        $display("act size: %d, exp size: %d",act_queue.size(),exp_queue.size());
        return;
    end else begin 
        $display("data len:%d",act_queue.size());
    end
    foreach( act_queue[i] ) begin 
        if( act_queue[i] != exp_queue[i] ) begin 
            $display("idx:%d -> d0:v %d, d1:v %d,value dismatch!",i,act_queue[i],exp_queue[i]);
            dis_match = 1;
        end
    end
    if( dis_match ) begin 
        show_fail();
    end else begin 
        show_pass();
    end
endfunction 

initial begin 
    forever begin 
        repeat( $urandom_range(2,10)) @(posedge clk);
        m_ready <= 'b1;
        repeat( $urandom_range(2,10)) @(posedge clk);
        m_ready <= 'b0;
    end
end

initial begin 
    #($urandom_range(500,1000));
    rst_n = 1'b1;
end

int temp_data;
initial begin 
    @(posedge clk iff (rst_n));
    for( int i=0;i<`DATA_NUM;i++ ) begin 
        s_valid <= 1'b1;
        temp_data = $urandom_range(0,2000);
        exp_queue.push_back(temp_data);
        s_data  <= temp_data;
        @(posedge clk iff (s_ready));
        temp_data = $urandom_range(0,10);
        if( temp_data != 0 ) begin 
            s_valid <= 1'b0;
            s_data  <= 'b0;
            repeat(temp_data) @(posedge clk);
        end
    end
end

initial begin 
    @(posedge clk iff (rst_n));
    for( int i=0;i<`DATA_NUM;i++ ) begin 
        @(posedge clk iff( m_ready & m_valid));
        act_queue.push_back(m_data);
    end
    compare(act_queue,exp_queue);
    $finish;
end
 
`define TEST_DUT fwdpipe
`define INST_NAME u_``TEST_DUT
// TEST_DUT macro from cmd
`TEST_DUT # ( 
    .DWIDTH ( DWIDTH )
)INST_NAME(
    .clk     (clk     ),
    .rst_n   (rst_n   ),
    .s_valid (s_valid ),
    .s_data  (s_data  ),
    .s_ready (s_ready ),
    .m_valid (m_valid ),
    .m_data  (m_data  ),
    .m_ready (m_ready ) 
);

endmodule