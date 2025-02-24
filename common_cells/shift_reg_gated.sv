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
// Description: A Simple shift register with ICG for arbitrary depth and types.

module shift_reg_gated # (
    parameter int unsigned Depth = 32'd8   , 
    parameter int unsigned Width = 32'd32      
) (
    input  logic              clk_i         ,   
    input  logic              rst_ni        ,   

    input  logic              valid_i       ,
    input  logic [Width-1:0]  data_i        ,
    output logic              valid_o       ,
    output logic [Width-1:0]  data_o   
);

generate 
    if (Depth == 0) begin : gen_pass_through
        assign valid_o = valid_i;
        assign data_o  = data_i;
     // It's a shift register if depth is greater than 0
    end else begin : gen_shift_reg
        logic [Depth-1 : 0]             valid_d, valid_q;
        logic [Depth-1 : 0] [Width-1:0] data_d , data_q ;
        genvar i;
        for (i = 0; i < Depth; i++) begin : gen_regs
            // Prepare D port for each shift register.
            if (i == 0) begin : gen_shift_in
                assign valid_d[i] = valid_i;
                assign data_d[i]  = data_i ;
            end else begin : gen_shift
                assign valid_d[i] = valid_q[i-1];
                assign data_d[i]  = data_q[i-1] ;
            end

            // shift valid flag without clock gate
            // `FF(valid_q[i], valid_d[i], '0, clk_i, rst_ni)
            gnrl_dffr #( 1 ) gnrl_dffr_inst( valid_d[i],valid_q[i],clk_i, rst_ni);

            // Gate each shift register with a valid flag to enable the synthsis tools to insert ICG for
            // better power comsumption.
            // `FFL(data_q[i], data_d[i], valid_d[i], dtype'('0), clk_i, rst_ni)
            gnrl_dfflr #( Width ) gnrl_dfflr_inst( valid_d[i],data_d[i],data_q[i],clk_i, rst_ni);
        end
  
        // Output the shifted result.
        assign valid_o = valid_q[Depth-1];
        assign data_o  = data_q [Depth-1];
    end
endgenerate

endmodule