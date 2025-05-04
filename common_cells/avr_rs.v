//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : avr_rs.v
// Author        :
// Project       : 
// Create Date   : 2021.04.01
// Description   :
// - AVR Register Slice，for timing;
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
// 
//==============================================================================

module avr_rs #(parameter DW='d256)(
    input [DW-1:0]  m_data  ,
    input           m_valid ,
    output          m_ready ,
 
    output [DW-1:0] s_data  ,
    output          s_valid ,
    input           s_ready ,

    input clk               ,
    input rst_n
    );
wire [DW-1:0] s_data_frs              ;
wire          s_valid_frs,s_ready_frs ;

    avr_frs #(.DW(DW))u_avr_frs(
    .m_data     ( m_data      ),
    .m_valid    ( m_valid     ),
    .m_ready    ( m_ready     ),
 
    .s_data     ( s_data_frs  ),
    .s_valid    ( s_valid_frs ),
    .s_ready    ( s_ready_frs ),
 
    .clk        ( clk         ),
    .rst_n      ( rst_n       )
    );  

    avr_brs #(.DW(DW))u_avr_brs(
    .m_data     ( s_data_frs  ),
    .m_valid    ( s_valid_frs ),
    .m_ready    ( s_ready_frs ),

    .s_data     ( s_data      ),
    .s_valid    ( s_valid     ),
    .s_ready    ( s_ready     ),

    .clk        ( clk         ),
    .rst_n      ( rst_n       )
    );  

endmodule