//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : avr_brs.v
// Author        :
// Project       : 
// Create Date   : 2021.04.01
// Description   :
// - AVR Backward Register Slice，for timing;
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
// 
//==============================================================================

module avr_brs #(parameter DW='d256 )(
    input [DW-1:0]  m_data     ,
    input           m_valid    ,
    output          m_ready    ,
 
    output [DW-1:0] s_data     ,
    output          s_valid    ,
    input           s_ready    ,

    input           clk        ,
    input           rst_n
);

reg          valid_tmp0;
reg [DW-1:0] payload_tmp0;
reg          ready_d1;
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'd0)
        valid_tmp0 <= 1'd0;
    else if (m_valid == 1'd1 && s_ready == 1'd0 && valid_tmp0 == 1'd0)
        valid_tmp0 <= 1'd1;
    else if (s_ready == 1'd1)
        valid_tmp0 <= 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'd0)
        payload_tmp0 <= 'd0;
    else if (m_valid == 1'd1 && s_ready == 1'd0 && valid_tmp0 == 1'd0)
        payload_tmp0 <= m_data;
end

assign s_data = (valid_tmp0 == 1'd1) ? payload_tmp0 : m_data;

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'd0)
        ready_d1 <= 1'd0;
    else
        ready_d1 <= s_ready;
end

assign m_ready = ~valid_tmp0 | ready_d1;
assign s_valid = valid_tmp0 | m_valid;
endmodule
