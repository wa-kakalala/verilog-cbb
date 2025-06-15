/*-----------------------------------------
file name  : bwdpipe.v
created    : 2025/06/14 22:59:39
modified   : 2025-06-14 23:55:29
description: 
notes      : 
author     : yyrwkk
-----------------------------------------*/
module bwdpipe # (
    parameter DWIDTH = 32 
)(
    input               clk     ,
    input               rst_n   ,

    input               s_valid ,
    input  [DWIDTH-1:0] s_data  ,
    output              s_ready ,

    output              m_valid ,
    output [DWIDTH-1:0] m_data  ,
    input               m_ready  
);

reg              full ;
reg [DWIDTH-1:0] s_data_reg;
assign m_valid = full | (s_valid & s_ready); // actually the s_ready is an implict condition
assign s_ready = ~full;
always @(posedge clk or negedge rst_n ) begin 
    if( !rst_n ) begin 
        full <= 1'b0;
    end else begin 
        full <= m_valid & ( ~m_ready );
    end
end 

// other method 
// always @(posedge clk or negedge rst_n ) begin 
//     if( !rst_n ) begin 
//         full <= 1'b0;
//     end else if( m_ready ) begin 
//         full <= 1'b0;
//     end else if( s_valid & s_ready & ( ~m_ready ) ) begin 
//         full <= 1'b1;
//     end
// end 
// 
// always@(posedge clk or negedge rst_n ) begin 
//     if( !rst_n ) begin 
//         s_ready <= 1'b1;
//     end else if( m_ready ) begin 
//         s_ready <= 1'b1;
//     end else if( s_valid ) begin // actually, the condition is s_valid & s_ready & ( !m_ready ) 
//         s_ready <= 1'b0;
//     end
// end 
// 
// assign m_valid = m_ready ? s_valid : full;

always @( posedge clk ) begin 
    if( s_valid & s_ready & (~m_ready )) begin 
        s_data_reg <= s_data; 
    end
end 

assign m_data = full ? s_data_reg : s_data;

endmodule
