/**************************************
@ filename     : asyncfifo.v
@ origin author: xu xiaokang
@ update by    : yyrwkk
@ create time  : 2025/04/01 17:20:01
@ version      : v1.0.0
**************************************/

/** 异步FIFO
 * 1.在判断写满与读空信号时，需要转换时钟域，为此先将读写指针转换为格雷码，减小亚稳态发生的概率
 * 2.开辟一个寄存器组作为RAM实现数据存储
 */
module asyncfifo # (
    parameter       DATA_WIDTH = 8            , // 数据位宽, 可取1, 2, 3, ... , 默认为8
    parameter       ADDR_WIDTH = 4            , // 地址位宽, 可取1, 2, 3, ... , 默认为4, 对应深度2**4
    parameter       RAM_STYLE  = "distributed", // RAM类型, 可选"block", "distributed"(默认)
    parameter       TH_WR      = 1'b1         , // the waterlevel of almost full
    parameter       TH_RD      = 1'b1         , // the waterlevel of almost empty
    parameter [0:0] FWFT_EN    = 1              // 首字直通特性使能, 默认为1, 表示使能首字直通
)(
    input  [DATA_WIDTH-1:0] din         ,
    input                   wr_en       ,
    output                  full        ,
    output                  almost_full ,
    input                   wr_clk      ,
    input                   wr_rst_n    ,

    output [DATA_WIDTH-1:0] dout        ,
    input                   rd_en       ,
    output                  empty       , 
    output                  almost_empty,
    input                   rd_clk      ,
    input                   rd_rst_n
);

//++ 生成读写指针 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// reg  [ADDR_WIDTH:0] rptr_bin;
// always @(posedge rd_clk or posedge rd_rst_n) begin
//     if (~rd_rst_n)
//         rptr_bin <= 0;
//     else if (rd_en & ~empty)
//         rptr_bin <= rptr_bin + 1'b1;
// end

// read ptr in binary mode
wire [ADDR_WIDTH + 1 -1 :0] rptr_bin    ;
wire [ADDR_WIDTH + 1 -1 :0] rptr_bin_nxt;
wire                        rptr_bin_ld ;
assign rptr_bin_ld = rd_en & ( ~ empty );
assign rptr_bin_nxt= rptr_bin + 1'b1;
gnrl_dfflr #(ADDR_WIDTH + 1) gnrl_dfflr_rptr_bin (rptr_bin_ld,rptr_bin_nxt,rptr_bin,rd_clk, rd_rst_n);

// reg  [ADDR_WIDTH:0] wptr_bin;
// always @(posedge wr_clk or posedge wr_rst_n) begin
//     if (~wr_rst_n)
//         wptr_bin <= 0;
//     else if (wr_en & ~full)
//         wptr_bin <= wptr_bin + 1'b1;
// end

// write ptr in binary mode
wire [ADDR_WIDTH + 1 -1 : 0] wptr_bin    ;
wire [ADDR_WIDTH + 1 -1 : 0] wptr_bin_nxt;
wire                         wptr_bin_ld ;
assign wptr_bin_ld = wr_en & ( ~ full );
assign wptr_bin_nxt= wptr_bin + 1'b1;
gnrl_dfflr #(ADDR_WIDTH + 1) gnrl_dfflr_wptr_bin (wptr_bin_ld,wptr_bin_nxt,wptr_bin,wr_clk, wr_rst_n);


wire [ADDR_WIDTH-1:0] raddr ; 
wire [ADDR_WIDTH-1:0] waddr ; 
assign raddr = rptr_bin[ADDR_WIDTH-1:0];
assign waddr = wptr_bin[ADDR_WIDTH-1:0];

wire [ADDR_WIDTH + 1 -1 : 0] wptr_bin_almost_full    ;
wire [ADDR_WIDTH + 1 -1 : 0] rptr_bin_almost_empty   ;
assign wptr_bin_almost_full  = wptr_bin + TH_WR;
assign rptr_bin_almost_empty = rptr_bin + TH_RD;
//-- 生成读写指针 ------------------------------------------------------------

//++ 二进制编码转换为格雷码 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ADDR_WIDTH:0] rptr_gray   ; 
wire [ADDR_WIDTH:0] rptr_gray_almost_empty; 

binary_to_gray #(ADDR_WIDTH +1) binary_to_gray_rptr(rptr_bin,rptr_gray);
binary_to_gray #(ADDR_WIDTH +1) binary_to_gray_rptr_almost_empty(rptr_bin_almost_empty, rptr_gray_almost_empty);

// assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;
// assign rptr_gray_almost_empty = ((rptr_bin + 1'b1) >> 1) ^ (rptr_bin + 1'b1);

wire [ADDR_WIDTH:0] wptr_gray   ; 
wire [ADDR_WIDTH:0] wptr_gray_almost_full; 

binary_to_gray #(ADDR_WIDTH +1) binary_to_gray_wptr(wptr_bin,wptr_gray);
binary_to_gray #(ADDR_WIDTH +1) binary_to_gray_wptr_almost_full(wptr_bin_almost_full, wptr_gray_almost_full);

// wire [ADDR_WIDTH:0] wptr_gray = (wptr_bin >> 1) ^ wptr_bin;
// wire [ADDR_WIDTH:0] wptr_gray_p1 = ((wptr_bin + 1'b1) >> 1) ^ (wptr_bin + 1'b1);
//-- 二进制编码转换为格雷码 ------------------------------------------------------------


//++ 格雷码的读写指针同步 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ADDR_WIDTH:0] rptr_gray_wr_clk_r1;
wire [ADDR_WIDTH:0] rptr_gray_wr_clk_r2;
// always @(posedge wr_clk or posedge wr_rst) begin
//   if (wr_rst) begin
//     rptr_gray_wr_clk_r1 <= 0;
//     rptr_gray_wr_clk_r2 <= 0;
//   end
//   else begin
//     rptr_gray_wr_clk_r1 <= rptr_gray;
//     rptr_gray_wr_clk_r2 <= rptr_gray_wr_clk_r1;
//   end
// end
gnrl_dffr #( ADDR_WIDTH + 1) gnrl_dffr_rptr2wrclk_0 (rptr_gray,rptr_gray_wr_clk_r1,wr_clk,wr_rst_n );
gnrl_dffr #( ADDR_WIDTH + 1) gnrl_dffr_rptr2wrclk_1 (rptr_gray_wr_clk_r1,rptr_gray_wr_clk_r2,wr_clk,wr_rst_n );

wire [ADDR_WIDTH:0] wptr_gray_rd_clk_r1;
wire [ADDR_WIDTH:0] wptr_gray_rd_clk_r2;
// always @(posedge rd_clk or posedge rd_rst) begin
//     if (rd_rst) begin
//         wptr_gray_rd_clk_r1 <= 0;
//         wptr_gray_rd_clk_r2 <= 0;
//     end
//     else begin
//         wptr_gray_rd_clk_r1 <= wptr_gray;
//         wptr_gray_rd_clk_r2 <= wptr_gray_rd_clk_r1;
//     end
// end

gnrl_dffr #( ADDR_WIDTH + 1) gnrl_dffr_wptr2rdclk_0 (wptr_gray,wptr_gray_rd_clk_r1,rd_clk,rd_rst_n );
gnrl_dffr #( ADDR_WIDTH + 1) gnrl_dffr_wptr2rdclk_1 (wptr_gray_rd_clk_r1,wptr_gray_rd_clk_r2,rd_clk,rd_rst_n );

//-- 格雷码的读写指针同步 ------------------------------------------------------------

//++ 生成empty与almost_empty信号 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// always @(*) begin
//   if (rd_rst)
//     empty <= 1'b1;
//   else if (rptr_gray == wptr_gray_rd_clk_r2)
//     empty <= 1'b1;
//   else
//     empty <= 1'b0;
// end
assign empty = ( ( rptr_gray == wptr_gray_rd_clk_r2 ) ) ? 1'b1 : 1'b0;

// always @(*) begin
//   if (rd_rst)
//     almost_empty <= 1'b1;
//   else if (rptr_gray_p1 == wptr_gray_rd_clk_r2 || empty)
//     almost_empty <= 1'b1;
//   else
//     almost_empty <= 1'b0;
// end
assign almost_empty = ( ( ~rd_rst_n ) || ( rptr_gray_almost_empty == wptr_gray_rd_clk_r2 ) || empty ) ? 1'b1 : 1'b0;
//-- 生成empty与almost_empty信号 ------------------------------------------------------------


