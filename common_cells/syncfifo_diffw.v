/**************************************
@ filename     : syncfifo_diffwidth.v
@ origin author: xu xiaokang
@ update by    : yyrwkk
@ create time  : 2025/03/28 21:51:18
@ version      : v1.0.0
**************************************/
/*==========================================================
 * @brief : 同步fifo, 支持数据位宽转换
 * @method: 分两种情况 -> 1. 当读位宽>写位宽时组合数据 2. 当读位宽<写位宽时分解数据
 * @note  :
 *     1. 同步fifo不存在"虚满"和"虚空"
 *     2. fifo实际容量比设定容量大，差值为两个小位宽读/写数据( 写入fifo的深度为2 )
 *     3. DIN_WIDTH与DOUT_WIDTH的倍数关系必须是2的n次方(2,4,8..),不能是(3,6...) !!!
 *     4. fifo深度通过WADDR_WIDTH来设置，所以深度必然是2的指数
 *     5. MSB_FIFO用于设定高位/低位先进先出
 *========================================================*/
module syncfifo_diffw # (
    parameter       DIN_WIDTH   = 8            , // 输入数据位宽, 可取1, 2, 3, ... , 默认为8
    parameter       DOUT_WIDTH  = 8            , // 输出数据位宽, 可取1, 2, 3, ... , 默认为8
    parameter       WADDR_WIDTH = 4            , // 写入地址位宽, 可取1, 2, 3, ... , 默认为4, 对应深度2**4
    parameter       RAM_STYLE   = "distributed", // RAM类型, 可选"block", "distributed"(默认)
    parameter [0:0] FWFT_EN     = 1            , // 首字直通特性使能, 默认为1, 表示使能首字直通
    parameter [0:0] MSB_FIFO    = 1              // 1(默认)表示高位先进先出,同Vivado FIFO一致; 0表示低位先进先出
)(
  input  [DIN_WIDTH-1:0]  din         ,
  input                   wr_en       ,
  output                  full        ,
  output                  almost_full ,

  output [DOUT_WIDTH-1:0] dout        ,
  input                   rd_en       ,
  output                  empty       ,
  output                  almost_empty,

  input                   clk         ,
  input                   rst_n         
);


//++ 写与读位宽转换 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [DIN_WIDTH-1:0]  wdata      ;
wire                  wdata_rd_en;
wire                  wdata_empty;

wire [DOUT_WIDTH-1:0] rdata      ;
wire                  rdata_wr_en;
wire                  rdata_full ;

