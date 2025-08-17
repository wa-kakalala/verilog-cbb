/************************************
@ filename   : fixed_prior_arbitor.v
@ author     : yyrwkk
@ create time: 2025/08/17 23:18:04
@ version    : v1.0.0
************************************/
module fixed_prior_arbitor # (
    parameter NUM = 16 
)(
    input  [NUM-1:0] req    ,
    output [NUM-1:0] grant  
);

wire [NUM-1:0] req_temp ;
genvar i;
generate 
    for( i = 0;i<NUM;i=i+1 ) begin : loop
        if( i == 0 ) begin 
            assign req_temp[i] = req[0];
            assign grant[i]    = req[0];
        end else begin 
            assign req_temp[i] = req[i] | req_temp[i-1];
            assign grant[i]    = req[i] & (~req_temp[i-1]);
        end
    end
endgenerate 

endmodule 