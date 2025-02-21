/**************************************
@ filename    : onehot_to_bin.sv
@ author      : yyrwkk
@ create time : 2025/02/21 15:25:04
@ version     : v1.0.0
**************************************/
module onehot_to_bin #(
    parameter  ONE_HOT_WIDTH    = 8     ,
    parameter  BIN_WIDTH        = (ONE_HOT_WIDTH == 1) ? 1: $clog2(ONE_HOT_WIDTH)
)(
    input        [ONE_HOT_WIDTH-1 : 0        ]   one_hot_code  ,
    output logic [BIN_WIDTH-1 : 0            ]   bin_code    
);

logic [BIN_WIDTH-1 : 0    ] temp1 [ONE_HOT_WIDTH-1 : 0 ];
logic [ONE_HOT_WIDTH-1 : 0] temp2 [BIN_WIDTH-1 : 0     ];
		
genvar i,j,k;
generate
    for(i = 0; i < ONE_HOT_WIDTH; i = i+1) begin : temp1_loop
        assign temp1[i] = one_hot_code[i]? BIN_WIDTH'(i):'b0;
    end
endgenerate

generate
    for(i = 0; i < ONE_HOT_WIDTH; i = i+1) begin : temp_ch1
        for(j = 0; j < BIN_WIDTH; j = j+1) begin : temp_ch2
            assign temp2[j][i] = temp1[i][j];
        end
    end
endgenerate

generate
    for(j = 0; j < BIN_WIDTH; j = j+1)begin : temp2_loop
        assign bin_code[j] = |temp2[j];
    end
endgenerate
	
endmodule