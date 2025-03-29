/**************************************
@ filename    : tb_syncfifo_diffw.sv
@ author      : yyrwkk
@ create time : 2025/03/29 14:52:44
@ version     : v1.0.0
**************************************/
`include "clk_rst_gen.sv"
module tb_syncfifo_diffw();

parameter       DIN_WIDTH   = 16           ;
parameter       DOUT_WIDTH  = 8            ;
parameter       WADDR_WIDTH = 4            ;
parameter       RAM_STYLE   = "distributed";
parameter [0:0] FWFT_EN     = 1            ;
parameter [0:0] MSB_FIFO    = 0            ;

logic [DIN_WIDTH-1:0]  din         ;
logic                  wr_en       ;
logic                  full        ;
logic                  almost_full ;
logic [DOUT_WIDTH-1:0] dout        ;
logic                  rd_en       ;
logic                  empty       ;
logic                  almost_empty;
logic                  clk         ;
logic                  rst_n       ;

syncfifo_diffw # (
    .DIN_WIDTH   (DIN_WIDTH   ), // 输入数据位宽, 可取1, 2, 3, ... , 默认为8
    .DOUT_WIDTH  (DOUT_WIDTH  ), // 输出数据位宽, 可取1, 2, 3, ... , 默认为8
    .WADDR_WIDTH (WADDR_WIDTH ), // 写入地址位宽, 可取1, 2, 3, ... , 默认为4, 对应深度2**4
    .RAM_STYLE   (RAM_STYLE   ), // RAM类型, 可选"block", "distributed"(默认)
    .FWFT_EN     (FWFT_EN     ), // 首字直通特性使能, 默认为1, 表示使能首字直通
    .MSB_FIFO    (MSB_FIFO    )  // 1(默认)表示高位先进先出,同Vivado FIFO一致; 0表示低位先进先出
)syncfifo_diffw_inst(
    .din         (din         ),
    .wr_en       (wr_en       ),
    .full        (full        ),
    .almost_full (almost_full ),
    .dout        (dout        ),
    .rd_en       (rd_en       ),
    .empty       (empty       ),
    .almost_empty(almost_empty),
    .clk         (clk         ),
    .rst_n       (rst_n       )  
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
    for(int i=0;i<50;i = i+1) begin 
        rd_en <= 1'b1;
        @(posedge clk);
    end
    rd_en <= 1'b0;

    repeat(100) @(posedge clk);
    $finish;
end

initial begin 
    $dumpfile("syncfifo_diffw.vcd"); // 生成的vcd文件名称
    $dumpvars(0, tb_syncfifo_diffw); // tb模块名称
end



endmodule 