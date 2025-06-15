/*-----------------------------------------
file name  : bwdfwdpipe.v
created    : 2025/06/14 23:38:14
modified   : 2025-06-14 23:52:10
description: 
notes      : 
author     : yyrwkk
-----------------------------------------*/
module bwdfwdpipe # (
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

wire              m_valid_bwd;
wire [DWIDTH-1:0] m_data_bwd ;
wire              s_ready_fwd;

bwdpipe # (
    .DWIDTH ( DWIDTH ) 
) u_bwdpipe (
    .clk     (clk         ),  
    .rst_n   (rst_n       ),
           
    .s_valid (s_valid     ),
    .s_data  (s_data      ), 
    .s_ready (s_ready     ),
           
    .m_valid (m_valid_bwd ),
    .m_data  (m_data_bwd  ), 
    .m_ready (s_ready_fwd )
);

fwdpipe # (
    .DWIDTH ( DWIDTH )
) u_fwdpipe (
    .clk     (clk         ),  
    .rst_n   (rst_n       ),
           
    .s_valid (m_valid_bwd ),
    .s_data  (m_data_bwd  ), 
    .s_ready (s_ready_fwd ),
           
    .m_valid (m_valid     ),
    .m_data  (m_data      ), 
    .m_ready (m_ready     )
);

endmodule
