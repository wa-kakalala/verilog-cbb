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
 // ===========================================================================
//
// Description:
//  Verilog module for general latch 
//
// ===========================================================================

module gnrl_ltch # (
    parameter DW = 32
  ) (
    input               lden, 
    input      [DW-1:0] dnxt,
    output     [DW-1:0] qout
  );
  
  reg [DW-1:0] qout_r;
  
  always @(*) begin : LTCH_PROC
    if (lden == 1'b1)
      qout_r = dnxt;
  end
  
  assign qout = qout_r;
  
  `ifndef FPGA_SOURCE//{
  `ifndef DISABLE_SV_ASSERTION//{
  //synopsys translate_off
  always_comb
  begin
    CHECK_THE_X_VALUE:
      assert (lden !== 1'bx) 
      else $fatal ("\n Error: Oops, detected a X value!!! This should never happen. \n");
  end
  
  //synopsys translate_on
  `endif//}
  `endif//}
      
  
  endmodule
  