//++ 生成full与almost_full信号 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
generate
if (ADDR_WIDTH == 1) begin
    /* FIFO地址位宽为1时, 读写指针位宽为2, 只有以下四种情况:
        二进制编码 | 格雷码
        00       | 00
        01       | 01
        10       | 11
        11       | 10
        FIFO full的判断条件为写指针二进制编码比读指针二进制编码领先一圈, 即最高位不同, 其余位相同
        如二进制: 写指针00, 读指针10; 写指针01, 读指针11; 写指针10, 读指针00; 写指针11, 读指针01
        等价到格雷码: 写指针00, 读指针11; 写指针01, 读指针10; 写指针11, 读指针00; 写指针10, 读指针01
        归纳为: 格雷码各位均不同, 此时FIFO满
    */
    // always @(*) begin
    //     if (wr_rst)
    //     full  <= 1'b1;
    //     else if ((wptr_gray[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH])
    //             && (wptr_gray[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1])
    //             )
    //     full  <= 1'b1;
    //     else
    //     full  <= 1'b0;
    // end
    assign full = ( (wptr_gray[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH]    )  
                    &&  
                    (wptr_gray[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1]) 
                  ) ? 1'b1 : 1'b0; 

    assign almost_full = ( (wptr_gray_almost_full[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH])
                           && 
                           (wptr_gray_almost_full[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1])
                           && 
                           full
                         ) ? 1'b1: 1'b0;

    // always @(*) begin
    //     if (wr_rst)
    //         almost_full <= 1'b1;
    //     else if (((wptr_gray_p1[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH])
    //             && (wptr_gray_p1[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1])
    //             )
    //             || full
    //             )
    //         almost_full <= 1'b1;
    //     else
    //         almost_full <= 1'b0;
    // end
end else begin
    // always @(*) begin
    //     if (wr_rst)
    //     full  <= 1'b1;
    //     else if ((wptr_gray[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH])
    //             && (wptr_gray[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1])
    //             && (wptr_gray[ADDR_WIDTH-2:0] == rptr_gray_wr_clk_r2[ADDR_WIDTH-2:0])
    //             )
    //     full  <= 1'b1;
    //     else
    //     full  <= 1'b0;
    // end
    assign full = ( (wptr_gray[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH]        ) 
                    && 
                    (wptr_gray[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1]    )
                    &&
                    (wptr_gray[ADDR_WIDTH-2:0] == rptr_gray_wr_clk_r2[ADDR_WIDTH-2:0])
                  ) ? 1'b1 : 1'b0;

//   always @(*) begin
//     if (wr_rst)
//       almost_full <= 1'b1;
//     else if (((wptr_gray_p1[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH])
//               && (wptr_gray_p1[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1])
//               && (wptr_gray_p1[ADDR_WIDTH-2:0] == rptr_gray_wr_clk_r2[ADDR_WIDTH-2:0])
//               )
//             || full
//             )
//       almost_full <= 1'b1;
//     else
//       almost_full <= 1'b0;
//   end
    assign almost_full = (  (wptr_gray_almost_full[ADDR_WIDTH] != rptr_gray_wr_clk_r2[ADDR_WIDTH]        ) 
                            && 
                            (wptr_gray_almost_full[ADDR_WIDTH-1] != rptr_gray_wr_clk_r2[ADDR_WIDTH-1]    )
                            &&
                            (wptr_gray_almost_full[ADDR_WIDTH-2:0] == rptr_gray_wr_clk_r2[ADDR_WIDTH-2:0])
                         ) ? 1'b1 : 1'b0;
end
endgenerate
//-- 生成full与almost_full信号 ------------------------------------------------------------


//++ 寄存器组定义与读写 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
localparam DEPTH = 1 << ADDR_WIDTH; // 等价于 2**ADDR_WIDTH
(* ram_style = RAM_STYLE *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge wr_clk) begin
    if (wr_en && ~full) begin 
        mem[waddr] <= din;
    end
end

generate
    if (FWFT_EN == 1) begin
        // Vivado FIFO在FIFO为空时, dout保持最后一个有效值, 为实现这一特性, 采用了下方的写法
        reg [DATA_WIDTH-1:0] dout_old;
        always @(posedge rd_clk) begin
            if (rd_en && ~empty) begin 
                dout_old <= mem[raddr]; // 存储上一个值
            end
        end

        // reg [DATA_WIDTH-1:0] dout_r;
        // always @(*) begin
        //     if (~empty)
        //         dout_r <= mem[raddr];
        //     else
        //         dout_r <= dout_old;
        // end

        // assign dout = dout_r;
        assign dout = ( ~empty ) ? mem[raddr] : dout_old;
    end
    else begin
        reg [DATA_WIDTH-1:0] dout_r;
        always @(posedge rd_clk) begin
            if (rd_en && ~empty) begin 
                dout_r <= mem[raddr];
            end
        end

        assign dout = dout_r;
    end
endgenerate
//-- 寄存器组定义与读写 ------------------------------------------------------------

endmodule