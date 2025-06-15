/*-----------------------------------------
file name  : fwdpipe.v
created    : 2025/06/13 20:00:54
modified   : 2025-06-14 23:13:15
description: forward pipeline
notes      : 
author     : yyrwkk
-----------------------------------------*/
module fwdpipe # (
    parameter DWIDTH = 32 
)(
    input                   clk     ,
    input                   rst_n   ,

    input                   s_valid ,
    input      [DWIDTH-1:0] s_data  ,
    output                  s_ready ,
   
    output reg              m_valid ,
    output reg [DWIDTH-1:0] m_data  ,
    input                   m_ready 
);

assign s_ready = (~m_valid) | m_ready;

always@(posedge clk or negedge rst_n) begin 
    if( !rst_n ) begin 
        m_valid <= 1'b0;
    end else begin 
        m_valid <= s_valid | ( ~m_ready & m_valid ); 
    end
end 

// other method 
// always@(posedge clk or negedge rst_n ) begin 
//     if( !rst_n ) begin 
//         m_valid <= 1'b0;
//     end else if( m_ready ) begin 
//         m_valid <= s_valid;
//     end
// end

always@(posedge clk) begin 
    if( s_valid & s_ready ) begin 
        m_data <= s_data;
    end
end 

endmodule
