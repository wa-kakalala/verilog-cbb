
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: <zarubaf@iis.ee.ethz.ch>
//
// Description: Simple shift register for arbitrary depth and types

// only support: input data in the mode of one by one period
module shift_reg #(
    parameter int unsigned Width = 32'd32  , 
    parameter int unsigned Depth = 1
)(
    input  logic             clk_i  ,    
    input  logic             rst_ni ,   
    input  logic [Width-1:0] d_i    ,
    output logic [Width-1:0] d_o        
);

shift_reg_gated #(
    .Depth(Depth ),
    .Width(Width )
) shift_reg_gated_inst (
    .clk_i  (clk_i ),
    .rst_ni (rst_ni),
    .valid_i(1'b1  ),
    .data_i (d_i   ),
    .valid_o(      ),
    .data_o (d_o   )
);

endmodule