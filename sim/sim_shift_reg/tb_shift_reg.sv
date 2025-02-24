module tb_shift_reg();
parameter int unsigned Width = 32'd32  ;
parameter int unsigned Depth = 8       ;

logic             clk_i  ;
logic             rst_ni ;
logic [Width-1:0] d_i    ;
logic [Width-1:0] d_o    ;

shift_reg #(
    .Width(Width)   ,
    .Depth(Depth)
)shift_reg_inst(
    .clk_i  (clk_i ),    
    .rst_ni (rst_ni),   
    .d_i    (d_i   ),
    .d_o    (d_o   )    
);

initial begin 
    clk_i  = 'b0;
    rst_ni = 'b0;
    d_i    = 'b0;
end 

initial begin 
    forever #5 clk_i = ~ clk_i;
end

initial begin 
    @(posedge clk_i);
    rst_ni <= 1'b1;
    @(posedge clk_i);

    for( int i=0;i<8;i++) begin 
        d_i <= Width'(i+1);
        @(posedge clk_i);
    end
    d_i <= Width'(0);
    repeat(10) @(posedge clk_i);
    for( int i=0;i<8;i++) begin 
        d_i <= Width'(i+1);
        @(posedge clk_i);
    end
    d_i <= Width'(0);
    repeat(10) @(posedge clk_i);

    $stop;
end


endmodule  