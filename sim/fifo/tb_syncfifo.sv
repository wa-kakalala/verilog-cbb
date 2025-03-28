/**************************************
@ filename    : tb_syncfifo.sv
@ author      : yyrwkk
@ create time : 2025/03/28 15:47:47
@ version     : v1.0.0
**************************************/
`include "clk_rst_gen.sv"
module tb_syncfifo();

localparam        DATA_WIDTH    = 8            ; // 数据位宽, 可取1, 2, 3, ... , 默认为8
localparam        ADDR_WIDTH    = 4            ; // 地址位宽, 可取1, 2, 3, ... , 默认为4, 对应深度2**4
localparam        RAM_STYLE     = "distributed"; // RAM类型, 可选"block", "distributed"(默认)
localparam        TH_WR         = 1'b1         ; // the waterlevel of almost full
localparam        TH_RD         = 1'b1         ; // the waterlevel of almost empty
localparam [0:0] FWFT_EN        = 0            ;  // 首字直通特性使能, 默认为1, 表示使能首字直通, first-word fall-through

logic  [DATA_WIDTH-1:0]  din          ;
logic                    wr_en        ;
logic                    full         ;
logic                    almost_full  ;
logic  [DATA_WIDTH-1:0]  dout         ;
logic                    rd_en        ;
logic                    empty        ;
logic                    almost_empty ;
logic                    clk          ;
logic                    rst_n        ;        

syncfifo # (
    .DATA_WIDTH   (DATA_WIDTH),
    .ADDR_WIDTH   (ADDR_WIDTH),
    .RAM_STYLE    (RAM_STYLE ),
    .TH_WR        (TH_WR     ),
    .TH_RD        (TH_RD     ),
    .FWFT_EN      (FWFT_EN   )
)syncfifo_inst(
    .din          (din         ),
    .wr_en        (wr_en       ),
    .full         (full        ),
    .almost_full  (almost_full ),
    .dout         (dout        ),
    .rd_en        (rd_en       ),
    .empty        (empty       ),
    .almost_empty (almost_empty),
    .clk          (clk         ),
    .rst_n        (rst_n       )
);

real clk_freq  = 100;
`clk_gen( clk, 0, clk_freq, 0 , 0.5, 0, 0  )
`rst_gen( rst_n,0,0,$urandom_range(100,300))

initial begin 
    din   = 'b0;
    wr_en = 'b0;
    rd_en = 'b0;
end

initial begin
    @(posedge clk); 
    wait(rst_n == 1'b1);
    @(posedge clk); 
    for(int i=0;i<20;i = i+1) begin 
        wr_en <= 1'b1;
        din   <= i + 1;
        @(posedge clk);
    end
    wr_en <= 1'b0;
    repeat(5) @(posedge clk);
    for(int i=0;i<20;i = i+1) begin 
        rd_en <= 1'b1;
        @(posedge clk);
    end

    repeat(100) @(posedge clk);
    $finish;
end

initial begin 
    $dumpfile("syncfifo.vcd"); // 生成的vcd文件名称
    $dumpvars(0, tb_syncfifo); // tb模块名称
end



endmodule 