genvar idx;
generate
    if( DOUT_WIDTH > DIN_WIDTH ) begin // 如果读位宽大于写位宽，则需要组合数据，组合成一个数据就写入到读取侧fifo中
        wire wdata_almost_full;
        syncfifo # (
            .DATA_WIDTH (DIN_WIDTH ),
            .ADDR_WIDTH (1         ),
            .RAM_STYLE  (RAM_STYLE ),
            .FWFT_EN    (1         )
        ) syncfifo_inst_w (
            .din          (din              ),
            .wr_en        (wr_en            ),
            .full         (full             ),
            .almost_full  (wdata_almost_full),
            .dout         (wdata            ),
            .rd_en        (wdata_rd_en      ),
            .empty        (wdata_empty      ),
            .almost_empty (                 ),
            .clk          (clk              ),
            .rst_n        (rst_n            )
        );

        assign almost_full = (wdata_almost_full & rdata_full) | full;

        localparam RADDR_WIDTH = $clog2((2**WADDR_WIDTH) * DIN_WIDTH / DOUT_WIDTH);
        syncfifo # (
            .DATA_WIDTH (DOUT_WIDTH ),
            .ADDR_WIDTH (RADDR_WIDTH),
            .RAM_STYLE  (RAM_STYLE  ),
            .FWFT_EN    (FWFT_EN    )
        ) syncfifo_inst_r (
            .din          (rdata         ),
            .wr_en        (rdata_wr_en   ),
            .full         (rdata_full    ),
            .almost_full  (              ),
            .dout         (dout          ),
            .rd_en        (rd_en         ),
            .empty        (empty         ),
            .almost_empty (almost_empty  ),
            .clk          (clk           ),
            .rst_n        (rst_n         )
        );

        // 在读取侧FIFO未满，而写入侧FIFO非空时去读取写入侧FIFO
        assign wdata_rd_en = (~rdata_full) && (~wdata_empty);

        wire [DOUT_WIDTH-1:0] rdata_r;
        wire [DOUT_WIDTH-1:0] rdata_r_nxt;
        wire rdata_ld ;
        
        assign rdata_ld = wdata_rd_en;
        if (MSB_FIFO == 1) begin
            // always @(posedge clk or posedge rst_n) begin
            //     if (~rst_n)
            //         rdata_r <= 'd0;
            //     else if (wdata_rd_en)
            //         rdata_r <= {rdata_r[DOUT_WIDTH-DIN_WIDTH-1:0], wdata}; // 先进的为高位
            //     else
            //         rdata_r <= rdata_r;
            // end
            assign rdata_r_nxt = {rdata_r[DOUT_WIDTH-DIN_WIDTH-1:0], wdata};
            gnrl_dfflr#(DOUT_WIDTH) gnrl_dfflr_inst_msb(rdata_ld,rdata_r_nxt,rdata_r,clk,rst_n);

            assign rdata = {rdata_r[DOUT_WIDTH-DIN_WIDTH-1:0], wdata}; // 先进的为高位
        end else begin 
            // always @(posedge clk or posedge rst_n) begin
            //     if (~rst_n)
            //         rdata_r <= 'd0;
            //     else if (wdata_rd_en)
            //         rdata_r <= {wdata, rdata_r[DOUT_WIDTH-1 : DIN_WIDTH]}; // 先进的为低位
            //     else
            //         rdata_r <= rdata_r;
            // end
            assign rdata_r_nxt = {wdata, rdata_r[DOUT_WIDTH-1 : DIN_WIDTH]};
            gnrl_dfflr#(DOUT_WIDTH) gnrl_dfflr_inst_lsb(rdata_ld,rdata_r_nxt,rdata_r,clk,rst_n);
            assign rdata = {wdata, rdata_r[DOUT_WIDTH-1 : DIN_WIDTH]}; // 先进的为低位
        end

        localparam WDATA_RD_EN_CNT_MAX = DOUT_WIDTH / DIN_WIDTH - 1;
        wire [$clog2(WDATA_RD_EN_CNT_MAX+1)-1 : 0] wdata_rd_en_cnt    ;
        wire [$clog2(WDATA_RD_EN_CNT_MAX+1)-1 : 0] wdata_rd_en_cnt_nxt;
        wire                                       wdata_rd_en_cnt_ld ;
        // always @(posedge clk or posedge rst_n) begin
        //     if (~rst_n)
        //         wdata_rd_en_cnt <= 'd0;
        //     else if (wdata_rd_en)
        //         wdata_rd_en_cnt <= wdata_rd_en_cnt + 1'b1;
        //     else
        //         wdata_rd_en_cnt <= wdata_rd_en_cnt;
        // end
        assign wdata_rd_en_cnt_ld  = wdata_rd_en ;
        assign wdata_rd_en_cnt_nxt = wdata_rd_en_cnt + 1'b1;
        gnrl_dfflr#($clog2(WDATA_RD_EN_CNT_MAX+1)) gnrl_dfflr_inst_cnt(wdata_rd_en_cnt_ld,wdata_rd_en_cnt_nxt,wdata_rd_en_cnt,clk,rst_n);

        assign rdata_wr_en = wdata_rd_en && (wdata_rd_en_cnt == WDATA_RD_EN_CNT_MAX);
    end else if (DOUT_WIDTH == DIN_WIDTH) begin //~ 如果读位宽等于写位宽，那么就是普通的同步FIFO
        syncfifo # (
            .DATA_WIDTH (DIN_WIDTH  ),
            .ADDR_WIDTH (WADDR_WIDTH),
            .RAM_STYLE  (RAM_STYLE  ),
            .FWFT_EN    (FWFT_EN    )
        ) syncfifo_inst (
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
    end else begin //~ 如果读位宽小于写位宽，则需要分解数据，写入的数据分解成几个数据写入到读取侧FIFO中
        syncfifo # (
            .DATA_WIDTH (DIN_WIDTH  ),
            .ADDR_WIDTH (WADDR_WIDTH),
            .RAM_STYLE  (RAM_STYLE  ),
            .FWFT_EN    (1          )
        ) sync_fifo_inst_w (
            .din          (din         ),
            .wr_en        (wr_en       ),
            .full         (full        ),
            .almost_full  (almost_full ),
            .dout         (wdata       ),
            .rd_en        (wdata_rd_en ),
            .empty        (wdata_empty ),
            .almost_empty (            ),
            .clk          (clk         ),
            .rst_n        (rst_n       )
        );

        wire rdata_almost_empty;
        syncfifo # (
            .DATA_WIDTH (DOUT_WIDTH),
            .ADDR_WIDTH (1         ),
            .RAM_STYLE  (RAM_STYLE ),
            .FWFT_EN    (FWFT_EN   )
        ) syncfifo_inst_r (
            .din          (rdata             ),
            .wr_en        (rdata_wr_en       ),
            .full         (rdata_full        ),
            .almost_full  (                  ),
            .dout         (dout              ),
            .rd_en        (rd_en             ),
            .empty        (empty             ),
            .almost_empty (rdata_almost_empty),
            .clk          (clk               ),
            .rst_n        (rst_n             )
        );

        assign almost_empty = (wdata_empty & rdata_almost_empty) | empty;

        // 在读取侧FIFO非满，而写入侧FIFO非空时去写入读取侧FIFO
        assign rdata_wr_en = (~rdata_full) && (~wdata_empty);

        // 先写入写数据的高位，再写入低位，当写入到最低位时，读取写入侧FIFO
        localparam RDATA_WR_EN_CNT_MAX = DIN_WIDTH/ DOUT_WIDTH - 1;
        wire [$clog2(RDATA_WR_EN_CNT_MAX+1)-1 : 0] rdata_wr_en_cnt    ;
        wire [$clog2(RDATA_WR_EN_CNT_MAX+1)-1 : 0] rdata_wr_en_cnt_nxt;
        wire                                       rdata_wr_en_cnt_ld ;

        // always @(posedge clk or posedge rst_n) begin
        //     if (~rst_n)
        //         rdata_wr_en_cnt <= 'd0;
        //     else if (rdata_wr_en)
        //         rdata_wr_en_cnt <= rdata_wr_en_cnt + 1'b1;
        //     else
        //         rdata_wr_en_cnt <= rdata_wr_en_cnt;
        // end

        assign rdata_wr_en_cnt_ld  = rdata_wr_en ;
        assign rdata_wr_en_cnt_nxt = rdata_wr_en_cnt + 1'b1;
        gnrl_dfflr #($clog2(RDATA_WR_EN_CNT_MAX+1)) gnrl_dfflr_inst_cnt(rdata_wr_en_cnt_ld,rdata_wr_en_cnt_nxt,rdata_wr_en_cnt,clk,rst_n);

        // not good, even bad !!!
        // if (MSB_FIFO == 1) begin
        //     wire [DIN_WIDTH-1:0] wdata_r ;
        //     assign wdata_r = wdata << (rdata_wr_en_cnt * DOUT_WIDTH);
        //     assign rdata = wdata_r[DIN_WIDTH-1 : DIN_WIDTH-DOUT_WIDTH];
        // end else begin
        //     wire [DIN_WIDTH-1:0] wdata_r ;
        //     assign wdata_r = wdata >> (rdata_wr_en_cnt * DOUT_WIDTH);
        //     assign rdata = wdata_r[DOUT_WIDTH-1 : 0];
        // end
        wire  [DOUT_WIDTH-1:0] wdata_r [RDATA_WR_EN_CNT_MAX+1-1:0];
        for( idx = 0;idx<RDATA_WR_EN_CNT_MAX+1;idx = idx + 1) begin 
           assign wdata_r[idx] = wdata[idx*DOUT_WIDTH+:DOUT_WIDTH];
        end

        if (MSB_FIFO == 1) begin
            assign rdata = wdata_r[~rdata_wr_en_cnt];
        end else begin 
            assign rdata = wdata_r[rdata_wr_en_cnt];
        end



        assign wdata_rd_en = rdata_wr_en && (rdata_wr_en_cnt == RDATA_WR_EN_CNT_MAX);
    end
endgenerate
//-- 写与读位宽转换 ------------------------------------------------------------

endmodule
