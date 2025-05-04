//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : avr_frs.v
// Author        :
// Project       : 
// Create Date   : 2021.04.01
// Description   :
// - AVR Forward Register Slice，for timing;
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
// 
//==============================================================================

module avr_frs #(parameter DW='d256)(
    input       [DW-1:0]  m_data  ,
    input                 m_valid ,
    output                m_ready ,
 
    output  reg [DW-1:0]  s_data  ,
    output  reg           s_valid ,
    input                 s_ready ,

    input                 clk     ,
    input                 rst_n
    );
//============== Forward Registered ========
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'd0)
        s_valid <= 1'd0;
    else if (m_valid == 1'd1)
        s_valid <= 1'd1;
    else if (s_ready == 1'd1)
        s_valid <= 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'd0)
        s_data <= 'd0;
    else if (m_valid == 1'd1 && m_ready == 1'd1)
        s_data <= m_data;
end

assign m_ready = (~s_valid) | s_ready;
endmodule
