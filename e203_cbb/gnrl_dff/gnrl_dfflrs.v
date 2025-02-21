 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  All of the general DFF and Latch modules
//
// ====================================================================

//

// ===========================================================================
//
// Description:
//  Verilog module sirv_gnrl DFF with Load-enable and Reset
//  Default reset value is 1
//
// ===========================================================================

 module gnrl_dfflrs # (
    parameter DW = 32
  ) (
  
    input               lden, 
    input      [DW-1:0] dnxt,
    output     [DW-1:0] qout,
  
    input               clk,
    input               rst_n
  );
  
  reg [DW-1:0] qout_r;
  
  always @(posedge clk or negedge rst_n) begin : DFFLRS_PROC
    if (rst_n == 1'b0)
      qout_r <= {DW{1'b1}};
    else if (lden == 1'b1)
      qout_r <= dnxt;
  end
  
  assign qout = qout_r;
  

  `ifndef VERILATOR
    // pragma translate_off
    gnrl_xchecker # (
    .DW(1)
  ) sirv_gnrl_xchecker(
    .i_dat(lden),
    .clk  (clk)
  );
`endif

  
      
  
  endmodule