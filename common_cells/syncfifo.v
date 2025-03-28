/**************************************
@ filename     : syncfifo.v
@ origin author: xu xiaokang
@ update by    : yyrwkk
@ create time  : 2025/03/28 14:38:08
@ version      : v1.0.0
**************************************/
module syncfifo # (
    parameter       DATA_WIDTH    = 8            , // 数据位宽, 可取1, 2, 3, ... , 默认为8
    parameter       ADDR_WIDTH    = 4            , // 地址位宽, 可取1, 2, 3, ... , 默认为4, 对应深度2**4
    parameter       RAM_STYLE     = "distributed", // RAM类型, 可选"block", "distributed"(默认)
    parameter       TH_WR         = 1'b1         , // the waterlevel of almost full
    parameter       TH_RD         = 1'b1         , // the waterlevel of almost empty
    parameter [0:0] FWFT_EN       = 1              // 首字直通特性使能, 默认为1, 表示使能首字直通, first-word fall-through
)(
    input   [DATA_WIDTH-1:0]  din          ,
    input                     wr_en        ,
    output                    full         ,
    output                    almost_full  ,
    
    output  [DATA_WIDTH-1:0]  dout         ,
    input                     rd_en        ,
    output                    empty        ,
    output                    almost_empty ,
    
    input                     clk          ,
    input                     rst_n
);

//++ 生成读写指针 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// reg  [ADDR_WIDTH-1+1 : 0] rptr;
// always @(posedge clk or negedge rst_n) begin
//     if( !rst_n ) begin 
//         rptr <= 'b0;
//     end else if (rd_en & ~empty) begin 
//         rptr <= rptr + 1'b1;
//     end
// end
wire [ADDR_WIDTH-1+1 : 0] rptr     ;
wire [ADDR_WIDTH-1+1 : 0] rptr_nxt ;
wire                      rptr_ld  ;
assign rptr_nxt = rptr + 1'b1      ;
assign rptr_ld  = rd_en & (~empty) ;
gnrl_dfflr #(ADDR_WIDTH + 1) gnrl_dfflr_rptr(rptr_ld,rptr_nxt,rptr,clk,rst_n);

wire [ADDR_WIDTH-1+1 : 0] wptr     ;
wire [ADDR_WIDTH-1+1 : 0] wptr_nxt ;
wire                      wptr_ld  ;
assign wptr_nxt = wptr + 1'b1      ;
assign wptr_ld  = wr_en & (~full)  ;
gnrl_dfflr #(ADDR_WIDTH + 1) gnrl_dfflr_wptr(wptr_ld,wptr_nxt,wptr,clk,rst_n);

// reg  [ADDR_WIDTH-1+1 : 0] wptr;
// always @(posedge clk or negedge rst_n) begin
//   if( !rst_n ) begin
//     wptr <= 0;
//   end else if (wr_en & ~full) begin 
//     wptr <= wptr + 1'b1;
//   end
// end

wire [ADDR_WIDTH-1:0] raddr ;
wire [ADDR_WIDTH-1:0] waddr ;
assign raddr = rptr[ADDR_WIDTH-1:0];
assign waddr = wptr[ADDR_WIDTH-1:0];

wire [ADDR_WIDTH:0] rptr_almost_empty = rptr + TH_RD;
wire [ADDR_WIDTH:0] wptr_almost_full  = wptr + TH_WR;
//-- 生成读写指针 ------------------------------------------------------------

//++ 生成empty与almost_empty信号 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// always @(*) begin
//     if (~ rst_n)
//         empty = 1'b1;
//     else if (rptr == wptr)
//         empty = 1'b1;
//     else
//         empty = 1'b0;
// end
assign empty = (rptr == wptr) ? 1'b1 : 1'b0 ; // when in reset state, both rptr and wptr are zero

// always @(*) begin
//     if (~ rst_n)
//         almost_empty = 1'b1;
//     else if (rptr_almost_empty == wptr || empty)
//         almost_empty = 1'b1;
//     else
//         almost_empty = 1'b0;
// end
assign almost_empty = ( (rptr_almost_empty == wptr) || empty ) ? 1'b1 : 1'b0;
//-- 生成empty与almost_empty信号 ------------------------------------------------------------

//++ 生成full与almost_full信号 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// always @(*) begin
//     if (~ rst_n)
//         full  = 1'b1;
//     else if ((wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH])
//             && (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0])
//             )
//         full  = 1'b1;
//     else
//         full  = 1'b0;
// end
assign full = ( (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) 
                && 
                (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0])
              ) ? 1'b1 : 1'b0;

// always @(*) begin
//     if (~ rst_n)
//         almost_full = 1'b1;
//     else if (((wptr_almost_full[ADDR_WIDTH] != rptr[ADDR_WIDTH])
//                 && (wptr_almost_full[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0])
//                 )
//             || full
//             )
//         almost_full = 1'b1;
//     else
//         almost_full = 1'b0;
// end
//-- 生成full与almost_full信号 ------------------------------------------------------------
assign almost_full = ( (wptr_almost_full[ADDR_WIDTH] != rptr[ADDR_WIDTH])
                       && 
                       (wptr_almost_full[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0])
                     ) ? 1'b1 : 1'b0;

//++ 寄存器组定义与读写 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
localparam DEPTH = 1 << ADDR_WIDTH; // 等价于 2**ADDR_WIDTH
(* ram_style = RAM_STYLE *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge clk) begin
    if (wr_en && ~full) begin 
        mem[waddr] <= din;
    end
end

generate
    if( FWFT_EN == 1 ) begin
        //=========================== first-word fall-through mode begin ====================== 
        // reg [DATA_WIDTH-1:0] dout_old;
        // always @(posedge clk) begin
        //     if (rd_en && ~empty) begin 
        //         dout_old <= mem[raddr]; // 存储上一个值
        //     end
        // end
        
        wire [DATA_WIDTH-1:0] dout_old       ;
        wire                  dout_old_ld    ;
        assign dout_old_ld = rd_en & (~empty);
        gnrl_dfflr #(DATA_WIDTH) gnrl_dfflr_old(dout_old_ld,mem[raddr],dout_old,clk,rst_n);

        // wire [DATA_WIDTH-1:0] dout_r;
        // always @(*) begin
        //     if (~empty)
        //         dout_r = mem[raddr];
        //     else
        //         dout_r = dout_old  ;
        // end
        // assign dout = dout_r;
        assign dout = (~empty) ? mem[raddr] : dout_old ;
        //=========================== first-word fall-through mode  end  ====================== 
    end else begin
        //=========================== normal mode begin ====================== 
        reg [DATA_WIDTH-1:0] dout_r;
        always @(posedge clk) begin
            if (rd_en && ~empty) begin 
                dout_r <= mem[raddr];
            end
        end

        assign dout = dout_r;
        //=========================== normal mode  end  ====================== 
    end
    endgenerate
//-- 寄存器组定义与读写 ------------------------------------------------------------

endmodule